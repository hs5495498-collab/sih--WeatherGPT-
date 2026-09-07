import logging
import sys


def setup_logging(debug: bool = False) -> None:
    """
    Configure logging once, at application startup. Every module then
    just does `logger = logging.getLogger(__name__)` and it works —
    no per-file setup needed.
    """

    level = logging.DEBUG if debug else logging.INFO

    formatter = logging.Formatter(
        fmt="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)

    root_logger = logging.getLogger()
    root_logger.setLevel(level)

    # Avoid duplicate log lines if this ever runs twice (e.g. uvicorn
    # --reload re-importing the module).
    root_logger.handlers.clear()
    root_logger.addHandler(console_handler)

    # Quiet down noisy third-party loggers so app logs aren't buried.
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)