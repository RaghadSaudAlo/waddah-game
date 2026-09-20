# waddah_core/__init__.py
# Shared logic imported by BOTH the Colab training notebook and the FastAPI
# service. One copy only — this is what prevents train/serve skew.

from .align import diagnose_at_target, levenshtein_align
from .arabic import LETTER_TO_PHONEME, get_phonemes, normalize_arabic
from .lexicon import lexicon_hash, load_lexicon
from .vocab import (
    build_vocab_dict,
    ctc_decode_ids,
    id_to_phoneme_map,
    load_vocab_bundle,
    save_vocab_bundle,
)

__all__ = [
    "normalize_arabic", "LETTER_TO_PHONEME", "get_phonemes",
    "load_lexicon", "lexicon_hash",
    "levenshtein_align", "diagnose_at_target",
    "build_vocab_dict", "id_to_phoneme_map", "ctc_decode_ids",
    "save_vocab_bundle", "load_vocab_bundle",
]
