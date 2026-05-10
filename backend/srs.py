"""Anki-style spaced repetition (SM-2 simplified to day granularity).

4 odpowiedzi:
  znowu  (Again) — nie wiem, karta wraca dziś / +1 dzień (lapse)
  trudne (Hard)  — wiem z trudem, mały wzrost interwału, ease -=
  dobrze (Good)  — wiem, interwał *= ease
  łatwe  (Easy)  — bardzo łatwe, interwał *= ease * bonus, ease +=

Stare odpowiedzi ("nie wiem"/"prawie"/"wiem") są mapowane na nowe,
żeby istniejący frontend dalej działał w trakcie wdrożenia.
"""
from __future__ import annotations
import math
from dataclasses import dataclass


# Stałe SM-2 — dobrane tak, żeby działały w skali dni (Anki używa minut dla
# learning steps; tu pomijamy je, bo aplikacja ma rytm dzienny).
EASE_DEFAULT = 2.5
EASE_MIN = 1.3
EASE_DELTA = {"znowu": -0.20, "trudne": -0.15, "dobrze": 0.0, "łatwe": +0.15}

# Karty świeże (interval == 0) — od razu graduate w 1 lub 4 dni.
GRADUATE_GOOD = 1
GRADUATE_EASY = 4

HARD_MULT = 1.2
EASY_BONUS = 1.3

VALID_ANSWERS = ("znowu", "trudne", "dobrze", "łatwe")

# Mapowanie starych odpowiedzi (3-przyciskowy UI) na nowe.
LEGACY_MAP = {
    "nie wiem": "znowu",
    "prawie": "trudne",
    "wiem": "dobrze",
}


def normalize_answer(answer: str) -> str:
    """Zaakceptuj zarówno nowe (znowu/trudne/dobrze/łatwe) jak i stare odpowiedzi."""
    if answer in VALID_ANSWERS:
        return answer
    if answer in LEGACY_MAP:
        return LEGACY_MAP[answer]
    raise ValueError(f"Nieprawidłowa odpowiedź: {answer!r}")


@dataclass
class SRSState:
    interval: int       # nowy interwał w dniach
    ease_factor: float
    lapses: int
    status: str         # "uczę się" | "znam" | "trudne"


def schedule(answer: str, ease: float, interval: int, lapses: int) -> SRSState:
    """Policz nowy stan karty po odpowiedzi. Czysta funkcja — bez DB."""
    answer = normalize_answer(answer)
    ease = ease if ease and ease >= EASE_MIN else EASE_DEFAULT

    # Karta świeża / wciąż w nauce (jeszcze nigdy nie graduate'owała).
    if interval <= 0:
        if answer == "znowu":
            return SRSState(interval=0, ease_factor=ease, lapses=lapses, status="uczę się")
        if answer == "trudne":
            return SRSState(interval=1, ease_factor=ease, lapses=lapses, status="uczę się")
        if answer == "dobrze":
            return SRSState(interval=GRADUATE_GOOD, ease_factor=ease, lapses=lapses, status="znam")
        # łatwe
        return SRSState(interval=GRADUATE_EASY, ease_factor=ease + EASE_DELTA["łatwe"],
                        lapses=lapses, status="znam")

    # Karta review (już graduate'owała).
    new_ease = max(EASE_MIN, ease + EASE_DELTA[answer])

    if answer == "znowu":
        # Lapse — wraca do relearningu, krótki interwał (1 dzień), licznik lapsów ++.
        return SRSState(interval=1, ease_factor=new_ease, lapses=lapses + 1, status="trudne")

    if answer == "trudne":
        new_int = max(interval + 1, math.ceil(interval * HARD_MULT))
        return SRSState(interval=new_int, ease_factor=new_ease, lapses=lapses, status="znam")

    if answer == "dobrze":
        new_int = max(interval + 1, math.ceil(interval * ease))
        return SRSState(interval=new_int, ease_factor=new_ease, lapses=lapses, status="znam")

    # łatwe
    new_int = max(interval + 1, math.ceil(interval * ease * EASY_BONUS))
    return SRSState(interval=new_int, ease_factor=new_ease, lapses=lapses, status="znam")


def preview_intervals(ease: float, interval: int) -> dict[str, int]:
    """Co-by-było-gdyby — jakie interwały zobaczy user pod każdym przyciskiem.
    Używane do podpisów na guzikach (jak w Anki: '<1d', '3d', '8d', '15d')."""
    return {a: schedule(a, ease, interval, 0).interval for a in VALID_ANSWERS}
