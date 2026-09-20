# waddah_core/vocab.py
# Purpose: build the CTC phoneme vocabulary, and decode CTC output WITHOUT
# going through tokenizer.decode() -> str.split().
#
# ---------------------------------------------------------------------------
# THE PROBLEM (verified on transformers==4.44.2 — reproduce it with
# colab/00_audit_decode_path.py before you change anything)
#
# Wav2Vec2CTCTokenizer does greedy longest-match over the vocabulary. When a
# multi-character phoneme follows the word delimiter, the delimiter is
# swallowed. Measured:
#
#     ['k','a','l','b']        -> decode 'k a l b'  -> split() 4 items  OK
#     ['b','aː','b']           -> decode 'baːb'     -> split() 1 item   WRONG
#     ['ħ','i','sˤ','aː','n']  -> decode 'ħ sˤaːn'  -> split() 2 items  WRONG
#
# Eight Waddah phonemes are multi-character: dʒ sˤ dˤ tˤ ðˤ aː uː iː.
# The three long vowels appear in most of the 84 words.
#
# CONSEQUENCE: notebook cell 6A builds `predicted` with
# `tokenizer.decode(...).split()` and aligns it against a `canonical` list
# taken straight from the lexicon. For any word with a long vowel, a 5-phoneme
# prediction is compared as 2 symbols against 5. PER, detection accuracy,
# diagnosis accuracy and the per-phoneme table in Phase 6 are all affected.
# Cell 5A's compute_per has the same flaw.
#
# THE FIX: collapse the CTC frame sequence and map integer ids straight to
# phonemes. The tokenizer string layer is never involved, so nothing can fuse.
#
# NOTE ON RETRAINING: the vocabulary itself is correct — index i means the same
# phoneme before and after this fix. So an existing checkpoint can simply be
# RE-DECODED and re-evaluated. No retraining is needed for this defect.
# ---------------------------------------------------------------------------

import json

__all__ = [
    "build_vocab_dict",
    "id_to_phoneme_map",
    "ctc_decode_ids",
    "save_vocab_bundle",
    "load_vocab_bundle",
]


def build_vocab_dict(all_phonemes) -> dict:
    """Identical to notebook cell 3A — kept here so there is one definition."""
    vocab_dict = {"<pad>": 0, "<unk>": 1, "|": 2}
    for i, ph in enumerate(sorted(all_phonemes), start=3):
        vocab_dict[ph] = i
    return vocab_dict


def id_to_phoneme_map(vocab_dict: dict) -> dict:
    """Reverse map, with the three special tokens excluded."""
    special = {"<pad>", "<unk>", "|"}
    return {int(i): tok for tok, i in vocab_dict.items() if tok not in special}


def ctc_decode_ids(pred_ids, id2ph: dict, blank_id: int = 0) -> list:
    """Greedy CTC decode: collapse repeats, drop blanks, map ids to phonemes.

    This is the ONLY decode path that should be used anywhere in the project —
    in the notebook's compute_per, in decode_predictions, and in the API.
    """
    out, prev = [], None
    for raw in pred_ids:
        idx = int(raw)
        if idx != prev:
            if idx != blank_id and idx in id2ph:
                out.append(id2ph[idx])
        prev = idx
    return out


def save_vocab_bundle(path: str, vocab_dict: dict, lexicon_sha: str) -> None:
    """Persist the label space plus the lexicon fingerprint it was built from."""
    with open(path, "w", encoding="utf-8") as f:
        json.dump(
            {"vocab": vocab_dict, "lexicon_sha256": lexicon_sha, "format_version": 2},
            f,
            ensure_ascii=False,
            indent=2,
        )


def load_vocab_bundle(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        bundle = json.load(f)
    bundle["id2ph"] = id_to_phoneme_map(bundle["vocab"])
    return bundle
