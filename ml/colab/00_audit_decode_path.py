# colab/00_audit_decode_path.py
# RUN THIS FIRST, in your existing notebook, right after cell 3B.
#
# Purpose: demonstrate that `tokenizer.decode(...).split()` — the decode path
# used in cell 5A (compute_per) and cell 6A (decode_predictions) — returns the
# wrong number of phonemes for any word containing a multi-character phoneme.
#
# Verified on transformers==4.44.2. Expect roughly 70-90% of your 84 lexicon
# words to FAIL this audit, because aː / uː / iː appear in most of them.

MULTI = [p for p in sorted(all_phonemes) if len(p) > 1]
print(f"Multi-character phonemes in vocab ({len(MULTI)}): {MULTI}\n")

print("=== Audit: does decode().split() round-trip a phoneme sequence? ===")
fails, total = 0, 0
examples = []

for word, entry in word_to_phonemes.items():
    seq = entry["phoneme_sequence"]
    label_str = " ".join(seq)                      # exactly what cell 3C builds
    ids = tokenizer(label_str).input_ids
    decoded = tokenizer.decode(ids, skip_special_tokens=True)
    recovered = decoded.split()                    # exactly what cell 6A does
    total += 1
    if recovered != seq:
        fails += 1
        if len(examples) < 8:
            examples.append((word, seq, decoded, recovered))

print(f"\n{fails} of {total} lexicon words do NOT survive encode -> decode -> split.\n")
for word, seq, decoded, recovered in examples:
    print(f"  {word}")
    print(f"     canonical ({len(seq)}): {seq}")
    print(f"     decoded            : {decoded!r}")
    print(f"     .split()  ({len(recovered)}): {recovered}")

if fails:
    print("\n" + "=" * 70)
    print("IMPACT")
    print("  cell 5A  compute_per        : reference lengths are wrong -> PER wrong")
    print("  cell 6A  decode_predictions : `predicted` is fused while `canonical`")
    print("                                is not, so every Levenshtein alignment")
    print("                                is wrong -> detection acc, diagnosis acc,")
    print("                                PER, WER, precision/recall/F1 all wrong")
    print("  cell 6C  per-phoneme table  : built on the same bad alignments")
    print()
    print("GOOD NEWS: the vocabulary and the trained weights are fine. Output")
    print("index i still means the same phoneme. You do NOT need to retrain for")
    print("this — apply 01_fix_decode_path.py and re-run Phase 6 only.")
    print("=" * 70)
else:
    print("No fusion detected. Check your transformers version and move on.")
