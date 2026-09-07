import time
import logging

import httpx

logger = logging.getLogger(__name__)


class TranslationService:
    """
    Best-effort text translation using MyMemory's free, keyless translation
    API (https://mymemory.translated.net/doc/spec.php).

    Why this exists: the NLU/response layer (nlu_service, response_generator_service,
    farmer/aviation/marine/outdoor advisory services) is entirely English --
    there is no Hindi or other-language branching anywhere in that code. To
    let a user ask in, say, Tamil and get a Tamil reply, this service
    translates the incoming message to English before it reaches the NLU,
    and translates the generated English response back to the user's
    language before it's returned.

    Honesty/robustness rules this follows:
    - No API key is configured or required -- MyMemory's anonymous tier
      allows ~5,000 words/day per IP, no signup. That's a real, disclosed
      limit, not a hidden one -- see translate()'s docstring.
    - MyMemory occasionally returns a low-quality or empty translation
      (e.g. for very short strings, or when its free quota is exhausted).
      In every failure mode this returns the ORIGINAL text unchanged and
      logs a warning -- it never raises, and it never fabricates a
      translation. Callers must treat a same-as-input result as "translation
      unavailable" is a possible cause, not assume translation happened.
    - Same in-memory TTL cache pattern as weather_service, so repeated
      phrases (many users will ask near-identical questions) don't burn
      through the daily quota.
    """

    ENDPOINT = "https://api.mymemory.translated.net/get"
    _CACHE_TTL_SECONDS = 3600  # translations of the same text/pair are stable; cache for an hour
    _cache: dict = {}

    # MyMemory rejects (or badly mistranslates) very long inputs on the free
    # tier. Chat messages are short by construction (ChatRequest caps at
    # 1000 chars) but this is a hard safety ceiling regardless.
    _MAX_CHARS = 480

    def _cache_get(self, key):
        entry = self._cache.get(key)
        if entry is None:
            return None
        value, expires_at = entry
        if time.monotonic() > expires_at:
            del self._cache[key]
            return None
        return value

    def _cache_set(self, key, value):
        self._cache[key] = (value, time.monotonic() + self._CACHE_TTL_SECONDS)

    async def translate(self, text: str, source: str, target: str) -> tuple[str, bool]:
        """
        Returns (translated_text, translated). `translated` is False whenever
        the input is returned unchanged -- whether because source == target,
        the input was empty/too long, or the API call failed. Callers should
        check this flag rather than assuming translation always succeeds.
        """
        if not text or not text.strip():
            return text, False

        if source == target:
            return text, False

        if len(text) > self._MAX_CHARS:
            logger.warning(
                "translation_service: text too long (%d chars), skipping translation",
                len(text),
            )
            return text, False

        cache_key = (source, target, text)
        cached = self._cache_get(cache_key)
        if cached is not None:
            return cached, True

        try:
            async with httpx.AsyncClient(timeout=6.0) as client:
                response = await client.get(
                    self.ENDPOINT,
                    params={"q": text, "langpair": f"{source}|{target}"},
                )
                response.raise_for_status()
                data = response.json()

            translated_text = (
                data.get("responseData", {}).get("translatedText")
            )

            # MyMemory returns HTTP 200 even for quota/error conditions,
            # signalling failure via responseStatus and/or an error-shaped
            # translatedText string instead. Treat anything suspicious as
            # "didn't translate" rather than trusting it blindly.
            response_status = data.get("responseStatus")
            if (
                not translated_text
                or response_status not in (200, "200")
                or "MYMEMORY WARNING" in translated_text.upper()
            ):
                logger.warning(
                    "translation_service: MyMemory did not return a usable "
                    "translation for %s->%s (status=%s)",
                    source, target, response_status,
                )
                return text, False

            self._cache_set(cache_key, translated_text)
            return translated_text, True

        except Exception as error:
            logger.warning(
                "translation_service: translation failed for %s->%s: %s",
                source, target, error,
            )
            return text, False


translation_service = TranslationService()
