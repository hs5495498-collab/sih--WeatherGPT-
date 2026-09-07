"""
Turns (user question + retrieved WeatherFacts) into a natural-language answer.

Why a generative model instead of more templates: templates are rigid — a new phrasing
the templates didn't anticipate produces an awkward or wrong-sounding reply even if the
NLU correctly understood it. A real instruction-tuned language model (FLAN-T5) can phrase
an answer naturally regardless of how the question was asked, AS LONG AS it's conditioned
on real facts rather than asked to invent the weather itself — that's the RAG (retrieval-
augmented generation) pattern used here: retrieve real data first (weather_client.py),
THEN generate, with the model explicitly instructed to use only the given facts.

Model choice: google/flan-t5-base — free, no API key, runs on CPU (slower) or GPU (fast),
no usage cost. flan-t5-large gives noticeably better phrasing if your serving box has the
memory/compute for it; swap MODEL_NAME below. A hosted LLM API (Claude, GPT, Gemini) would
give the best phrasing quality of all, at the cost of needing an API key and per-request
cost/latency — a reasonable upgrade path once this is past hackathon stage, not required
to have a working, good product today.
"""

from functools import lru_cache
from typing import Optional

from transformers import T5ForConditionalGeneration, T5Tokenizer

from weather_client import WeatherFacts

MODEL_NAME = "google/flan-t5-base"


@lru_cache(maxsize=1)
def _load_model():
    tokenizer = T5Tokenizer.from_pretrained(MODEL_NAME)
    model = T5ForConditionalGeneration.from_pretrained(MODEL_NAME)
    model.eval()
    return tokenizer, model


def _facts_to_text(facts: WeatherFacts) -> str:
    parts = [f"Location: {facts.location_name}", f"Date: {facts.date}", f"Condition: {facts.condition_label}"]
    if facts.current_temp_c is not None:
        parts.append(f"Current temperature: {facts.current_temp_c}°C")
    if facts.temp_max_c is not None and facts.temp_min_c is not None:
        parts.append(f"Forecast high/low: {facts.temp_max_c}°C / {facts.temp_min_c}°C")
    if facts.precipitation_probability_pct is not None:
        parts.append(f"Chance of rain: {facts.precipitation_probability_pct}%")
    if facts.precipitation_mm is not None:
        parts.append(f"Expected rainfall: {facts.precipitation_mm} mm")
    if facts.wind_speed_kmh is not None:
        parts.append(f"Wind speed: {facts.wind_speed_kmh} km/h")
    if facts.humidity_pct is not None:
        parts.append(f"Humidity: {facts.humidity_pct}%")
    return "; ".join(parts)


def generate_answer(question: str, facts: Optional[WeatherFacts]) -> str:
    """The core grounding guarantee: if `facts` is None (geocoding/API failure),
    this NEVER asks the model to invent weather data — it returns an honest
    "couldn't fetch that" message instead. Hallucinated weather facts in a
    disaster-alert-adjacent tool are a genuinely unsafe failure mode, not just
    a quality issue."""
    if facts is None:
        return (
            "I couldn't fetch live weather data for that location just now — "
            "the location might be misspelled, or the weather service is "
            "temporarily unreachable. Could you try rephrasing the place name?"
        )

    tokenizer, model = _load_model()
    facts_text = _facts_to_text(facts)

    prompt = (
        "You are a helpful weather assistant. Answer the user's question in one or "
        "two clear, friendly sentences, using ONLY the facts given below. Do not "
        "invent any numbers or details not present in the facts.\n\n"
        f"Facts: {facts_text}\n"
        f"Question: {question}\n"
        "Answer:"
    )

    inputs = tokenizer(prompt, return_tensors="pt", truncation=True, max_length=256)
    output_ids = model.generate(
        **inputs,
        max_new_tokens=80,
        num_beams=4,
        no_repeat_ngram_size=3,
        early_stopping=True,
    )
    answer = tokenizer.decode(output_ids[0], skip_special_tokens=True).strip()

    # A small instruction-tuned base model occasionally returns something too
    # short/empty on an unusual prompt — never show a blank bubble in the app.
    if len(answer) < 3:
        return (
            f"In {facts.location_name} on {facts.date}, expect {facts.condition_label} "
            f"conditions with a high of {facts.temp_max_c}°C."
            if facts.temp_max_c is not None
            else f"Here's what I found for {facts.location_name}: {facts_text}."
        )
    return answer


CONVERSATIONAL_REPLIES = {
    "greeting": "Namaste! Ask me about weather, forecasts, or alerts anywhere in India.",
    "thanks": "You're welcome! Anything else you'd like to know about the weather?",
    "goodbye": "Take care, and stay safe out there!",
    "out_of_scope": (
        "I'm focused on weather, forecasts, and alerts — I can't help with that one, "
        "but ask me anything about the weather anywhere in India!"
    ),
}
