from typing import Optional

from pydantic import BaseModel, Field


class SignupRequest(BaseModel):
    email: str = Field(..., description="User email")
    password: str = Field(..., min_length=6, description="Minimum 6 characters")


class LoginRequest(BaseModel):
    email: str
    password: str


class AuthUser(BaseModel):
    id: str
    email: Optional[str] = None


class AuthResponse(BaseModel):
    success: bool
    message: Optional[str] = None
    user: Optional[AuthUser] = None
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None