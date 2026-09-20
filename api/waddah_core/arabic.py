# waddah_core/arabic.py
# Purpose: Arabic text normalization + letter-level G2P fallback.
# COPIED VERBATIM from Waddah_MDD_V3_CTC.ipynb cells 1A and 1D.
# Do NOT edit without re-running tests/test_parity.py — training and serving
# must share byte-identical logic or the deployed model silently degrades.

import re

__all__ = ["normalize_arabic", "LETTER_TO_PHONEME", "get_phonemes"]


def normalize_arabic(text: str) -> str:
    """Strip diacritics (U+064B-U+0652, U+0670), unify hamza forms, alif maksura."""
    text = re.sub(r"[ً-ْٰ]", "", text)
    text = text.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا")
    text = text.replace("ى", "ي")
    return text.strip()


LETTER_TO_PHONEME = {
    "ب": "b",   "ت": "t",   "ث": "θ",   "ج": "dʒ",  "ح": "ħ",   "خ": "χ",
    "د": "d",   "ذ": "ð",   "ر": "r",   "ز": "z",   "س": "s",   "ش": "ʃ",
    "ص": "sˤ",  "ض": "dˤ",  "ط": "tˤ",  "ظ": "ðˤ",  "ع": "ʕ",   "غ": "γ",
    "ف": "f",   "ق": "q",   "ك": "k",   "ل": "l",   "م": "m",   "ن": "n",
    "ه": "h",   "و": "uː",  "ي": "iː",  "ا": "aː",
    "ى": "aː",  "ء": "ʔ",   "أ": "ʔ",   "إ": "ʔ",   "آ": "ʔ",   "ة": "a",
}


def get_phonemes(word: str, lexicon: dict) -> tuple:
    """Return (phoneme_list, source) where source in {'lexicon', 'letter_g2p'}."""
    norm = normalize_arabic(word)
    if norm in lexicon:
        return lexicon[norm]["phoneme_sequence"], "lexicon"
    return [LETTER_TO_PHONEME[c] for c in norm if c in LETTER_TO_PHONEME], "letter_g2p"
