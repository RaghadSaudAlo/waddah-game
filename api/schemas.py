# api/schemas.py
# Purpose: the contract between the FastAPI service and the Flutter app.
# Change this file and you must change waddah_api.dart in the same commit.

from typing import List, Literal

from pydantic import BaseModel, Field


class DiagnoseResponse(BaseModel):
    target_word: str = Field(..., description="Normalized Arabic word that was prompted")
    target_phoneme: str = Field(..., description="IPA symbol under test, e.g. 'sˤ'")
    phoneme_position: str = Field(..., description="initial | medial | final")

    canonical: List[str] = Field(..., description="Expected phoneme sequence from the lexicon")
    predicted: List[str] = Field(..., description="Phoneme sequence the CTC head decoded")

    per: float = Field(..., description="Phoneme Error Rate for this utterance")
    subs: int
    dels: int
    ins: int

    detection: Literal["normal", "abnormal"] = Field(
        ..., description="Whole-word verdict — any misalignment anywhere"
    )
    target_detection: Literal["normal", "abnormal"] = Field(
        ..., description="Target-phoneme verdict — THIS is what the game scores on"
    )
    diagnosis: Literal["correct", "substitution", "deletion", "insertion"] = Field(
        ..., description="Operation observed at the target phoneme position"
    )

    confidence: float = Field(..., description="Mean max-softmax over non-blank frames, 0-1")
    latency_ms: float


class HealthResponse(BaseModel):
    status: str
    model_id: str
    lexicon_words: int
    device: str
    quantized: bool
