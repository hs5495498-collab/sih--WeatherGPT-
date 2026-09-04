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


class AlertsResponse(BaseModel):
    success: bool
    location: AlertLocation
    overall_risk: OverallRisk
    risks: RiskBreakdown
    alerts: List[AlertItem]
    alert_count: int
    message: str
