"""Hashowanie haseł, JWT (HS256), dependency `current_user`.

JWT robimy ręcznie na stdlib (hmac/hashlib/base64) — bez dodatkowych zależności
od cryptography/PyJWT. Wystarczy nam HS256 i to jest dokładnie to, co opisuje
sekcja 4.4 RFC 7515. Format identyczny jak biblioteczne JWT —
zewnętrzni klienci mogą weryfikować standardowymi narzędziami.
"""
from datetime import datetime, timedelta, timezone
from typing import Optional
import base64
import hashlib
import hmac
import json
import os

from fastapi import Depends, HTTPException, Request, status
from sqlalchemy.orm import Session
from passlib.context import CryptContext

import models
import database

SECRET_KEY = os.getenv("AUTH_SECRET_KEY", "dev-secret-change-me-please-1234567890abcdef")
ALGORITHM = "HS256"
TOKEN_TTL_DAYS = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ─── password ────────────────────────────────────────────────────────────────

def hash_password(plain: str) -> str:
    return pwd_context.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return pwd_context.verify(plain, hashed)
    except Exception:
        return False


# ─── JWT (HS256, stdlib only) ────────────────────────────────────────────────

def _b64url(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode("ascii")


def _b64url_decode(s: str) -> bytes:
    pad = "=" * (-len(s) % 4)
    return base64.urlsafe_b64decode(s + pad)


def create_token(user_id: int) -> str:
    header = {"alg": "HS256", "typ": "JWT"}
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(days=TOKEN_TTL_DAYS)).timestamp()),
    }
    h = _b64url(json.dumps(header, separators=(",", ":")).encode())
    p = _b64url(json.dumps(payload, separators=(",", ":")).encode())
    signing_input = f"{h}.{p}".encode()
    sig = hmac.new(SECRET_KEY.encode(), signing_input, hashlib.sha256).digest()
    return f"{h}.{p}.{_b64url(sig)}"


def _decode(token: str) -> Optional[int]:
    try:
        h, p, s = token.split(".")
    except ValueError:
        return None
    try:
        signing_input = f"{h}.{p}".encode()
        expected = hmac.new(SECRET_KEY.encode(), signing_input, hashlib.sha256).digest()
        if not hmac.compare_digest(expected, _b64url_decode(s)):
            return None
        payload = json.loads(_b64url_decode(p))
        if int(payload.get("exp", 0)) < int(datetime.now(timezone.utc).timestamp()):
            return None
        return int(payload["sub"])
    except (ValueError, TypeError, KeyError, json.JSONDecodeError):
        return None


# ─── current_user dependency ─────────────────────────────────────────────────

def _get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_current_user(request: Request, db: Session = Depends(_get_db)) -> models.User:
    """Wymaga ważnego tokena Bearer w nagłówku Authorization."""
    auth = request.headers.get("authorization") or request.headers.get("Authorization")
    if not auth or not auth.lower().startswith("bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Brak tokena autoryzacji",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = auth.split(" ", 1)[1].strip()
    user_id = _decode(token)
    if user_id is None:
        raise HTTPException(401, "Nieprawidłowy lub wygasły token", headers={"WWW-Authenticate": "Bearer"})
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(401, "Użytkownik nie istnieje", headers={"WWW-Authenticate": "Bearer"})
    return user
