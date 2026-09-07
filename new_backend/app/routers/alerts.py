import logging

from fastapi import APIRouter, HTTPException, Query

from app.services.location_service import location_service
from app.services.weather_service import weather_service
from app.services.risk_service import risk_service
from app.services.alert_service import alert_service
from app.services.notification_service import notification_service

from app.schemas.alert import AlertsResponse

logger = logging.getLogger(__name__)


router = APIRouter(
    prefix="/api/v1/alerts",
    tags=["Alerts"]
)


@router.get("/", response_model=AlertsResponse)
async def get_alerts(
    city: str = Query(..., min_length=2, description="City name, e.g. Delhi")
):
    """
    Return active weather alerts for a city.

    Flow:
    City -> Location Service -> Weather Service -> Risk Service -> Alert Service -> JSON Response

    Reuses risk_service.analyze_location() (which already wraps location +
    current/forecast weather + risk scoring) and alert_service.generate_alerts()
    so alert logic isn't duplicated across the codebase.
    """

    try:
        risk_result = await risk_service.analyze_location(
            city=city,
            location_service=location_service,
            weather_service=weather_service
        )

        if not risk_result.get("success"):
            raise HTTPException(
                status_code=404,
                detail=risk_result.get(
                    "message",
                    f"Location '{city}' could not be found."
                )
            )

        risks = risk_result["risks"]
        overall_risk = risk_result["overall_risk"]

        active_alerts = alert_service.generate_alerts(risks)

        await notification_service.notify(
            city=risk_result["location"]["city"],
            location=risk_result["location"],
            overall_risk=overall_risk,
            alerts=active_alerts,
        )

        if active_alerts:
            message = (
                f"{overall_risk['risk']} weather risk detected for "
                f"{risk_result['location']['city']}. "
                f"{len(active_alerts)} active alert(s)."
            )
        else:
            message = (
                f"No significant weather risks are currently detected "
                f"for {risk_result['location']['city']}."
            )

        return AlertsResponse(
            success=True,
            location=risk_result["location"],
            overall_risk=overall_risk,
            risks=risks,
            alerts=active_alerts,
            alert_count=len(active_alerts),
            message=message,
            official_provider_active=False,
            provider_status=(
                "No official IMD/NDMA alert feed is configured. All alerts "
                "above are generated locally from live weather data against "
                "fixed meteorological thresholds -- not an official "
                "government warning."
            ),
        )

    except HTTPException:
        raise

    except Exception as error:
        logger.error("Unexpected error generating alerts for city='%s': %s", city, error)
        raise