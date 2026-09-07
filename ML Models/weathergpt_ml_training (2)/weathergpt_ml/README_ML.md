# WeatherGPT — Image Weather Classifier

Extends the ML/NLP layer (Members 3 & 4) with a **photo-to-weather-condition** classifier:
point a camera at the sky, get an instant label. Complements the existing text-based
forecast/alert Q&A rather than replacing it — a nice "wow" moment for the live demo, and a
genuinely useful offline fallback when connectivity or official data feeds are down.

## What's in this folder
| File | Purpose |
|---|---|
| `WeatherGPT_Image_Classifier_Training.ipynb` | Full Colab training pipeline — open it in Colab and run top to bottom |
| `serve_model.py` | Optional FastAPI microservice to serve the trained model behind a REST endpoint |

## Dataset
**Weather Dataset** — Kaggle `jehanbhathena/weather-dataset` — 6,862 images, 11 classes:
`dew, fogsmog, frost, glaze, hail, lightning, rain, rainbow, rime, sandstorm, shine, snow, sunrise`.
The notebook downloads it automatically via `kagglehub` (you'll need a free Kaggle account +
API token — instructions are in the notebook's Section 2).

*Time-constrained alternative:* `pratik2901/multiclass-weather-dataset` (4 classes, ~1,125
images) trains much faster if you're close to demo day — just change one variable in the
notebook, the rest of the pipeline is unchanged.

## How to run it
1. Open `WeatherGPT_Image_Classifier_Training.ipynb` in Google Colab.
2. **Runtime → Change runtime type → T4 GPU.**
3. Run cells top to bottom. Total runtime ≈ 25–40 minutes on a T4.
4. Section 14 downloads a zip with everything you need: `weathergpt_vision.tflite`,
   `weathergpt_vision.keras`, `labels.txt`.

## What the pipeline does (and why)
- **Transfer learning** (EfficientNetB0, MobileNetV2 as a faster on-device alternative) —
  training a CNN from scratch on ~7k images would badly overfit; starting from
  ImageNet-pretrained weights and fine-tuning is the standard, correct approach here.
- **Two-phase training**: freeze the backbone and train just the classification head first,
  then unfreeze the top ~30% of the backbone and fine-tune at a much lower learning rate.
  This avoids destroying useful pretrained features early in training.
- **Class-weighted loss** to handle the dataset's natural class imbalance (some weather
  types have far more stock photos than others).
- **Defensive callbacks**: early stopping on validation accuracy, LR reduction on plateau,
  checkpointing the best model — not just the last epoch.
- **Full evaluation**: classification report (precision/recall/F1 per class), confusion
  matrix, and a look at actual misclassified images — not just a single accuracy number.
- **Grad-CAM visualization** — shows which pixels the model actually used to make each
  prediction. Worth screenshotting for your presentation's "Tech Highlights" section as
  evidence the model learned real weather cues, not spurious shortcuts.
- **TFLite export with float16 quantization** for on-device inference, plus a sanity check
  that the quantized model's predictions match the full Keras model closely.

## Realistic expectations
On this dataset, a well-tuned EfficientNetB0 typically lands somewhere in the **85-92% test
accuracy** range across all 11 classes — but a few classes are genuinely hard even for a
human glance: `frost`, `glaze`, and `rime` all look visually similar (a light icy coating),
so most of the remaining errors tend to cluster there. Check your own confusion matrix in
Section 11 rather than assuming a number in advance; if those three dominate your errors,
consider merging them into one `icy-conditions` class for a cleaner demo.

**Domain gap warning:** this is global stock photography. Real photos taken by users in
India (monsoon cloud types, regional haze levels, phone camera quality) will likely score
somewhat lower than the Colab test accuracy. If time allows before the demo, collect even a
small set (20-30 photos) of real Indian sky/weather photos and spot-check accuracy on those
before trusting this on stage.

## Integrating into the app
**On-device (recommended)**: bundle the `.tflite` + `labels.txt` as Flutter assets and run
inference locally via `tflite_flutter`. Works fully offline — a real advantage for a
disaster-management tool. Preprocessing in Dart must exactly match the notebook (resize to
224×224, same pixel scaling) or you'll get a model that scores well in Colab but performs
randomly in the app — this mismatch is the single most common deployment bug for this kind
of pipeline.

**Backend-served**: run `serve_model.py`, which exposes `POST /api/vision/classify-weather`.
Add this endpoint to the shared API contract doc alongside `/api/chat/query` so Member 1 can
keep the mobile app's integration in sync. Already includes upload size limits, content-type
validation, and basic rate limiting — see the security notes in the file's docstring for
what still needs a production-grade version if you extend this past the hackathon.

## Suggested next steps (Members 3 & 4)
- Spot-check accuracy on real India-sourced photos, not just the Kaggle test split.
- Consider merging `frost`/`glaze`/`rime` if they dominate the confusion matrix.
- If Colab compute allows, try `EfficientNetB3` for the backend-served path only (too heavy
  for on-device latency, but a few extra points of accuracy is easy to get server-side).
