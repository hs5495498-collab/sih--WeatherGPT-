import logging
from typing import Dict, Set

from fastapi import WebSocket

logger = logging.getLogger(__name__)


def _normalize_city(city: str) -> str:
    """Case/whitespace-insensitive city key so 'Delhi' and 'delhi ' group together."""
    return city.strip().lower()


class WebSocketManager:
    """
    Tracks live WebSocket connections grouped by the city they subscribed to.

    One socket can only be subscribed to one city at a time (matches the
    /ws/weather-alerts?city=... contract). Broadcasting to a city pushes to
    every socket currently subscribed to it.
    """

    def __init__(self):
        # city_key -> set of active sockets
        self._city_connections: Dict[str, Set[WebSocket]] = {}
        # socket -> city_key, so we can clean up on disconnect without a scan
        self._connection_city: Dict[WebSocket, str] = {}

    async def connect(self, websocket: WebSocket, city: str) -> str:
        await websocket.accept()

        city_key = _normalize_city(city)
        self._city_connections.setdefault(city_key, set()).add(websocket)
        self._connection_city[websocket] = city_key

        logger.info(
            "WebSocket connected for city='%s' (total for city: %d)",
            city_key,
            len(self._city_connections[city_key]),
        )
        return city_key

    def disconnect(self, websocket: WebSocket):
        city_key = self._connection_city.pop(websocket, None)

        if city_key and city_key in self._city_connections:
            self._city_connections[city_key].discard(websocket)

            if not self._city_connections[city_key]:
                del self._city_connections[city_key]

        logger.info("WebSocket disconnected (was subscribed to city='%s')", city_key)

    def subscribed_cities(self) -> Set[str]:
        """All cities that currently have at least one live subscriber."""
        return set(self._city_connections.keys())

    def subscriber_count(self, city: str) -> int:
        return len(self._city_connections.get(_normalize_city(city), set()))

    async def broadcast_to_city(self, city: str, payload: dict):
        """Send a JSON payload to every socket subscribed to this city."""

        city_key = _normalize_city(city)
        sockets = list(self._city_connections.get(city_key, set()))

        if not sockets:
            return 0

        dead_sockets = []

        for socket in sockets:
            try:
                await socket.send_json(payload)
            except Exception as error:
                logger.warning("Failed to push to a socket on '%s': %s", city_key, error)
                dead_sockets.append(socket)

        for socket in dead_sockets:
            self.disconnect(socket)

        return len(sockets) - len(dead_sockets)


websocket_manager = WebSocketManager()
