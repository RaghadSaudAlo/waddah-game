# colab/03_SAVE_EVERYTHING.py
# ============================================================================
#  RUN THIS THE MOMENT TRAINING FINISHES. THIS IS THE MOST URGENT CELL.
# ============================================================================
# Your notebook says "Nothing is saved to disk" and writes checkpoints to
# /tmp/waddah-v3-checkpoints. /tmp is wiped when the Colab runtime recycles,
# which happens on idle timeout, on disconnect, and whenever Colab feels like
# it. An A100 training run that is not persisted is a training run you will
# do again.
#
# Paste this directly after cell 5C.

import hashlib
import json
import os
import shutil

# --- PRELUDE -------------------------------------------------------------
# The original version of this script opened with `from waddah_core import
# save_vocab_bundle` and referenced LEXICON_SHA. Neither exists in the Colab
# runtime: waddah_core lives in the repo (api/waddah_core/), not on Drive, and
# the notebook defines LEXICON_PATH but never hashes it. Both would raise
# NameError *after* the A100 run finished — the worst possible moment.
# Inlined here so this cell is self-contained and cannot fail on an import.

LEXICON_SHA = hashlib.sha256(open(LEXICON_PATH, "rb").read()).hexdigest()
print("Lexicon SHA256:", LEXICON_SHA)
# Must read e4c830ce5d666249a8435f42f68714266e6ca4702e0850037ac42d13f270cc13
# for the 84-word lexicon currently in the repo. A different value means the
# CSV on Drive is not the one in shared/ — stop and reconcile before saving.

def save_vocab_bundle(path, vocab_dict, lexicon_sha):
    """Byte-identical to api/waddah_core/vocab.py:save_vocab_bundle."""
    with open(path, "w", encoding="utf-8") as f:
        json.dump(
            {"vocab": vocab_dict, "lexicon_sha256": lexicon_sha, "format_version": 2},
            f,
            ensure_ascii=False,
            indent=2,
        )
# -------------------------------------------------------------------------

SAVE_DIR = "/content/drive/MyDrive/Segmented-Audios/waddah_ctc_v3"
os.makedirs(SAVE_DIR, exist_ok=True)

# 1. Model weights + config (Trainer already restored the best checkpoint
#    because load_best_model_at_end=True).
trainer.save_model(SAVE_DIR)

# 2. Processor = feature extractor + tokenizer + vocab.json.
#    Without this the checkpoint's 38 output indices are meaningless.
processor.save_pretrained(SAVE_DIR)

# 3. The vocabulary and the lexicon fingerprint. The API refuses to start if
#    the lexicon changed since this moment, because every CTC output index is
#    derived from it.
save_vocab_bundle(
    os.path.join(SAVE_DIR, "waddah_vocab_bundle.json"),
    vocab_dict=vocab_dict,
    lexicon_sha=LEXICON_SHA,
)

# 4. The lexicon itself, pinned alongside the weights.
shutil.copy(LEXICON_PATH, os.path.join(SAVE_DIR, "arabic_phoneme_lexicon.csv"))

# 5. Training provenance — a permanent record of how this model was produced.
#
# Measure speaker leakage rather than asserting a split strategy. A child whose
# recordings appear in BOTH train and test inflates every headline metric,
# because the model has already heard that voice. Counting it here means the
# provenance card states what actually happened, whatever you ran.
_train_ids = set(manifest_df.loc[manifest_df.split == "train", "id"])
_test_ids = set(manifest_df.loc[manifest_df.split == "test", "id"])
_leaked = _train_ids & _test_ids
N_LEAKED = len(_leaked)
SPLIT_LABEL = (
    "child-stratified 80/10/10 (no speaker overlap)"
    if N_LEAKED == 0
    else f"word-stratified 80/10/10 — SPEAKER LEAKAGE: {N_LEAKED} children in both train and test"
)
print(f"Split: {SPLIT_LABEL}")
if N_LEAKED:
    print(
        f"  WARNING: {N_LEAKED} of {len(_train_ids | _test_ids)} children appear in "
        f"train AND test. Metrics from this run are optimistic. Apply "
        f"02_child_stratified_split.py and retrain for the honest number."
    )

json.dump(
    {
        "base_model": "omarxadel/hubert-large-arabic-egyptian",
        "vocab_size": len(vocab_dict),
        "sample_rate": 16000,
        "max_audio_seconds": 5,
        "seed": SEED,
        "epochs_configured": training_args.num_train_epochs,
        "effective_batch_size": (
            training_args.per_device_train_batch_size
            * training_args.gradient_accumulation_steps
        ),
        "learning_rate": training_args.learning_rate,
        "warmup_ratio": training_args.warmup_ratio,
        "weight_decay": training_args.weight_decay,
        # MEASURED, not asserted. The original script hardcoded
        # "child-stratified 80/10/10", which would have written a false claim
        # into the provenance card if 02_child_stratified_split.py had
        # not been applied yet. This counts children appearing in both train
        # and test and labels the split by what actually happened.
        "split": SPLIT_LABEL,
        "speaker_leakage_n_children_in_train_and_test": N_LEAKED,
        "n_train": int((manifest_df.split == "train").sum()),
        "n_val": int((manifest_df.split == "val").sum()),
        "n_test": int((manifest_df.split == "test").sum()),
        "best_val_per": float(val_result["eval_per"]),
        "final_train_loss": float(train_result.training_loss),
        "lexicon_sha256": LEXICON_SHA,
    },
    open(os.path.join(SAVE_DIR, "training_card.json"), "w"),
    indent=2,
    ensure_ascii=False,
)

# 6. The manifest — reproducibility of the exact split.
#    NOTE: filepath and filename columns contain child IDs. This CSV stays in
#    the RBAC-controlled Drive folder and is NEVER committed to git (PDPL).
manifest_df.to_csv(os.path.join(SAVE_DIR, "manifest_with_splits.csv"), index=False)

print("Saved to:", SAVE_DIR)
for f in sorted(os.listdir(SAVE_DIR)):
    size_mb = os.path.getsize(os.path.join(SAVE_DIR, f)) / 1e6
    print(f"  {f:<40} {size_mb:>8.1f} MB")


# ---------------------------------------------------------------------------
# 7. Push weights to a PRIVATE Hugging Face model repo so the Space can pull
#    them. Drive cannot be read from a container without OAuth gymnastics.
# ---------------------------------------------------------------------------
# !pip install -q huggingface_hub==0.25.2
# from huggingface_hub import login, create_repo, upload_folder
# login()  # paste a WRITE token from hf.co/settings/tokens
#
# REPO_ID = "<your-hf-username>/waddah-ctc-v3"
# create_repo(REPO_ID, repo_type="model", private=True, exist_ok=True)
# upload_folder(
#     repo_id=REPO_ID,
#     folder_path=SAVE_DIR,
#     ignore_patterns=["manifest_with_splits.csv"],  # PDPL: no child IDs off-Drive
# )
# print(f"Pushed to https://huggingface.co/{REPO_ID}")
