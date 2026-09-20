from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List, Optional


BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"


def _load_json(filename: str) -> Any:
    path = DATA_DIR / filename
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _safe_get(d: dict, keys: List[str], default=None):
    for key in keys:
        if key in d:
            return d[key]
    return default


def load_age_norms() -> Any:
    return _load_json("age_norms.json")


def load_word_bank() -> Any:
    return _load_json("word_bank.json")


def load_therapy_progression() -> Any:
    return _load_json("therapy_progression.json")


def is_age_appropriate(
    age: int,
    target_phoneme: str,
    age_norms_data: Any,
) -> bool:
    """
    يحاول يدعم أكثر من شكل محتمل لملف age_norms
    """

    # شكل 1
    # {
    #   "ء": {"min_age": 5}
    # }
    if isinstance(age_norms_data, dict):
        phoneme_info = age_norms_data.get(target_phoneme)
        if isinstance(phoneme_info, dict):
            min_age = _safe_get(phoneme_info, ["min_age", "age", "expected_age"])
            if isinstance(min_age, int):
                return age < min_age

    # شكل 2
    # [
    #   {"phoneme": "ء", "min_age": 5}
    # ]
    if isinstance(age_norms_data, list):
        for item in age_norms_data:
            if not isinstance(item, dict):
                continue
            phoneme = _safe_get(item, ["phoneme", "target_phoneme", "sound"])
            if phoneme == target_phoneme:
                min_age = _safe_get(item, ["min_age", "age", "expected_age"])
                if isinstance(min_age, int):
                    return age < min_age

    return False


def get_progression_levels(
    target_phoneme: str,
    therapy_progression_data: Any,
) -> Dict[str, Any]:
    """
    يحاول يقرأ التسلسل من therapy_progression
    """

    if isinstance(therapy_progression_data, dict):
        phoneme_info = therapy_progression_data.get(target_phoneme)
        if isinstance(phoneme_info, dict):
            return phoneme_info

    if isinstance(therapy_progression_data, list):
        for item in therapy_progression_data:
            if not isinstance(item, dict):
                continue
            phoneme = _safe_get(item, ["phoneme", "target_phoneme", "sound"])
            if phoneme == target_phoneme:
                return item

    return {
        "levels": ["word", "phrase", "sentence"]
    }


def get_word_bank_for_target(
    word_bank_data: Any,
    target_phoneme: str,
    position: str,
) -> Dict[str, List[str]]:
    """
    يرجع كلمات، عبارات، جمل حسب الحرف والموضع.
    يدعم شكل word_bank الحالي عندك:
    {
      "س": {
        "one_syllable": {"initial": [], "medial": [], "final": []},
        "two_syllables": {"initial": [], "medial": [], "final": []},
        "three_or_more_syllables": {"initial": [], "medial": [], "final": []},
        "phrase": [],
        "sentence": []
      }
    }
    """

    result = {
        "words": [],
        "phrases": [],
        "sentences": [],
    }

    if not isinstance(word_bank_data, dict):
        return result

    phoneme_data = word_bank_data.get(target_phoneme)

    if not isinstance(phoneme_data, dict):
        return result

    for stage in [
        "one_syllable",
        "two_syllables",
        "three_or_more_syllables",
    ]:
        stage_data = phoneme_data.get(stage, {})

        if isinstance(stage_data, dict):
            result["words"].extend(stage_data.get(position, []))

    result["phrases"] = phoneme_data.get("phrase", [])
    result["sentences"] = phoneme_data.get("sentence", [])

    return result

def build_therapy_targets(
    age: int,
    diagnosis_results: List[Dict[str, Any]]
) -> List[Dict[str, Any]]:
    age_norms_data = load_age_norms()

    therapy_targets: List[Dict[str, Any]] = []

    for item in diagnosis_results:
        word = item.get("word", "")
        target_phoneme = item.get("target_phoneme", "")
        position = item.get("position", "initial")
        produced_phoneme = item.get("produced_phoneme", "")

        if not word or not target_phoneme:
            continue

        age_ok = is_age_appropriate(
            age=age,
            target_phoneme=target_phoneme,
            age_norms_data=age_norms_data,
        )

        # إذا طبيعي لعمره ما يحتاج ثيرابي
        if age_ok:
            continue

        therapy_targets.append({
            "word": word,
            "target_phoneme": target_phoneme,
            "position": position,
            "produced_phoneme": produced_phoneme,
            "age_status": "needs_therapy",
        })

    return therapy_targets

def build_therapy_session(
    selected_word: str,
    target_phoneme: str,
    position: str,
) -> Dict[str, Any]:
    word_bank_data = load_word_bank()
    therapy_progression_data = load_therapy_progression()

    phoneme_data = word_bank_data.get(target_phoneme, {})

    progression = get_progression_levels(
        target_phoneme=target_phoneme,
        therapy_progression_data=therapy_progression_data,
    )

    isolation_items = phoneme_data.get("isolation", [])

    one_syllable_items = (
        phoneme_data.get("one_syllable", {}).get(position, [])
    )

    two_syllable_items = (
        phoneme_data.get("two_syllables", {}).get(position, [])
    )

    three_or_more_items = (
        phoneme_data.get("three_or_more_syllables", {}).get(position, [])
    )

    phrase_items = phoneme_data.get("phrase", [])
    sentence_items = phoneme_data.get("sentence", [])

    stages = [
        {
            "stage": "isolation",
            "title": "نطق الحرف لوحده",
            "items": isolation_items[:3],
        },
        {
            "stage": "one_syllable",
            "title": "كلمات قصيرة",
            "items": one_syllable_items[:4],
        },
        {
            "stage": "two_syllables",
            "title": "كلمات أطول",
            "items": two_syllable_items[:4],
        },
        {
            "stage": "three_or_more_syllables",
            "title": "كلمات متقدمة",
            "items": three_or_more_items[:4],
        },
        {
            "stage": "phrase",
            "title": "عبارات قصيرة",
            "items": phrase_items[:3],
        },
        {
            "stage": "sentence",
            "title": "جمل تدريبية",
            "items": sentence_items[:3],
        },
    ]

    # حذف أي مرحلة فاضية، لأن عرض فراغ للطفل فكرة عبقرية سيئة
    stages = [
        stage for stage in stages
        if stage["items"]
    ]

    # fallback لو الحرف غير موجود
    if not stages:
        stages = [
            {
                "stage": "word",
                "title": "كلمة تدريب",
                "items": [selected_word],
            }
        ]

    return {
        "selected_word": selected_word,
        "target_phoneme": target_phoneme,
        "position": position,
        "progression": progression,
        "stages": stages,

        # نخلي القديم موجود مؤقتًا عشان Flutter ما ينكسر
        "word_sequence": one_syllable_items[:4] or two_syllable_items[:4] or [selected_word],
        "phrases": phrase_items[:3],
        "sentences": sentence_items[:3],
    }

