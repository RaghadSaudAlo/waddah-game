import json
from pathlib import Path
from typing import Dict, List, Any


DATA_DIR = Path(__file__).resolve().parent.parent / "data"
WORD_BANK_PATH = DATA_DIR / "word_bank.json"


def load_word_bank() -> Dict[str, Any]:
    with open(WORD_BANK_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def get_phoneme_bank(target_phoneme: str) -> Dict[str, Any]:
    word_bank = load_word_bank()
    return word_bank.get(target_phoneme, {})


def get_words_for_stage(target_phoneme: str, stage: str) -> List[str]:
    """
    ترجع الكلمات/النصوص المناسبة للمرحلة المطلوبة.
    المراحل المدعومة:
    - isolation
    - one_syllable
    - two_syllables
    - word_initial
    - word_medial
    - word_final
    - phrase
    - sentence
    """

    phoneme_bank = get_phoneme_bank(target_phoneme)

    if not phoneme_bank:
        return []

    if stage == "isolation":
        return phoneme_bank.get("isolation", [])

    if stage == "one_syllable":
        one_syllable = phoneme_bank.get("one_syllable", {})
        return (
            one_syllable.get("initial", [])
            + one_syllable.get("medial", [])
            + one_syllable.get("final", [])
        )

    if stage == "two_syllables":
        two_syllables = phoneme_bank.get("two_syllables", {})
        return (
            two_syllables.get("initial", [])
            + two_syllables.get("medial", [])
            + two_syllables.get("final", [])
        )

    if stage == "word_initial":
        return (
            phoneme_bank.get("one_syllable", {}).get("initial", [])
            + phoneme_bank.get("two_syllables", {}).get("initial", [])
            + phoneme_bank.get("three_or_more_syllables", {}).get("initial", [])
        )

    if stage == "word_medial":
        return (
            phoneme_bank.get("one_syllable", {}).get("medial", [])
            + phoneme_bank.get("two_syllables", {}).get("medial", [])
            + phoneme_bank.get("three_or_more_syllables", {}).get("medial", [])
        )

    if stage == "word_final":
        return (
            phoneme_bank.get("one_syllable", {}).get("final", [])
            + phoneme_bank.get("two_syllables", {}).get("final", [])
            + phoneme_bank.get("three_or_more_syllables", {}).get("final", [])
        )

    if stage == "phrase":
        return phoneme_bank.get("phrase", [])

    if stage == "sentence":
        return phoneme_bank.get("sentence", [])

    return []


def get_structured_words_for_stage(target_phoneme: str, stage: str) -> Dict[str, List[str]]:
    """
    نسخة منظمة أكثر، إذا احتجنا نعرض الكلمات حسب الموضع بدل قائمة واحدة.
    """

    phoneme_bank = get_phoneme_bank(target_phoneme)

    if not phoneme_bank:
        return {
            "initial": [],
            "medial": [],
            "final": []
        }

    if stage == "one_syllable":
        return phoneme_bank.get("one_syllable", {
            "initial": [],
            "medial": [],
            "final": []
        })

    if stage == "two_syllables":
        return phoneme_bank.get("two_syllables", {
            "initial": [],
            "medial": [],
            "final": []
        })

    if stage == "word_initial":
        return {
            "initial": (
                phoneme_bank.get("one_syllable", {}).get("initial", [])
                + phoneme_bank.get("two_syllables", {}).get("initial", [])
                + phoneme_bank.get("three_or_more_syllables", {}).get("initial", [])
            ),
            "medial": [],
            "final": []
        }

    if stage == "word_medial":
        return {
            "initial": [],
            "medial": (
                phoneme_bank.get("one_syllable", {}).get("medial", [])
                + phoneme_bank.get("two_syllables", {}).get("medial", [])
                + phoneme_bank.get("three_or_more_syllables", {}).get("medial", [])
            ),
            "final": []
        }

    if stage == "word_final":
        return {
            "initial": [],
            "medial": [],
            "final": (
                phoneme_bank.get("one_syllable", {}).get("final", [])
                + phoneme_bank.get("two_syllables", {}).get("final", [])
                + phoneme_bank.get("three_or_more_syllables", {}).get("final", [])
            )
        }

    return {
        "initial": [],
        "medial": [],
        "final": []
    }