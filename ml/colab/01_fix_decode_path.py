# colab/01_fix_decode_path.py
# REPLACES the decoding logic inside notebook cells 5A and 6A.
# No vocabulary change, no retraining — output index i already means the right
# phoneme. Only the id -> phoneme step changes.
#
# Prereq — clone the repo into Colab so training and serving share one copy of
# the logic instead of two that drift:
#
#     !git clone https://github.com/<your-team>/waddah.git /content/waddah
#     import sys; sys.path.insert(0, "/content/waddah/api")

from waddah_core import ctc_decode_ids, id_to_phoneme_map, lexicon_hash

ID2PH = id_to_phoneme_map(vocab_dict)
BLANK_ID = vocab_dict["<pad>"]
LEXICON_SHA = lexicon_hash(LEXICON_PATH)
print(f"id -> phoneme map built: {len(ID2PH)} phonemes, blank id = {BLANK_ID}")


# ---- 5A (replacement) ------------------------------------------------------
def compute_per(pred):
    """Phoneme Error Rate. Decodes from ids, never from a fused string."""
    pred_ids = pred.predictions.argmax(-1)
    label_ids = pred.label_ids.copy()

    total_ref, total_errors = 0, 0
    for p_row, l_row in zip(pred_ids, label_ids):
        hyp = ctc_decode_ids(p_row, ID2PH, BLANK_ID)
        # Labels are not CTC-collapsed; -100 is the padding sentinel.
        ref = [ID2PH[int(i)] for i in l_row if int(i) != -100 and int(i) in ID2PH]
        if not ref:
            continue
        s, d, i_, _ = levenshtein_align(ref, hyp)
        total_errors += s + d + i_
        total_ref += len(ref)

    return {"per": total_errors / total_ref if total_ref else 1.0}


# ---- 6A (replacement for the decode step only) -----------------------------
# In decode_predictions(), replace these two lines:
#
#     pred_tokens = tokenizer.decode(pred_ids[i], skip_special_tokens=True)
#     pred_phonemes = pred_tokens.split() if pred_tokens.strip() else []
#
# with:
#
#     pred_phonemes = ctc_decode_ids(pred_ids[i], ID2PH, BLANK_ID)
#
# Everything downstream (levenshtein_align, diagnose_at_target, the metrics
# block in 6B, the per-phoneme table in 6C) then operates on correctly
# separated phonemes and needs no further change.


# ---- Verification ----------------------------------------------------------
print("\n=== Verifying the new decode path on label sequences ===")
fails = 0
for word, entry in list(word_to_phonemes.items()):
    seq = entry["phoneme_sequence"]
    ids = [vocab_dict[p] for p in seq if p in vocab_dict]
    recovered = ctc_decode_ids(ids, ID2PH, BLANK_ID)
    # CTC collapse legitimately merges adjacent identical phonemes; compare
    # against the collapsed reference so gemination is not a false failure.
    collapsed = [p for j, p in enumerate(seq) if j == 0 or p != seq[j - 1]]
    if recovered != collapsed:
        fails += 1
        print(f"  MISMATCH {word}: {seq} -> {recovered}")

print(f"{len(word_to_phonemes) - fails}/{len(word_to_phonemes)} lexicon words decode exactly.")
assert fails == 0, "Investigate before re-running Phase 6."
print("Decode path is clean. Re-run cells 6A-6E and report the new numbers.")
