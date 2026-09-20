#!/usr/bin/env python3
"""Fail if any line the app speaks has no pre-baked clip.

WHY THIS EXISTS
The deployed build has no TTS service — it can only speak text that
`generate_audio.py` baked into `app/assets/audio/`. The manifest is keyed on
the EXACT Dart string, so a one-character edit to a prompt silently turns that
line into nothing at all. Nothing crashes, nothing logs at the user, the child
just gets silence. That is exactly the class of bug nobody notices until a
demo.

This walks the Dart source for every string literal handed to a speech call and
checks it against the manifest.

    python tools/check_audio_coverage.py     # exit 1 if a line would be silent
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LIB = REPO / "app" / "lib"
MANIFEST = REPO / "app" / "assets" / "audio" / "audio_manifest.json"
AUDIO_DIR = MANIFEST.parent

# Two ways a line reaches the speaker:
#   1. handed straight to playText('...') / _playFeedback('...')
#   2. passed as AnimalPromptScreen(fullPromptText: '...', wordOnlyText: '...'),
#      which the screen later speaks via widget.fullPromptText. These are the
#      main child-facing prompts, so missing them would defeat the point.
CALL = re.compile(
    r"""(?:playText|_playFeedback|fullPromptText\s*:|wordOnlyText\s*:)\s*\(?\s*(['"])(?P<text>(?:\\.|(?!\1).)*)\1""",
    re.DOTALL,
)


BLOCK_COMMENT = re.compile(r"/\*.*?\*/", re.DOTALL)
LINE_COMMENT = re.compile(r"^[ \t]*///?.*$", re.MULTILINE)

def _lexicon_words() -> list[str]:
    """The 84 words, from the lexicon — the same source generate_audio.py uses."""
    import csv

    # utf-8-sig: the CSV has a BOM, which the stdlib csv module does not strip.
    with open(
        REPO / "shared" / "arabic_phoneme_lexicon.csv", encoding="utf-8-sig", newline=""
    ) as f:
        return [r["word"].strip() for r in csv.DictReader(f) if r.get("word", "").strip()]


def known_interpolations() -> dict[str, list[str]]:
    """Interpolated lines whose value set is CLOSED, with every variant listed.

    An interpolated string can only be spoken if every value it can take was
    baked. That is acceptable when the set is finite and known; it is a bug
    when it is open-ended (a child's name, GPT-4 output). Keep in sync with
    tools/generate_audio.py.
    """
    return {
        "مرحلة جديدة، $currentStageTitle": [
            "مرحلة جديدة، كلمات قصيرة",
            "مرحلة جديدة، كلمات أطول",
            "مرحلة جديدة، تدريب أخير",
        ],
        # select_character_screen can route to ANY lexicon word, so all 84
        # variants are baked. Derived from the lexicon so the two cannot drift.
        "هذا $word، قل: $word": [f"هذا {w}، قل: {w}" for w in _lexicon_words()],
    }


KNOWN_INTERPOLATIONS = known_interpolations()


def strip_comments(src: str) -> str:
    """Blank out comments, preserving newlines so line numbers stay correct.

    Without this, the doc comments that explain this very mechanism (they
    contain `playText('...')`) get scanned as if they were real call sites.
    """
    src = BLOCK_COMMENT.sub(lambda m: "\n" * m.group(0).count("\n"), src)
    return LINE_COMMENT.sub("", src)


def unescape_dart(s: str) -> str:
    return s.replace(r"\n", "\n").replace(r"\'", "'").replace(r"\"", '"').replace(r"\\", "\\")


def main() -> int:
    if not MANIFEST.exists():
        print(f"No manifest at {MANIFEST}. Run tools/generate_audio.py first.")
        return 1

    manifest: dict[str, str] = json.loads(MANIFEST.read_text(encoding="utf-8"))

    missing: list[tuple[str, str]] = []
    dynamic: list[tuple[str, str]] = []
    ok = 0

    for path in sorted(LIB.rglob("*.dart")):
        src = strip_comments(path.read_text(encoding="utf-8"))
        for m in CALL.finditer(src):
            raw = m.group("text")
            where = f"{path.relative_to(REPO)}:{src[: m.start()].count(chr(10)) + 1}"

            # '$name' / '${expr}' cannot be pre-baked: the value is only known
            # at runtime. Report separately — these need a closed set of
            # variants baked, or the interpolation removed.
            if "$" in raw:
                dynamic.append((where, raw))
                continue

            text = unescape_dart(raw)
            if text in manifest:
                ok += 1
            else:
                missing.append((where, text))

    # Also confirm every manifest entry actually has its mp3 on disk.
    orphan_entries = [t for t, f in manifest.items() if not (AUDIO_DIR / f).exists()]

    print(f"spoken literals resolved : {ok}")
    print(f"manifest entries         : {len(manifest)}")

    # An interpolated line is acceptable only when its variants form a closed
    # set AND every variant is baked. Anything else is an unresolved risk.
    unhandled_dynamic: list[tuple[str, str]] = []
    for where, raw in dynamic:
        variants = KNOWN_INTERPOLATIONS.get(raw)
        if variants is None:
            unhandled_dynamic.append((where, raw))
            continue
        gaps = [v for v in variants if v not in manifest]
        if gaps:
            missing.extend((where, v) for v in gaps)
        else:
            ok += len(variants)
            print(f"interpolated, all {len(variants)} variants baked: {raw}")

    if unhandled_dynamic:
        print(f"\nUNHANDLED INTERPOLATION ({len(unhandled_dynamic)}) — will be silent:")
        for where, raw in unhandled_dynamic:
            print(f"  {where}\n      {raw}")
            print("      Fix: make the values a closed set, bake each variant,")
            print("      and list it in KNOWN_INTERPOLATIONS.")

    if missing:
        print(f"\nSILENT ({len(missing)}) — spoken in Dart, not in the manifest:")
        for where, text in missing:
            print(f"  {where}\n      {text!r}")

    if orphan_entries:
        print(f"\nMANIFEST ENTRIES WITH NO FILE ({len(orphan_entries)}):")
        for t in orphan_entries:
            print(f"      {t!r}")

    if missing or orphan_entries or unhandled_dynamic:
        print("\nFAIL")
        return 1

    print("\nOK — every non-interpolated spoken line has a clip.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
