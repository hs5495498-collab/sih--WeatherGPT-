from typing import List, Optional

from pydantic import BaseModel


class AlertLocation(BaseModel):
    city: str
    state: Optional[str] = None
    country: Optional[str] = None
    latitude: float
    longitude: float


class RiskDetail(BaseModel):
    risk: str
    score: int
    message: str


class RiskBreakdown(BaseModel):
    heat: RiskDetail
    rain: RiskDetail
    wind: RiskDetail
    flood: RiskDetail


class OverallRisk(BaseModel):
    risk: str
    score: int


class AlertItem(BaseModel):
    type: str
    title: str
    severity: str
    score: int
    message: str
    recommendations: List[str]
    # Every alert must declare what kind of information it is, so a client
    # can never mistake a locally-generated advisory for an official
    # government warning. Until a real IMD/NDMA feed is wired in (see
    # AlertsResponse.official_provider_active), every alert this service
    # produces is AUTOMATED_ADVISORY -- never OFFICIAL_WARNING.
    information_class: str = "AUTOMATED_ADVISORY"


class AlertsResponse(BaseModel):
    success: bool
    location: AlertLocation
    overall_risk: OverallRisk
    risks: RiskBreakdown
    alerts: List[AlertItem]
    alert_count: int
    message: str
    # Honesty fields: false/blank today because no official alert provider
    # is configured. A future IMD/NDMA integration would flip this to True
    # and start returning OFFICIAL_WARNING items alongside these
    # AUTOMATED_ADVISORY ones -- never silently replacing the disclosure.
    official_provider_active: bool = False
    provider_status: str = (
        "No official IMD/NDMA alert feed is configured. All alerts below "
        "are generated locally from live weather data against fixed "
        "meteorological thresholds -- not an official government warning."
    )
