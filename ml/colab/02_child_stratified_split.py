# colab/02_child_stratified_split.py
# REPLACES notebook cell 2B.
#
# WHY THIS MATTERS MORE THAN IT LOOKS
# The current stratified_split() groups by target WORD only. The same child
# (same ID) therefore appears in train, val and test. A large self-supervised
# encoder will memorise speaker identity, so your test scores measure
# "can the model recognise this child's voice" as much as "can it detect
# mispronunciation". Reported accuracy is inflated, and a CCIS examiner who
# asks "is your split speaker-independent?" gets the wrong answer.
#
# Phase 1 Section 0F already specifies a per-child split. This restores it.
# Expect your headline numbers to DROP. That drop is the honest number.

import random
from collections import defaultdict


def child_stratified_split(df, train_ratio=0.8, val_ratio=0.1, seed=42):
    """Split by child ID, balancing the N/AB ratio across splits.

    No child's audio appears in more than one split.
    """
    rng = random.Random(seed)

    # Each child is Normal or Abnormal at the child level; stratify on that.
    child_diag = df.groupby("id")["diagnosis"].agg(
        lambda s: "AB" if (s == "AB").any() else "N"
    )

    buckets = defaultdict(list)
    for child_id, diag in child_diag.items():
        buckets[diag].append(child_id)

    train_ids, val_ids, test_ids = set(), set(), set()
    for diag, ids in buckets.items():
        ids = sorted(ids)
        rng.shuffle(ids)
        n = len(ids)
        n_train = max(1, round(n * train_ratio))
        n_val = max(1, round(n * val_ratio)) if n - n_train >= 2 else 0
        train_ids.update(ids[:n_train])
        val_ids.update(ids[n_train:n_train + n_val])
        test_ids.update(ids[n_train + n_val:])

    def assign(cid):
        if cid in train_ids:
            return "train"
        if cid in val_ids:
            return "val"
        return "test"

    df = df.copy()
    df["split"] = df["id"].map(assign)
    return df


manifest_df = child_stratified_split(manifest_df, seed=SEED)

# ---- Report + hard assertion ----------------------------------------------
print("=== Speaker-independent split ===")
for split in ["train", "val", "test"]:
    sub = manifest_df[manifest_df["split"] == split]
    n_children = sub["id"].nunique()
    n_n = (sub["diagnosis"] == "N").sum()
    n_ab = (sub["diagnosis"] == "AB").sum()
    print(f"  {split:5s}: {len(sub):5d} clips | {n_children:3d} children | N={n_n}, AB={n_ab}")

# Coverage warning: a per-child split cannot guarantee all 84 words per split.
for split in ["val", "test"]:
    covered = manifest_df[manifest_df["split"] == split]["target"].nunique()
    print(f"  {split} covers {covered}/{len(word_to_phonemes)} lexicon words")

overlap = (
    set(manifest_df[manifest_df.split == "train"]["id"])
    & set(manifest_df[manifest_df.split == "test"]["id"])
)
assert not overlap, f"Speaker leakage into test: {overlap}"
print("\nNo child appears in both train and test.")
