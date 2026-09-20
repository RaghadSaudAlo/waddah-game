# waddah_core/infer.py
# Purpose: load the fine-tuned HubertForCTC checkpoint once and run the full
# Waddah diagnosis pipeline on a single WAV file.
#
# This mirrors notebook Phase 7 (`infer`) exactly, with the glyph fix from
# vocab.py applied and the model kept resident instead of re-created per call.

import os
import time

import numpy as np
import torch
import torchaudio
from transformers import HubertForCTC, Wav2Vec2Processor

from .align import diagnose_at_target, levenshtein_align
from .arabic import normalize_arabic
from .lexicon import lexicon_hash, load_lexicon
from .vocab import ctc_decode_ids

SAMPLE_RATE = 16_000
MAX_AUDIO_SECONDS = 5           # must match MAX_AUDIO_LENGTH in the notebook
MAX_SAMPLES = MAX_AUDIO_SECONDS * SAMPLE_RATE


class WaddahCTC:
    """Resident inference engine. Construct once at API startup."""

    def __init__(self, model_dir: str, lexicon_path: str, vocab_bundle: dict, device: str = "cpu"):
        self.device = torch.device(device)
        self.processor = Wav2Vec2Processor.from_pretrained(model_dir)
        self.model = HubertForCTC.from_pretrained(model_dir).to(self.device).eval()

        # Why dynamic int8 on CPU: HuBERT-Large is ~315M params. Quantizing the
        # Linear layers roughly halves latency and memory on CPU with a small
        # accuracy cost. Skipped on GPU, where it would slow things down.
        if self.device.type == "cpu" and os.getenv("WADDAH_QUANTIZE", "1") == "1":
            self.model = torch.quantization.quantize_dynamic(
                self.model, {torch.nn.Linear}, dtype=torch.qint8
            )

        self.lexicon, _ = load_lexicon(lexicon_path)
        self.id2ph = {int(k): v for k, v in vocab_bundle["id2ph"].items()}
        self.blank_id = int(vocab_bundle["vocab"]["<pad>"])

        # Refuse to serve if the lexicon drifted from the one used in training.
        expected = vocab_bundle.get("lexicon_sha256")
        actual = lexicon_hash(lexicon_path)
        if expected and expected != actual:
            raise RuntimeError(
                "Lexicon SHA mismatch. The CSV changed since training, so CTC "
                f"output indices are no longer valid.\n  trained: {expected}\n  loaded:  {actual}"
            )

    # -- audio -------------------------------------------------------------

    def _load_audio(self, path: str) -> np.ndarray:
        waveform, sr = torchaudio.load(path)
        if sr != SAMPLE_RATE:
            waveform = torchaudio.transforms.Resample(sr, SAMPLE_RATE)(waveform)
        if waveform.shape[0] > 1:
            waveform = waveform.mean(dim=0, keepdim=True)
        if waveform.shape[1] > MAX_SAMPLES:
            waveform = waveform[:, :MAX_SAMPLES]
        return waveform.squeeze().numpy()

    # -- prediction --------------------------------------------------------

    def predict(self, audio_path: str, target_word: str) -> dict:
        t0 = time.perf_counter()

        norm_word = normalize_arabic(target_word)
        if norm_word not in self.lexicon:
            raise KeyError(f"'{target_word}' is not one of the 84 lexicon words.")

        entry = self.lexicon[norm_word]
        canonical = entry["phoneme_sequence"]

        audio = self._load_audio(audio_path)
        inputs = self.processor(audio, sampling_rate=SAMPLE_RATE, return_tensors="pt")
        inputs = {k: v.to(self.device) for k, v in inputs.items()}

        with torch.no_grad():
            logits = self.model(**inputs).logits          # (1, T, V)

        pred_ids = logits.argmax(-1)[0]
        # Decode ids -> phonemes directly. Never tokenizer.decode().split():
        # that fuses multi-character phonemes. See vocab.py for the evidence.
        predicted = ctc_decode_ids(pred_ids.tolist(), self.id2ph, self.blank_id)

        # Confidence: mean max-softmax over frames the model did NOT label blank.
        # Used by the Phase 4 mastery rule (confidence < 0.60 -> no score update).
        probs = torch.softmax(logits[0].float(), dim=-1)
        conf_per_frame, _ = probs.max(dim=-1)
        non_blank = pred_ids != self.model.config.pad_token_id
        confidence = float(conf_per_frame[non_blank].mean()) if non_blank.any() else 0.0

        subs, dels, ins, ops = levenshtein_align(canonical, predicted)
        per = (subs + dels + ins) / len(canonical) if canonical else 0.0

        has_error = any(o[0] != "correct" for o in ops)
        target_op = diagnose_at_target(predicted, canonical, entry["target_phoneme_idx"])
        target_is_error = target_op in ("substitution", "deletion", "insertion")

        return {
            "target_word": norm_word,
            "target_phoneme": entry["target_phoneme"],
            "phoneme_position": entry["phoneme_position"],
            "canonical": canonical,
            "predicted": predicted,
            "per": round(per, 4),
            "subs": subs, "dels": dels, "ins": ins,
            # Whole-word verdict, as in notebook 6B.
            "detection": "abnormal" if has_error else "normal",
            # Target-phoneme verdict — this is what the game should act on
            # (Hard Constraint 4: per-word evaluation focuses on the target only).
            "target_detection": "abnormal" if target_is_error else "normal",
            "diagnosis": target_op,
            "confidence": round(confidence, 4),
            "latency_ms": round((time.perf_counter() - t0) * 1000, 1),
        }
