import json
from pathlib import Path


DATA_DIR = Path(__file__).resolve().parent.parent / "data"
AGE_NORMS_PATH = DATA_DIR / "age_norms.json"


def load_age_norms() -> dict:
    with open(AGE_NORMS_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def get_age_status(target_phoneme: str, child_age: int) -> str:
    """
    ترجع:
    - needs_therapy
    - age_appropriate
    """

    age_norms = load_age_norms()

    if target_phoneme not in age_norms:
        # لو الحرف غير موجود، نعتبره يحتاج مراجعة علاجية
        return "needs_therapy"

    phoneme_rule = age_norms[target_phoneme]
    expected_by_age = phoneme_rule["expected_by_age"]

    if child_age < expected_by_age:
        return phoneme_rule["status_if_younger"]

    return phoneme_rule["status_if_older"]