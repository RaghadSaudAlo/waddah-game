from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi import FastAPI, UploadFile, File, Form
from pathlib import Path
from fastapi import UploadFile, File, Form

import uuid
from pathlib import Path

from app.schemas import (
    DiagnosisInput,
    TherapyResponse,
    DiagnosisMockRequest,
    DiagnosisMockResponse,
    UploadedDiagnosisResponse,
)
from app.therapy_engine import run_therapy
from app.tts_service import generate_tts_audio

from app.therapy_plan_service import build_therapy_targets, build_therapy_session
from app.schemas import (
    TherapyPlanRequest,
    TherapyPlanResponse,
    TherapySessionRequest,
    TherapySessionResponse,
)


BASE_DIR = Path(__file__).resolve().parent.parent
GENERATED_AUDIO_DIR = BASE_DIR / "generated_audio"

UPLOADED_RECORDINGS_DIR = BASE_DIR / "uploaded_recordings"
UPLOADED_RECORDINGS_DIR.mkdir(parents=True, exist_ok=True)

app = FastAPI(
    title="Waddah Therapy Backend",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount(
    "/generated_audio",
    StaticFiles(directory=GENERATED_AUDIO_DIR),
    name="generated_audio"
)


@app.get("/")
def health_check():
    return {
        "status": "ok",
        "message": "Waddah Therapy Backend is running"
    }


@app.post("/therapy", response_model=TherapyResponse)
def generate_therapy(diagnosis_input: DiagnosisInput):
    therapy_output = run_therapy(diagnosis_input.model_dump())

    return TherapyResponse(
        success=True,
        diagnosis_input=diagnosis_input,
        therapy_output=therapy_output
    )


@app.post("/therapy-with-audio", response_model=TherapyResponse)
def generate_therapy_with_audio(diagnosis_input: DiagnosisInput):
    therapy_output = run_therapy(diagnosis_input.model_dump())

    output_filename = generate_tts_audio(
        text=therapy_output.tts_text
    )

    therapy_output.audio_url = f"http://127.0.0.1:8002/generated_audio/{output_filename}"

    return TherapyResponse(
        success=True,
        diagnosis_input=diagnosis_input,
        therapy_output=therapy_output
    )

@app.post("/diagnosis-prompt-audio")
def generate_prompt_audio(data: dict):
    text = data.get("text", "هذا صديقي الأسد، قل: أسد")

    output_filename = generate_tts_audio(text)

    return {
    "audio_url": f"http://127.0.0.1:8002/generated_audio/{output_filename}"
}

@app.post("/diagnosis-mock", response_model=DiagnosisMockResponse)
def diagnosis_mock(data: DiagnosisMockRequest):
    # مؤقتًا نخلي النتيجة بسيطة
    # لاحقًا هنا يجي diagnosis model الحقيقي

    word = data.word.strip()

    correct_words = {"أسد", "فيل", "شمس", "كتاب"}

    is_correct = word in correct_words

    if is_correct:
        message = "أحسنت!"
    else:
        message = "محاولة جميلة"

    return DiagnosisMockResponse(
        success=True,
        word=data.word,
        target_phoneme=data.target_phoneme,
        position=data.position,
        is_correct=is_correct,
        message=message,
    )

@app.post("/diagnosis-upload")
async def diagnosis_upload(
    word: str = Form(...),
    target_phoneme: str = Form(...),
    position: str = Form(...),
    audio_file: UploadFile = File(...),
):
    upload_dir = Path("uploaded_recordings")
    upload_dir.mkdir(exist_ok=True)

    file_path = upload_dir / audio_file.filename

    with open(file_path, "wb") as f:
        f.write(await audio_file.read())

    # Mock مؤقت: بعض الكلمات نعتبرها غلط عشان نختبر الثيرابي
    wrong_words = ["أسد", "فيل"]

    is_correct = word not in wrong_words

    produced_phoneme = target_phoneme if is_correct else "غير صحيح"

    return {
        "success": True,
        "word": word,
        "target_phoneme": target_phoneme,
        "position": position,
        "produced_phoneme": produced_phoneme,
        "audio_filename": audio_file.filename,
        "audio_saved_path": str(file_path),
        "is_correct": is_correct,
        "message": "Correct pronunciation" if is_correct else "Needs therapy"
    }

@app.post("/therapy-targets", response_model=TherapyPlanResponse)
def get_therapy_targets(request: TherapyPlanRequest):
    targets = build_therapy_targets(
        age=request.age,
        diagnosis_results=[item.model_dump() for item in request.diagnosis_results],
    )
    return TherapyPlanResponse(therapy_targets=targets)


@app.post("/therapy-session-plan", response_model=TherapySessionResponse)
def get_therapy_session_plan(request: TherapySessionRequest):
    session = build_therapy_session(
        selected_word=request.selected_word,
        target_phoneme=request.target_phoneme,
        position=request.position,
    )

    return TherapySessionResponse(**session)