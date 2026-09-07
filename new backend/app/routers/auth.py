from fastapi import APIRouter, Depends, HTTPException

from app.schemas.auth import SignupRequest, LoginRequest, AuthResponse
from app.services.auth_service import auth_service
from app.dependencies.auth import get_current_user


router = APIRouter(prefix="/api/v1/auth", tags=["Auth"])


@router.post("/signup", response_model=AuthResponse)
async def signup(request: SignupRequest):
    try:
        result = await auth_service.sign_up(request.email, request.password)

        # If Supabase has "Confirm email" enabled (default for new
        # projects), no session/access_token is issued until the user
        # clicks the confirmation link in their email.
        message = (
            "Signup successful."
            if result["access_token"]
            else "Signup successful. Check your email to confirm your account, then log in."
        )

        return AuthResponse(success=True, message=message, **result)

    except Exception as error:
        raise HTTPException(status_code=400, detail=f"Signup failed: {str(error)}")


@router.post("/login", response_model=AuthResponse)
async def login(request: LoginRequest):
    try:
        result = await auth_service.sign_in(request.email, request.password)
        return AuthResponse(success=True, message="Login successful.", **result)

    except Exception:
        raise HTTPException(status_code=401, detail="Invalid email or password.")


@router.get("/me", response_model=AuthResponse)
async def get_me(current_user=Depends(get_current_user)):
    return AuthResponse(
        success=True,
        user={"id": current_user.id, "email": current_user.email}
    )