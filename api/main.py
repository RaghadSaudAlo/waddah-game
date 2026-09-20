# api/main.py
# Purpose: the single HTTP surface the Flutter game talks to.
# Run locally:  uvicorn main:app --reload --port 8000
# In Docker/HF Spaces it is started on port 7860 by the Dockerfile CMD.

import os
import tempfile

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from huggingface_hub import snapshot_download

from schemas import DiagnoseResponse, HealthResponse
from waddah_core import load_vocab_bundle
from waddah_core.infer import WaddahCTC

# --- configuration (set these as Space secrets / .env) ---------------------
MODEL_REPO = os.environ.get("WADDAH_MODEL_REPO", "")   # e.g. "pnu-waddah/waddah-ctc-v3"
HF_TOKEN = os.environ.get("HF_TOKEN")                  # read token, private repo
ALLOWED_ORIGINS = os.environ.get(
    "WADDAH_ALLOWED_ORIGINS",
    "http://localhost:*,https://*.web.app,https://*.firebaseapp.com",
).split(",")

app = FastAPI(title="Waddah MDD API", version="0.3.0")

# Why CORS matters: Flutter Web runs on a different origin than this API, so the
# browser blocks the request unless the server opts in. Tighten this to your
# exact Firebase domain before any session with real children.
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https://.*\.(web\.app|firebaseapp\.com)|http://localhost(:\d+)?",
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

engine: WaddahCTC | None = None


@app.on_event("startup")
def load_model() -> None:
    """Download the checkpoint once and keep the model resident.

    Loading inside the request handler would add ~20s to every call.
    """
    global engine
    local_dir = snapshot_download(repo_id=MODEL_REPO, token=HF_TOKEN)
    bundle = load_vocab_bundle(os.path.join(local_dir, "waddah_vocab_bundle.json"))
    engine = WaddahCTC(
        model_dir=local_dir,
        lexicon_path=os.path.join(local_dir, "arabic_phoneme_lexicon.csv"),
        vocab_bundle=bundle,
        device="cuda" if os.environ.get("WADDAH_DEVICE") == "cuda" else "cpu",
    )


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    if engine is None:
        raise HTTPException(503, "Model still loading")
    return HealthResponse(
        status="ok",
        model_id=MODEL_REPO,
        lexicon_words=len(engine.lexicon),
        device=str(engine.device),
        quantized=os.getenv("WADDAH_QUANTIZE", "1") == "1",
    )


@app.get("/words")
def words() -> dict:
    """The 84 lexicon words, so the Flutter app never hardcodes them."""
    if engine is None:
        raise HTTPException(503, "Model still loading")
    return {
        "count": len(engine.lexicon),
        "words": [
            {
                "word": w,
                "target_phoneme": e["target_phoneme"],
                "position": e["phoneme_position"],
            }
            for w, e in engine.lexicon.items()
        ],
    }


@app.post("/diagnose", response_model=DiagnoseResponse)
async def diagnose(
    audio: UploadFile = File(..., description="16kHz mono WAV, <= 5 seconds"),
    target_word: str = Form(..., description="Arabic word the child was prompted with"),
) -> DiagnoseResponse:
    if engine is None:
        raise HTTPException(503, "Model still loading")

    raw = await audio.read()
    if len(raw) > 5 * 1024 * 1024:
        raise HTTPException(413, "Audio too large; expected <= 5s of 16kHz mono WAV")

    # PDPL: audio exists only inside this context manager. The file is unlinked
    # on exit and nothing is written to durable storage. Log this as an
    # extension row to Phase 1 Table 3.7 (transient processing, zero retention).
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=True) as tmp:
        tmp.write(raw)
        tmp.flush()
        try:
            result = engine.predict(tmp.name, target_word=target_word)
        except KeyError as exc:
            raise HTTPException(422, str(exc)) from exc

    return DiagnoseResponse(**result)
