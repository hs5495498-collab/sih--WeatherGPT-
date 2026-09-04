import asyncio
import logging

from app.core.config import settings
from app.services.location_service import location_service
from app.services.weather_service import weather_service
from app.services.risk_service import risk_service
from app.services.alert_service import alert_service
from app.services.notification_service import notification_service
from app.services.websocket_manager import websocket_manager

logger = logging.getLogger(__name__)


class AlertPoller:
    """
    Background loop that keeps WebSocket subscribers genuinely "real-time":
    instead of only pushing when someone happens to call
    GET /api/v1/alerts, it re-runs the risk pipeline for every city that
    currently has a live subscriber, on a fixed interval, and pushes
    whenever there's something to report.
    """

    def __init__(self, interval_seconds: int):
        self.interval_seconds = interval_seconds
        self._task: asyncio.Task | None = None
        self._running = False

    def start(self):
        if self._task is None:
            self._running = True
            self._task = asyncio.create_task(self._run_loop())
            logger.info("Alert poller started (interval=%ss)", self.interval_seconds)

    async def stop(self):
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
            self._task = None
            logger.info("Alert poller stopped")

    async def _run_loop(self):
        while self._running:
            try:
                await asyncio.sleep(self.interval_seconds)
                await self._check_all_subscribed_cities()
            except asyncio.CancelledError:
                raise
            except Exception as error:
                logger.warning("Alert poller iteration failed: %s", error)

    async def _check_all_subscribed_cities(self):
        cities = websocket_manager.subscribed_cities()

        if not cities:
            return

        for city in cities:
            try:
                await self._check_city(city)
            except Exception as error:
                logger.warning("Poller failed to check '%s': %s", city, error)

    async def _check_city(self, city: str):
        risk_result = await risk_service.analyze_location(
            city=city,
            location_service=location_service,
            weather_service=weather_service,
        )

        if not risk_result.get("success"):
            return

        active_alerts = alert_service.generate_alerts(risk_result["risks"])

        await notification_service.notify(
            city=risk_result["location"]["city"],
            location=risk_result["location"],
            overall_risk=risk_result["overall_risk"],
            alerts=active_alerts,
        )


alert_poller = AlertPoller(interval_seconds=settings.ALERT_POLL_INTERVAL_SECONDS)
