from typing import Dict, List, Literal, Optional
from pydantic import BaseModel, Field


from pydantic import BaseModel
from typing import List, Dict, Any, Optional


class DiagnosisInput(BaseModel):
    child_id: str = Field(..., description="Unique child identifier")
    age: int = Field(..., ge=2, le=12, description="Child age in years")

    target_word: str = Field(..., description="Target word used in diagnosis")
    target_phoneme: str = Field(..., description="Expected phoneme")
    produced_phoneme: str = Field(..., description="Produced phoneme by child")

    error_type: Literal["substitution", "deletion", "insertion", "distortion", "other"] = Field(
        ...,
        description="Type of phoneme-level error"
    )

    confidence: float = Field(..., ge=0.0, le=1.0, description="Model confidence")
    per: float = Field(..., ge=0.0, le=1.0, description="Phoneme Error Rate")

    session_id: Optional[str] = Field(default=None, description="Optional session identifier")
    word_position: Optional[Literal["initial", "medial", "final"]] = Field(
        default=None,
        description="Optional phoneme position inside target word"
    )


class TherapyWords(BaseModel):
    initial: List[str] = []
    medial: List[str] = []
    final: List[str] = []


class FeedbackOutput(BaseModel):
    encouragement: str
    main_feedback: str
    hint: str


class TherapyOutput(BaseModel):
    child_id: str
    target_word: str
    target_phoneme: str

    age_status: Literal["needs_therapy", "age_appropriate"]
    difficulty_level: Literal[
        "isolation",
        "one_syllable",
        "two_syllables",
        "word",
        "phrase",
        "sentence"
    ]

    therapy_words: TherapyWords
    feedback: FeedbackOutput

    tts_text: str = Field(..., description="Final text to send to TTS")
    audio_url: Optional[str] = Field(default=None, description="Optional generated audio URL")


class TherapyResponse(BaseModel):
    success: bool
    diagnosis_input: DiagnosisInput
    therapy_output: TherapyOutput


class DiagnosisMockRequest(BaseModel):
    word: str
    target_phoneme: str
    position: Literal["initial", "medial", "final"]


class DiagnosisMockResponse(BaseModel):
    success: bool
    word: str
    target_phoneme: str
    position: Literal["initial", "medial", "final"]
    is_correct: bool
    message: str

class UploadedDiagnosisResponse(BaseModel):
    success: bool
    word: str
    target_phoneme: str
    position: Literal["initial", "medial", "final"]
    audio_filename: str
    audio_saved_path: str
    is_correct: bool
    message: str



class DiagnosisResultItem(BaseModel):
    word: str
    target_phoneme: str
    position: str
    produced_phoneme: Optional[str] = ""


class TherapyPlanRequest(BaseModel):
    age: int
    diagnosis_results: List[DiagnosisResultItem]


class TherapyTargetItem(BaseModel):
    word: str
    target_phoneme: str
    position: str
    produced_phoneme: Optional[str] = ""
    age_status: str


class TherapyPlanResponse(BaseModel):
    therapy_targets: List[TherapyTargetItem]


class TherapySessionRequest(BaseModel):
    selected_word: str
    target_phoneme: str
    position: str


class TherapySessionResponse(BaseModel):
    selected_word: str
    target_phoneme: str
    position: str
    progression: Dict[str, Any]
    stages: List[Dict[str, Any]]
    word_sequence: List[str]
    phrases: List[str]
    sentences: List[str]