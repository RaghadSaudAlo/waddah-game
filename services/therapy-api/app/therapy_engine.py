import json
from pathlib import Path
from typing import Any, Dict

from app.age_rules import get_age_status
from app.word_bank import get_words_for_stage
from app.schemas import DiagnosisInput, TherapyOutput, TherapyWords, FeedbackOutput
from app.llm_service import generate_feedback_with_llm


DATA_DIR = Path(__file__).resolve().parent.parent / "data"
PROGRESSION_PATH = DATA_DIR / "therapy_progression.json"


def load_progression() -> dict:
    with open(PROGRESSION_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def get_default_stage(age_status: str) -> str:
    if age_status == "age_appropriate":
        return "isolation"
    return "one_syllable"


def split_words_by_position(words: list[str], stage: str) -> TherapyWords:
    if stage in ["one_syllable", "two_syllables", "phrase", "sentence", "isolation"]:
        return TherapyWords(
            initial=words,
            medial=[],
            final=[]
        )

    if stage == "word_initial":
        return TherapyWords(initial=words, medial=[], final=[])

    if stage == "word_medial":
        return TherapyWords(initial=[], medial=words, final=[])

    if stage == "word_final":
        return TherapyWords(initial=[], medial=[], final=words)

    return TherapyWords(initial=[], medial=[], final=[])


def run_therapy(diagnosis_data: Dict[str, Any]) -> TherapyOutput:
    diagnosis_input = DiagnosisInput(**diagnosis_data)

    age_status = get_age_status(
        target_phoneme=diagnosis_input.target_phoneme,
        child_age=diagnosis_input.age
    )

    selected_stage = get_default_stage(age_status)

    selected_words = get_words_for_stage(
        target_phoneme=diagnosis_input.target_phoneme,
        stage=selected_stage
    )

    therapy_words = split_words_by_position(
        words=selected_words,
        stage=selected_stage
    )

    llm_feedback = generate_feedback_with_llm(
        diagnosis_data=diagnosis_input.model_dump(),
        selected_stage=selected_stage,
        selected_words=selected_words,
        age_status=age_status
    )

    feedback = FeedbackOutput(
        encouragement=llm_feedback["encouragement"],
        main_feedback=llm_feedback["main_feedback"],
        hint=llm_feedback["hint"]
    )

    tts_text = f"{feedback.encouragement} {feedback.main_feedback} {feedback.hint}"

    return TherapyOutput(
        child_id=diagnosis_input.child_id,
        target_word=diagnosis_input.target_word,
        target_phoneme=diagnosis_input.target_phoneme,
        age_status=age_status,
        difficulty_level=selected_stage,
        therapy_words=therapy_words,
        feedback=feedback,
        tts_text=tts_text,
        audio_url=None
    )