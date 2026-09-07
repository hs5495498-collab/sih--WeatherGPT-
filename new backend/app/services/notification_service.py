import logging
from abc import ABC, abstractmethod
from datetime import datetime, timezone
from enum import Enum
from typing import List

from app.services.websocket_manager import websocket_manager

logger = logging.getLogger(__name__)


class NotificationChannel(str, Enum):
    WEBSOCKET = "websocket"
    EMAIL = "email"
    SMS = "sms"
    PUSH = "push"


class BaseNotifier(ABC):
    """Every channel implements this. Add a new channel = add a new class."""

    channel: NotificationChannel

    @abstractmethod
    async def send(self, city: str, alert_payload: dict) -> bool:
        """Return True if the notification was (or would be) delivered."""
        raise NotImplementedError


class WebSocketNotifier(BaseNotifier):
    """The one fully-working channel: pushes live over /ws/weather-alerts."""

    channel = NotificationChannel.WEBSOCKET

    async def send(self, city: str, alert_payload: dict) -> bool:
        delivered = await websocket_manager.broadcast_to_city(city, alert_payload)
        if delivered:
            logger.info("Pushed alert for '%s' to %d live socket(s)", city, delivered)
        return delivered > 0


class EmailNotifier(BaseNotifier):
    """
    Stub. Swap the body of send() for a real provider (SES/SendGrid/SMTP)
    when there's budget for a paid API -- interface stays the same.
    """

    channel = NotificationChannel.EMAIL

    async def send(self, city: str, alert_payload: dict) -> bool:
        logger.info("[stub:email] Would email alert for '%s': %s", city, alert_payload.get("message"))
        return False


class SMSNotifier(BaseNotifier):
    """Stub. Swap for Twilio/etc later -- interface stays the same."""

    channel = NotificationChannel.SMS

    async def send(self, city: str, alert_payload: dict) -> bool:
        logger.info("[stub:sms] Would SMS alert for '%s': %s", city, alert_payload.get("message"))
        return False


class PushNotifier(BaseNotifier):
    """Stub. Swap for FCM/APNs later -- interface stays the same."""

    channel = NotificationChannel.PUSH

    async def send(self, city: str, alert_payload: dict) -> bool:
        logger.info("[stub:push] Would push alert for '%s': %s", city, alert_payload.get("message"))
        return False


class NotificationService:
    """
    Fans a single alert event out across every registered channel.
    WebSocket is live today; Email/SMS/Push are stubs that log and return
    False, so they're already wired into the flow and just need a real
    provider dropped in behind the same `send()` interface.
    """

    def __init__(self, notifiers: List[BaseNotifier] | None = None):
        self._notifiers = notifiers or [
            WebSocketNotifier(),
            EmailNotifier(),
            SMSNotifier(),
            PushNotifier(),
        ]

    async def notify(self, city: str, location: dict, overall_risk: dict, alerts: list) -> dict:
        """
        Build one alert payload and send it through every channel.
        Returns a per-channel delivery report, useful for debugging/demo.
        """

        payload = {
            "event": "weather_alert",
            "city": city,
            "location": location,
            "overall_risk": overall_risk,
            "alerts": alerts,
            "alert_count": len(alerts),
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }

        results = {}
        for notifier in self._notifiers:
            try:
                results[notifier.channel.value] = await notifier.send(city, payload)
            except Exception as error:
                logger.warning("Notifier '%s' raised an error: %s", notifier.channel.value, error)
                results[notifier.channel.value] = False

        return results


notification_service = NotificationService()
