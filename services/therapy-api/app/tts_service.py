import os
import uuid
from pathlib import Path
from typing import Optional

import requests


BASE_DIR = Path(__file__).resolve().parent.parent
GENERATED_AUDIO_DIR = BASE_DIR / "generated_audio"
GENERATED_AUDIO_DIR.mkdir(exist_ok=True)


def get_elevenlabs_config() -> tuple[str, str]:
    api_key = os.getenv("ELEVENLABS_API_KEY", "").strip()
    voice_id = os.getenv("ELEVENLABS_VOICE_ID", "").strip()

    if not api_key:
        raise ValueError("ELEVENLABS_API_KEY is not set in environment variables")

    if not voice_id:
        raise ValueError("ELEVENLABS_VOICE_ID is not set in environment variables")

    return api_key, voice_id


def generate_tts_audio(
    text: str,
    output_filename: Optional[str] = None
) -> str:
    """
    Sends text to ElevenLabs, saves the generated audio inside generated_audio,
    and returns the generated filename.
    """

    api_key, voice_id = get_elevenlabs_config()

    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"

    headers = {
        "xi-api-key": api_key,
        "Content-Type": "application/json",
        "Accept": "audio/mpeg"
    }

    payload = {
        "text": text,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {
            "stability": 0.6,
            "similarity_boost": 0.75,
            "speed": 0.9
        }
    }

    response = requests.post(url, headers=headers, json=payload, timeout=60)
    response.raise_for_status()

    if output_filename is None:
        output_filename = f"waddah_{uuid.uuid4().hex}.mp3"

    output_path = GENERATED_AUDIO_DIR / output_filename

    with open(output_path, "wb") as f:
        f.write(response.content)

    return output_filename