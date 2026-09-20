#!/usr/bin/env python3
"""Pre-bake every Arabic line the app speaks into app/assets/audio/.

WHY THIS EXISTS
---------------
Every line the app speaks is generated once, here, and shipped as a Flutter
asset. The app therefore needs no TTS service at runtime: it makes no network
calls, holds no API credentials, and works offline.

WHY A MANIFEST KEYED ON THE EXACT TEXT
--------------------------------------
Filenames are sha1(text)[:16].mp3 -- content-addressed, so re-running this
script overwrites rather than duplicates, and changed text always means a new
filename. audio_manifest.json maps the exact Dart string to its file.

Keying on the exact string is what lets the Dart call sites stay unchanged:
playText('...') simply looks up '...'. It also means whitespace matters, which
is why tools/check_audio_coverage.py exists.

USAGE
-----
    # put the key in a gitignored file first
    #   D:\\waddah\\services\\therapy-api\\.env
    #     ELEVENLABS_API_KEY=...
    #     ELEVENLABS_VOICE_ID=...
    python tools/generate_audio.py            # generate missing only
    python tools/generate_audio.py --force    # regenerate everything
    python tools/generate_audio.py --dry-run  # list texts, call nothing
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LEXICON = REPO / "shared" / "arabic_phoneme_lexicon.csv"
OUT_DIR = REPO / "app" / "assets" / "audio"
MANIFEST = OUT_DIR / "audio_manifest.json"
ENV_FILE = REPO / "services" / "therapy-api" / ".env"

ELEVEN_URL = "https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
MODEL_ID = "eleven_multilingual_v2"
# Same voice settings as services/therapy-api/app/tts_service.py, so the baked
# audio sounds identical to what the live service produced.
VOICE_SETTINGS = {"stability": 0.6, "similarity_boost": 0.75, "speed": 0.9}


def normalize_arabic(text: str) -> str:
    """Verbatim from api/waddah_core/arabic.py. Duplicated deliberately: this
    script must run with no repo imports and no third-party deps but requests."""
    text = re.sub(r"[\u064B-\u0652\u0670]", "", text)
    text = text.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا")
    text = text.replace("ى", "ي")
    return text.strip()


def load_words() -> list[str]:
    """The 84 words, read from the lexicon so there is one source of truth.

    Uses utf-8-sig: the CSV carries a BOM. pandas strips it silently, the
    stdlib csv module does not -- with plain utf-8 the first column comes back
    as '\\ufeffword' and the lookup fails.
    """
    import csv

    with open(LEXICON, encoding="utf-8-sig", newline="") as f:
        return [row["word"].strip() for row in csv.DictReader(f) if row.get("word", "").strip()]


def build_texts() -> dict[str, str]:
    """Every string the app passes to playText(), mapped to a short label.

    The KEY is the exact Dart string, byte for byte, including the '\\n' in the
    hand-written animal prompts. If you change a prompt in Dart you must change
    it here too, or that line falls back to silence.
    """
    texts: dict[str, str] = {}

    # 1. Hand-written prompts on the four built screens. Copied exactly from
    #    lib/screens/{lion,elephant,sun,book}_screen.dart.
    for label, s in {
        "prompt_lion": "هذا صديقي الأسد \nهل تستطيع أن تقول: أسد؟",
        "prompt_elephant": "هذا صديقي الفيل \nهل تستطيع أن تقول: فيل؟",
        "prompt_sun": "هذه صديقتي الشمس \nهل تستطيع أن تقول: شمس؟",
        "prompt_book": "هذا صديقي الكتاب \nهل تستطيع أن تقول: كتاب؟",
    }.items():
        texts[s] = label

    # 2. Fixed UI lines.
    #    The home greeting is name-less by design: the original embedded the
    #    child's name, which cannot be pre-baked. The name still appears on
    #    screen, it is just not spoken.
    texts["أهلًا يا صديقي، أنا صديقك وَضّاح، هؤلاء أصدقائي، هيا بنا نتعرف عليهم"] = "ui_home_greeting"
    texts["أي صديق تريد أن نتدرّب معه أولًا؟"] = "ui_therapy_intro"

    # Every line therapy_screen.dart speaks. Verified against the
    # _playFeedback / playText call sites — miss one and it plays silently.
    for i, s in enumerate(
        [
            "لنبدأ التدريب، استمع جيدًا",
            "أحسنت، محاولة جميلة",
            "ممتاز، ننتقل للخطوة التالية",
            "أحسنت جدًا، أنهيت تدريب اليوم",
        ],
        start=1,
    ):
        texts[s] = f"ui_therapy_{i}"

    # 'مرحلة جديدة، $currentStageTitle' interpolates the stage title, so the
    # titles must be a CLOSED set and every combination baked. These must stay
    # identical to kTherapyStageTitles in app/lib/services/therapy_service.dart.
    for i, title in enumerate(["كلمات قصيرة", "كلمات أطول", "تدريب أخير"], start=1):
        texts[f"مرحلة جديدة، {title}"] = f"ui_stage_{i}"

    # 3. Canned praise, replacing GPT-4 feedback in the mock build.
    for i, s in enumerate(
        [
            "أحسنت! نطق ممتاز",
            "محاولة جميلة، هيا نجرب مرة أخرى",
            "رائع! أنت تتحسن",
            "لا بأس، جرب مرة أخرى معي",
        ],
        start=1,
    ):
        texts[s] = f"ui_praise_{i}"

    # 4. Per-word: the bare word, and the select_character_screen template
    #    "هذا $word، قل: $word".
    for w in load_words():
        texts[w] = f"word_{normalize_arabic(w)}"
        texts[f"هذا {w}، قل: {w}"] = f"prompt_{normalize_arabic(w)}"

    return texts


def filename_for(text: str) -> str:
    """Deterministic and collision-free. Re-running overwrites, never duplicates."""
    return hashlib.sha1(text.encode("utf-8")).hexdigest()[:16] + ".mp3"


def speech_text(text: str) -> str:
    """What we actually send to the API: newlines are layout, not speech."""
    return " ".join(text.split())


def read_env() -> tuple[str, str]:
    key = os.getenv("ELEVENLABS_API_KEY", "").strip()
    voice = os.getenv("ELEVENLABS_VOICE_ID", "").strip()
    if (not key or not voice) and ENV_FILE.exists():
        for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, _, v = line.partition("=")
            k, v = k.strip(), v.strip().strip('"').strip("'")
            if k == "ELEVENLABS_API_KEY" and not key:
                key = v
            elif k == "ELEVENLABS_VOICE_ID" and not voice:
                voice = v
    if not key or not voice:
        sys.exit(
            f"ELEVENLABS_API_KEY / ELEVENLABS_VOICE_ID not found.\n"
            f"Set them as environment variables, or put them in {ENV_FILE}\n"
            f"(that path is gitignored)."
        )
    return key, voice


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true", help="regenerate files that already exist")
    ap.add_argument("--dry-run", action="store_true", help="list texts, make no API calls")
    args = ap.parse_args()

    texts = build_texts()
    total_chars = sum(len(speech_text(t)) for t in texts)
    print(f"{len(texts)} distinct lines, {total_chars} characters of TTS")

    if args.dry_run:
        for t, label in sorted(texts.items(), key=lambda kv: kv[1]):
            print(f"  {label:<28} {filename_for(t)}  {speech_text(t)[:60]}")
        print("\n--dry-run: nothing generated, no API call made.")
        return 0

    import requests  # imported late so --dry-run works without it

    api_key, voice_id = read_env()
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    manifest: dict[str, str] = {}
    made = skipped = 0

    for i, (text, label) in enumerate(sorted(texts.items(), key=lambda kv: kv[1]), start=1):
        fname = filename_for(text)
        manifest[text] = fname
        dest = OUT_DIR / fname

        if dest.exists() and not args.force:
            skipped += 1
            continue

        resp = requests.post(
            ELEVEN_URL.format(voice_id=voice_id),
            headers={
                "xi-api-key": api_key,
                "Content-Type": "application/json",
                "Accept": "audio/mpeg",
            },
            json={
                "text": speech_text(text),
                "model_id": MODEL_ID,
                "voice_settings": VOICE_SETTINGS,
            },
            timeout=60,
        )
        if resp.status_code != 200:
            # Never print the response body unfiltered: on a 401 ElevenLabs
            # echoes request context back.
            print(f"\nFAILED {label}: HTTP {resp.status_code}", file=sys.stderr)
            return 1

        dest.write_bytes(resp.content)
        made += 1
        print(f"  [{i}/{len(texts)}] {label:<28} {len(resp.content)/1024:6.1f} KB")
        time.sleep(0.25)  # be polite to the API

    MANIFEST.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True), encoding="utf-8"
    )

    size_mb = sum(f.stat().st_size for f in OUT_DIR.glob("*.mp3")) / 1e6
    print(f"\ngenerated {made}, reused {skipped}")
    print(f"{len(manifest)} entries -> {MANIFEST.relative_to(REPO)}")
    print(f"total audio: {size_mb:.1f} MB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
