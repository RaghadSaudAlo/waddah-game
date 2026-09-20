import json

from app.age_rules import get_age_status
from app.word_bank import get_words_for_stage, get_structured_words_for_stage
from app.therapy_engine import run_therapy
from app.tts_service import generate_tts_audio

print("س ، عمر 4:", get_age_status("س", 4))
print("س ، عمر 5:", get_age_status("س", 5))
print("ر ، عمر 5:", get_age_status("ر", 5))
print("م ، عمر 5:", get_age_status("م", 5))

print("\n--- word bank tests ---")
print("ل - isolation:", get_words_for_stage("ل", "isolation"))
print("ل - one_syllable:", get_words_for_stage("ل", "one_syllable"))
print("م - word_initial:", get_words_for_stage("م", "word_initial"))
print("ن - phrase:", get_words_for_stage("ن", "phrase"))

print("\n--- structured test ---")
print(get_structured_words_for_stage("ل", "one_syllable"))

print("\n--- therapy engine test ---")
with open("examples/therapy_input_example.json", "r", encoding="utf-8") as f:
    diagnosis_data = json.load(f)

therapy_output = run_therapy(diagnosis_data)
print(therapy_output.model_dump_json(indent=2, ensure_ascii=False))

print("\n--- tts test ---")
audio_file = generate_tts_audio(
    text=therapy_output.tts_text,
    output_path="waddah_test_output.mp3"
)
print("Generated audio file:", audio_file)