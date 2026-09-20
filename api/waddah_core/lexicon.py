# waddah_core/lexicon.py
# Purpose: load arabic_phoneme_lexicon.csv into the canonical word -> phoneme map.
# COPIED VERBATIM from notebook cell 1B, plus a frozen-hash helper.

import hashlib

import pandas as pd

from .arabic import normalize_arabic

__all__ = ["load_lexicon", "lexicon_hash"]


def load_lexicon(csv_path: str) -> tuple:
    """Load lexicon CSV -> ({word: {...}}, set_of_all_phonemes).

    Returns the same structure the training notebook used, so canonical
    sequences at inference are identical to those used for supervision.
    """
    df = pd.read_csv(csv_path, encoding="utf-8")
    lexicon = {}
    all_phonemes = set()

    for _, row in df.iterrows():
        word = normalize_arabic(str(row["word"]).strip())
        raw_seq = str(row["phoneme_sequence"]).strip()
        phonemes = [p.strip().strip("/") for p in raw_seq.split() if p.strip().strip("/")]
        all_phonemes.update(phonemes)

        target_ph = str(row["target_phoneme"]).strip().strip("/")
        target_idx = None
        for i, ph in enumerate(phonemes):
            if ph == target_ph:
                target_idx = i
                break
        if target_idx is None:
            target_idx = 0  # fallback

        lexicon[word] = {
            "phoneme_sequence": phonemes,
            "target_phoneme": target_ph,
            "target_phoneme_idx": target_idx,
            "phoneme_position": str(row.get("phoneme_position", "")).strip(),
        }

    return lexicon, all_phonemes


def lexicon_hash(csv_path: str) -> str:
    """SHA256 of the lexicon file.

    Why: the phoneme vocabulary (and therefore every CTC output index) is
    derived from this file. If the CSV changes after training, the checkpoint's
    output layer no longer means what it meant. The API refuses to start on a
    hash mismatch rather than serving silently-wrong predictions.
    """
    with open(csv_path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()
