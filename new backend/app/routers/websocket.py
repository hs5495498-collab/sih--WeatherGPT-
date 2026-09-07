import logging

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse

from app.services.websocket_manager import websocket_manager

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Real-time Alerts"])


@router.websocket("/ws/weather-alerts")
async def weather_alerts_socket(
    websocket: WebSocket,
    city: str = Query(..., min_length=2, description="City to subscribe to, e.g. Delhi"),
):
    """
    Subscribe to live weather alerts for a city.

    Connect with: ws://<host>/ws/weather-alerts?city=Delhi

    You'll receive a JSON message immediately on connect, then a new
    JSON message every time:
      - the background poller detects a risk change for this city, or
      - GET /api/v1/alerts?city=<this city> is called by anyone.

    Message shape:
        {
          "event": "weather_alert" | "subscribed",
          "city": "...",
          "location": {...},
          "overall_risk": {...},
          "alerts": [...],
          "alert_count": 0,
          "timestamp": "..."
        }
    """

    city_key = await websocket_manager.connect(websocket, city)

    try:
        await websocket.send_json(
            {
                "event": "subscribed",
                "city": city_key,
                "message": f"Subscribed to real-time weather alerts for '{city_key}'.",
            }
        )

        # Keep the connection open and listen for client pings/messages.
        # We don't require the client to send anything -- this just keeps
        # the receive loop alive so we detect disconnects promptly.
        while True:
            await websocket.receive_text()

    except WebSocketDisconnect:
        pass

    except Exception as error:
        logger.warning("WebSocket error for city='%s': %s", city_key, error)

    finally:
        websocket_manager.disconnect(websocket)


@router.get("/ws/test", response_class=HTMLResponse, include_in_schema=False)
async def websocket_test_page():
    """Tiny built-in test page so the socket can be demoed without a client."""

    return """
<!DOCTYPE html>
<html>
<head>
  <title>WeatherGPT — Live Alerts Test</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 640px; margin: 40px auto; padding: 0 16px; }
    h2 { margin-bottom: 4px; }
    #status { font-size: 14px; color: #888; margin-bottom: 16px; }
    #status.connected { color: #1a7f37; }
    input, button { font-size: 14px; padding: 8px 10px; }
    input { width: 200px; }
    #log { border: 1px solid #ddd; border-radius: 6px; padding: 12px; height: 400px;
           overflow-y: auto; background: #fafafa; margin-top: 16px; }
    .msg { padding: 8px 0; border-bottom: 1px solid #eee; font-size: 13px; white-space: pre-wrap; }
    .msg:last-child { border-bottom: none; }
  </style>
</head>
<body>
  <h2>Live Weather Alerts</h2>
  <div id="status">disconnected</div>
  <input id="city" placeholder="City, e.g. Delhi" value="Delhi" />
  <button onclick="connect()">Connect</button>
  <button onclick="disconnect()">Disconnect</button>
  <div id="log"></div>

  <script>
    let ws = null;

    function log(text) {
      const el = document.getElementById('log');
      const div = document.createElement('div');
      div.className = 'msg';
      div.textContent = new Date().toLocaleTimeString() + '  ' + text;
      el.appendChild(div);
      el.scrollTop = el.scrollHeight;
    }

    function connect() {
      if (ws) ws.close();
      const city = document.getElementById('city').value.trim();
      if (!city) return;

      const proto = location.protocol === 'https:' ? 'wss' : 'ws';
      ws = new WebSocket(`${proto}://${location.host}/ws/weather-alerts?city=${encodeURIComponent(city)}`);

      ws.onopen = () => {
        document.getElementById('status').textContent = 'connected';
        document.getElementById('status').className = 'connected';
        log('Connected, subscribing to ' + city);
      };
      ws.onmessage = (event) => log(event.data);
      ws.onclose = () => {
        document.getElementById('status').textContent = 'disconnected';
        document.getElementById('status').className = '';
        log('Disconnected');
      };
      ws.onerror = () => log('Error on socket');
    }

    function disconnect() {
      if (ws) ws.close();
    }
  </script>
</body>
</html>
"""
