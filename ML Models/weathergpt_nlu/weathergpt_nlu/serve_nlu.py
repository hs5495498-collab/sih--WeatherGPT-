"""
WeatherGPT — real chat backend. Implements the exact /api/chat/query contract the
Flutter app already expects (see the mobile app's README), so dropping this in behind
the app's `baseUrl` requires zero app-side changes.

Pipeline per request:
  1. NLU (nlu_inference.py) parses intent + slots from the raw message — any phrasing.
  2. If the intent is conversational (greeting/thanks/goodbye) or out_of_scope,
     answer directly — no need to hit the weather API for "hi".
  3. Otherwise, fetch real facts for the extracted location (weather_client.py).
  4. Generate the final natural-language answer grounded in those facts
     (answer_generator.py) — never inventing numbers the model wasn't given.
  5. Map the facts into the same WeatherData JSON shape the app's models already parse.

Run:
    pip install fastapi uvicorn torch transformers requests slowapi python-multipart
    python serve_nlu.py
"""

import os

from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from answer_generator import CONVERSATIONAL_REPLIES, generate_answer
from nlu_inference import NluEngine
from weather_client import WeatherClient

limiter = Limiter(key_func=get_remote_address)
app = FastAPI(title="WeatherGPT Chat Service")
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

_nlu: NluEngine | None = None
_weather_client = WeatherClient()

CONVERSATIONAL_INTENTS = {"greeting", "thanks", "goodbye", "out_of_scope"}
DEFAULT_LOCATION = "New Delhi"
LOW_CONFIDENCE_THRESHOLD = 0.45


class ChatQueryRequest(BaseModel):
    message: str
    lang: str | None = "en"
    location: str | None = None


@app.on_event("startup")
def startup():
    global _nlu
    _nlu = NluEngine()


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.post("/api/chat/query")
@limiter.limit("20/minute")
async def chat_query(request: Request, body: ChatQueryRequest):
    message = body.message.strip()
    if not message:
        raise HTTPException(status_code=400, detail="message must not be empty")
    if len(message) > 500:
        raise HTTPException(status_code=400, detail="message too long (max 500 chars)")

    parsed = _nlu.parse(message)
    intent = parsed["intent"]

    # Low-confidence predictions are treated as out_of_scope rather than acted on —
    # an uncertain guess about a disaster-alert-adjacent question is worse than an
    # honest "I'm not sure I understood that."
    if parsed["confidence"] < LOW_CONFIDENCE_THRESHOLD:
        intent = "out_of_scope"

    if intent in CONVERSATIONAL_INTENTS:
        return {
            "answer": CONVERSATIONAL_REPLIES[intent],
            "language": body.lang,
            "weather": None,
            "alert": None,
            "suggestions": [] if intent != "out_of_scope" else [
                "Will it rain tomorrow?", "What's the weather in Mumbai?"
            ],
        }

    location = parsed["location"] or body.location or DEFAULT_LOCATION
    facts = _weather_client.get_weather(location, when=parsed["datetime"])

    answer = generate_answer(message, facts)

    weather_payload = None
    if facts is not None:
        weather_payload = {
            "location": facts.location_name,
            "temp_c": facts.current_temp_c if facts.current_temp_c is not None else facts.temp_max_c,
            "condition": facts.condition_label,
            "description": f"{facts.condition_label.capitalize()} conditions expected",
            "humidity_pct": facts.humidity_pct or 50,
            "wind_kmh": facts.wind_speed_kmh or 0,
            "forecast": [],  # populate via repeated get_weather calls per day if the UI needs a strip
        }

    # NOTE: real severe-weather alerts need a dedicated feed (NDMA/IMD alert bulletins)
    # which Open-Meteo does not provide — this is intentionally left None here rather
    # than fabricating an alert. Member 6's alert engine is the real source for this
    # field; wire it in here once that's ready.
    return {
        "answer": answer,
        "language": body.lang,
        "weather": weather_payload,
        "alert": None,
        "suggestions": [],
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
