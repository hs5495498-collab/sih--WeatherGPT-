"""
WeatherGPT — vision inference microservice (optional backend-served path).

Serves the model trained in WeatherGPT_Image_Classifier_Training.ipynb behind
a REST endpoint, following the same contract style as the mobile app's
ApiClient (see the Flutter project's README for /api/chat/query etc.).

Run:
    pip install fastapi uvicorn tensorflow pillow python-multipart slowapi
    python serve_model.py

Endpoint:
    POST /api/vision/classify-weather
    multipart/form-data: file=<image>
    Response:
      {
        "label": "rain",
        "confidence": 0.94,
        "top_k": [{"label": "rain", "confidence": 0.94}, {"label": "fogsmog", "confidence": 0.03}]
      }

SECURITY NOTES for whoever deploys this (Member 5/6):
- File size and content-type are validated before decoding — never pass raw
  upload bytes straight to an image decoder without a size cap (decompression
  bomb risk).
- Rate limiting is included via slowapi (10 requests/minute/IP by default) —
  tune for your expected demo traffic, and put a real API gateway limiter in
  front of this for production, this is a baseline only.
- This service should sit behind the same HTTPS termination as the rest of
  the backend — never expose it on plain HTTP.
- Model file path is read from an environment variable, not hardcoded, so
  nothing about your deployment layout ends up committed to git.
"""

import io
import os

from fastapi import FastAPI, File, HTTPException, Request, UploadFile
from fastapi.responses import JSONResponse
from PIL import Image
import numpy as np
import tensorflow as tf
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

MODEL_PATH = os.environ.get("WEATHERGPT_VISION_MODEL_PATH", "weathergpt_vision.keras")
LABELS_PATH = os.environ.get("WEATHERGPT_VISION_LABELS_PATH", "labels.txt")
IMG_SIZE = (224, 224)
MAX_UPLOAD_BYTES = 8 * 1024 * 1024  # 8 MB — generous for a phone photo, small enough to block abuse
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}

limiter = Limiter(key_func=get_remote_address)
app = FastAPI(title="WeatherGPT Vision Service")
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

_model = None
_class_names: list[str] = []


def _load_model():
    global _model, _class_names
    if _model is None:
        if not os.path.exists(MODEL_PATH):
            raise RuntimeError(
                f"Model file not found at {MODEL_PATH}. Set WEATHERGPT_VISION_MODEL_PATH "
                "or place weathergpt_vision.keras next to this script."
            )
        _model = tf.keras.models.load_model(MODEL_PATH)
        with open(LABELS_PATH) as f:
            _class_names = [line.strip() for line in f if line.strip()]
    return _model, _class_names


@app.on_event("startup")
def startup():
    # Fail fast and loud if the model can't load, rather than 500-ing on
    # the first real request during a live demo.
    _load_model()


@app.get("/healthz")
def healthz():
    return {"status": "ok", "classes_loaded": len(_class_names)}


@app.post("/api/vision/classify-weather")
@limiter.limit("10/minute")
async def classify_weather(request: Request, file: UploadFile = File(...)):
    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=415,
            detail=f"Unsupported content type '{file.content_type}'. Use JPEG, PNG, or WebP.",
        )

    raw = await file.read()
    if len(raw) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="Image too large (max 8 MB).")

    try:
        image = Image.open(io.BytesIO(raw)).convert("RGB")
    except Exception:
        raise HTTPException(status_code=400, detail="Could not decode image file.")

    image = image.resize(IMG_SIZE)
    arr = np.array(image, dtype=np.float32)
    arr = tf.keras.applications.efficientnet.preprocess_input(arr)  # match training preprocessing exactly
    arr = np.expand_dims(arr, axis=0)

    model, class_names = _load_model()
    predictions = model.predict(arr, verbose=0)[0]

    top_indices = np.argsort(predictions)[::-1][:3]
    top_k = [
        {"label": class_names[i], "confidence": round(float(predictions[i]), 4)}
        for i in top_indices
    ]

    return JSONResponse(
        {
            "label": top_k[0]["label"],
            "confidence": top_k[0]["confidence"],
            "top_k": top_k,
        }
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8001)
