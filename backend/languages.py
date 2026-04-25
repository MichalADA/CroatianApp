"""Rejestr obsługiwanych języków.

Żeby dodać nowy język:
  1. Dopisz wpis poniżej.
  2. Uruchom backend — pusta baza /data/languages/<code>.db utworzy się sama.
  3. Wypełnij content (np. seed albo import) i tyle.
"""

SUPPORTED = {
    "hr": {
        "code": "hr",
        "name": "Chorwacki",
        "title": "Chorwacki od podstaw",
        "flag": "🇭🇷",
    },
    "es": {
        "code": "es",
        "name": "Hiszpański",
        "title": "Hiszpański od podstaw",
        "flag": "🇪🇸",
    },
    "el": {
        "code": "el",
        "name": "Grecki",
        "title": "Grecki od podstaw",
        "flag": "🇬🇷",
    },
}

DEFAULT_LANGUAGE = "hr"


def is_supported(code: str) -> bool:
    return code in SUPPORTED


def codes() -> list[str]:
    return list(SUPPORTED.keys())


def info(code: str) -> dict:
    return SUPPORTED.get(code, SUPPORTED[DEFAULT_LANGUAGE])
