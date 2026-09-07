# WeatherGPT — Where Things Stand

Written after three rounds of work: the Flutter app, the image classifier, and now the
real NLU + generation backend. This is the honest full picture — what's actually working,
what's still a gap, and what you personally need to learn to own all of it credibly on
stage and in Q&A.

---

## 1. What has been built

### Mobile app (Flutter) — `weathergpt_flutter_app.zip`
A complete, running app: animated chat UI, dashboard with forecast/alerts, voice input,
read-aloud replies, Hindi/English toggle, offline caching, connectivity awareness, dark
mode. Talks to a backend over the `/api/chat/query`, `/api/weather/current`, `/api/alerts`
contract documented in its README. Ships with a mock data fallback so it's demoable with
zero backend right now.

**Bugs found and fixed along the way**: a memory leak from undisposed controllers, a race
condition where fast taps could send concurrent requests and land replies out of order, a
broken pulse animation, no validation of backend responses (a malformed field would crash
the chat), no input sanitization or rate limiting. All fixed — see that project's README
for the specific before/after on each.

### Image classifier — `weathergpt_ml_training.zip`
A Colab notebook that trains a CNN (EfficientNetB0 transfer learning) to classify weather
condition from a photo, now combining **two Kaggle datasets** into one unified, deduplicated
taxonomy (13-14 classes depending on whether you merge the visually-similar frost/glaze/rime
group). Includes Grad-CAM visualization, TFLite export, and a FastAPI serving stub.

**Realistic expectation, not a promise**: ~85-92% test accuracy on the combined Kaggle data,
likely somewhat lower on real photos your users submit (stock photography vs. real Indian
sky/monsoon conditions is a genuine domain gap — flagged, not hidden).

### NLU + real answer generation — `weathergpt_nlu.zip` (this delivery)
This is the piece that actually answers your core ask — **"I don't need predefined
questions, I need it to answer all types of questions."** Here's what that means concretely
and where the honest boundary is:

- A **trained joint intent + slot-filling model** (fine-tuned DistilBERT) that understands
  16 different question types (current weather, forecast, rain probability, temperature,
  wind, humidity, alerts, cyclone status, flood risk, clothing advice, travel advice,
  general climate, plus greeting/thanks/goodbye/out-of-scope) **regardless of how they're
  phrased** — "will it pour in Chennai this evening" and "chennai mein aaj shaam baarish
  hogi kya" and "should I expect rain in Chennai tonight" all correctly resolve to the same
  intent+slots, because it's a real trained model, not keyword matching.
- A **real, free, keyless weather data client** (Open-Meteo) — actual current conditions
  and forecasts for any location worldwide, not mock/hardcoded data.
- A **grounded generative answer** (FLAN-T5) that phrases the final reply naturally for
  whatever way the question was asked, while being explicitly constrained to only use the
  real fetched facts — this is what stops it from confidently making up numbers.
- A FastAPI service (`serve_nlu.py`) that wires all three together behind the exact
  `/api/chat/query` contract the Flutter app already expects — no app-side changes needed
  to plug this in.

**The honest scope boundary**: this answers any phrasing of a *weather-related* question. It
does not answer literally everything — ask it who won the cricket match and it will
correctly and politely decline (that's the `out_of_scope` intent working as designed, not a
failure). A tool that confidently answers non-weather trivia with made-up information would
be worse than one with a clear, honest boundary — especially for something adjacent to
disaster alerts, where a wrong confident answer has real stakes.

---

## 2. What still needs to be done

Roughly in priority order for your remaining days before Sept 8:

1. **Actually run both training notebooks on Colab and look at your own results.** I've
   written code that should train well, but "should" isn't "did" — you need real accuracy
   numbers and a real confusion matrix from your own run, because that's what you'll be
   asked about on stage. Don't present numbers you haven't personally seen.
2. **Deploy `serve_nlu.py` somewhere reachable** (Render/Railway free tier, per your
   original plan) and point the Flutter app's `baseUrl` at it via `--dart-define`.
3. **Wire in a real severe-weather alert source.** This is the one piece intentionally left
   as `None` in `serve_nlu.py` — Open-Meteo doesn't provide alert bulletins. This was
   always Member 6's "alert engine" responsibility in your original plan; it needs a real
   feed (NDMA/IMD bulletins, or a simple rule-based threshold on the forecast data you're
   already fetching — e.g. flag `precipitation_probability_pct > 80` as a rain advisory).
4. **Test the NLU on questions your teammates try to break it with**, not just the
   sanity-check list in the notebook. Rephrase aggressively, try Hindi more, try genuinely
   ambiguous questions. Fix what breaks by adding those phrasings back into the synthetic
   generator and retraining — this loop (test → find gaps → add examples → retrain) is the
   real ongoing work of an NLU system, not a one-time task.
5. **Decide on and test the image classifier's integration path** (on-device TFLite vs.
   backend-served) and actually wire it into a chat flow (e.g. an attach-photo button).
6. **Spot-check both models against real Indian data** if you have any time left — real
   sky photos for the classifier, real Hindi phrasings from an actual Hindi speaker on the
   team for the NLU (the notebook's Hindi templates are a starting scaffold, not a
   validated set).
7. **Auth on the backend**, if time allows — right now `serve_nlu.py` and `serve_model.py`
   are open endpoints with only rate limiting, fine for a demo, not for anything beyond it.

---

## 3. What you personally need to learn to own this credibly

You asked to understand this "from bottom to top" — here's the actual learning path, not
just a reading list, ordered by what unlocks the most understanding fastest:

**To understand what you already have (do this first, even before more building):**
- **What a neural network's forward pass actually computes** — inputs → weighted sums →
  activation function → next layer. If this is fuzzy, the rest won't click. 3Blue1Brown's
  "Neural Networks" video series is the fastest genuinely-correct intuition-builder.
- **Transfer learning, specifically**: why you freeze a pretrained backbone first and only
  unfreeze it later at a lower learning rate (this is exactly what the image classifier
  notebook does in Sections 8-9) — the intuition is "don't let a big update from a
  randomly-initialized new head wreck good pretrained features on the first few steps."
- **Tokenization and subword alignment** — why the NLU code has that `word_ids()` /
  `-100` label-masking logic. Modern NLP models don't operate on whole words; they split
  into subword pieces, and labeling those correctly is a real, common source of subtle
  bugs if you don't understand why it's there.
- **Precision, recall, F1, and confusion matrices** — you'll be asked "how accurate is
  it" on stage; "accuracy" alone is a weak/misleading answer for an imbalanced multi-class
  problem like this one, and judges asking about disaster-alert software should expect you
  to know the difference between missing a real alert (false negative) and crying wolf
  (false positive) — that framing matters a lot for a Ministry-of-Earth-Sciences judge.

**To extend or debug what's here:**
- **Hugging Face `transformers` basics** — `AutoTokenizer`, `AutoModel`, the encode/decode
  cycle. The NLU and generation code both depend on this library; skimming their own
  "Quick tour" docs will make every file here make sense line by line.
- **PyTorch fundamentals** — tensors, `.backward()`, optimizers, the train/eval loop
  structure. The NLU notebook's training loop is written explicitly (not hidden behind a
  `.fit()` call) specifically so it's readable as a learning artifact — read it slowly once.
- **REST API design + FastAPI** — request/response bodies, status codes, path vs. query
  params. You'll need this to explain `serve_nlu.py` and to actually deploy it.
- **Prompt design for instruction-tuned models** — why `answer_generator.py`'s prompt
  explicitly says "using ONLY the facts given" — this is the core technique (grounding/RAG)
  that prevents hallucination, and it generalizes far beyond this project.

**To deploy and demo confidently:**
- **Environment variables / `--dart-define` / secrets management** — why nothing here has
  a hardcoded API key or URL, and how to actually supply them at build/run time.
- **Basic Linux/cloud deployment** — getting a FastAPI app running on Render or Railway,
  reading logs when it breaks, understanding cold-start delays on free tiers (this
  directly affects your live demo — test it enough in advance to know the real latency).

**Where to look things up as you go** (not a syllabus to complete linearly — use these as
references when something above doesn't click): Hugging Face's own course
(huggingface.co/course) for the NLP/transformers side, PyTorch's official 60-minute
blitz for the DL fundamentals, FastAPI's own docs (genuinely excellent, worth reading
directly), and 3Blue1Brown for intuition whenever the math feels like symbol-pushing
rather than something you understand.

**The most important thing, honestly**: you don't need to derive backpropagation from
scratch to present this well on Sept 8. You need to be able to explain, in your own words,
what each piece does and why it's built the way it is — a judge probing "why transfer
learning" or "how does it handle a question it hasn't seen before" should get a real answer
from you, not a memorized line. Reading the code's own comments slowly, one file at a time,
is genuinely the fastest path there — I wrote them for exactly this purpose, not just as
documentation.
