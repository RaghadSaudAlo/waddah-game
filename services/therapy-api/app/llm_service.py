import os
import json
from typing import Dict, Any

from openai import OpenAI


ARABIC_PHONEME_NAMES = {
    "أ": "الهمزة",
    "ء": "الهمزة",
    "ب": "الباء",
    "ت": "التاء",
    "ث": "الثاء",
    "ج": "الجيم",
    "ح": "الحاء",
    "خ": "الخاء",
    "د": "الدال",
    "ذ": "الذال",
    "ر": "الراء",
    "ز": "الزاي",
    "س": "السين",
    "ش": "الشين",
    "ص": "الصاد",
    "ض": "الضاد",
    "ط": "الطاء",
    "ظ": "الظاء",
    "ع": "العين",
    "غ": "الغين",
    "ف": "الفاء",
    "ق": "القاف",
    "ك": "الكاف",
    "ل": "اللام",
    "م": "الميم",
    "ن": "النون",
    "ه": "الهاء",
    "و": "الواو",
    "ي": "الياء"
}


def get_performance_band(per: float) -> str:
    if per <= 0.10:
        return "Excellent"
    elif per <= 0.30:
        return "Good"
    else:
        return "Needs Support"


FEW_SHOT_EXAMPLES = """
Example 1:

Input:
Target word: أسد
Target phoneme: السين
Produced phoneme: الثاء
Error type: substitution
Performance band: Needs Support
Confidence score: 0.87

Output:
{
  "encouragement": "محاولة جميلة!",
  "main_feedback": "حاول أن تجعل صوت السين أوضح عند نطق كلمة أسد.",
  "hint": "ابتسم قليلًا وقل سسس بهدوء."
}

Example 2:

Input:
Target word: تفاح
Target phoneme: التاء
Produced phoneme: التاء
Error type: correct
Performance band: Excellent
Confidence score: 0.94

Output:
{
  "encouragement": "أحسنت!",
  "main_feedback": "نطقك ممتاز وقريب جدًا من الصوت الصحيح.",
  "hint": "استمر بنفس الأداء الجميل."
}

Example 3:

Input:
Target word: فيل
Target phoneme: الفاء
Produced phoneme: الباء
Error type: substitution
Performance band: Good
Confidence score: 0.78

Output:
{
  "encouragement": "جيد جدًا!",
  "main_feedback": "حاول إخراج الهواء بلطف عند نطق الفاء.",
  "hint": "ضع أسنانك على الشفة السفلية وقل ففف."
}
"""


def get_openai_client() -> OpenAI:
    api_key = os.getenv("OPENAI_API_KEY")

    if not api_key:
        raise ValueError("OPENAI_API_KEY is not set in environment variables")

    return OpenAI(api_key=api_key)


def build_feedback_prompt(
    diagnosis_data: Dict[str, Any],
    selected_stage: str,
    selected_words: list[str],
    age_status: str
) -> str:

    target_phoneme = diagnosis_data.get("target_phoneme", "")
    produced_phoneme = diagnosis_data.get("produced_phoneme", "")

    target_phoneme_name = ARABIC_PHONEME_NAMES.get(
        target_phoneme,
        target_phoneme
    )

    produced_phoneme_name = ARABIC_PHONEME_NAMES.get(
        produced_phoneme,
        produced_phoneme
    )

    performance_band = get_performance_band(
        diagnosis_data.get("per", 1.0)
    )

    prompt = f"""
أنت مساعد علاج نطق للأطفال باللغة العربية.

المهمة:
بناءً على بيانات التشخيص، أعطِ feedback علاجي مناسب لطفل.

القواعد:
- استخدم لغة عربية بسيطة ومناسبة للأطفال
- لا تستخدم مصطلحات طبية
- لا تضف شروحات خارج المطلوب
- لا تحكم على قدرات الطفل
- إذا كانت الثقة أقل من 0.60 استخدم دعمًا لطيفًا بدون تصحيح مباشر
- إذا كانت الثقة أعلى أو تساوي 0.60 أعطِ تصحيحًا واضحًا وبسيطًا
- استخدم اسم الحرف العربي الكامل
- أعد النتيجة بصيغة JSON فقط

Few-shot examples:

{FEW_SHOT_EXAMPLES}

Current case:

Child ID: {diagnosis_data.get("child_id")}
Age: {diagnosis_data.get("age")}
Target word: {diagnosis_data.get("target_word")}
Target phoneme: {target_phoneme_name}
Produced phoneme: {produced_phoneme_name}
Error type: {diagnosis_data.get("error_type")}
Confidence score: {diagnosis_data.get("confidence")}
PER score: {diagnosis_data.get("per")}
Performance band: {performance_band}
Age status: {age_status}
Selected stage: {selected_stage}
Selected therapy words: {selected_words[:8]}

Output JSON format:
{{
  "encouragement": "...",
  "main_feedback": "...",
  "hint": "..."
}}
"""

    return prompt.strip()


def generate_feedback_with_llm(
    diagnosis_data: Dict[str, Any],
    selected_stage: str,
    selected_words: list[str],
    age_status: str,
    model_name: str = "gpt-4o"
) -> Dict[str, str]:

    client = get_openai_client()

    prompt = build_feedback_prompt(
        diagnosis_data=diagnosis_data,
        selected_stage=selected_stage,
        selected_words=selected_words,
        age_status=age_status
    )

    response = client.chat.completions.create(
        model=model_name,
        messages=[
            {
                "role": "system",
                "content": "You generate structured Arabic therapy feedback for children."
            },
            {
                "role": "user",
                "content": prompt
            }
        ],
        temperature=0.4
    )

    content = response.choices[0].message.content.strip()

    print("\n--- raw llm response ---")
    print(content)

    cleaned_content = content

    if cleaned_content.startswith("```json"):
        cleaned_content = cleaned_content.replace(
            "```json",
            "",
            1
        ).strip()

    if cleaned_content.startswith("```"):
        cleaned_content = cleaned_content.replace(
            "```",
            "",
            1
        ).strip()

    if cleaned_content.endswith("```"):
        cleaned_content = cleaned_content[:-3].strip()

    print("\n--- cleaned llm response ---")
    print(cleaned_content)

    try:
        parsed = json.loads(cleaned_content)

    except json.JSONDecodeError:
        print("\n--- llm json parse failed, using fallback ---")

        parsed = {
            "encouragement": "أحسنت",
            "main_feedback": "سنكمل التدريب على هذا الحرف بشكل تدريجي.",
            "hint": "استمع جيدًا ثم أعد المحاولة ببطء."
        }

    return {
        "encouragement": parsed.get(
            "encouragement",
            "أحسنت"
        ),
        "main_feedback": parsed.get(
            "main_feedback",
            "سنكمل التدريب على هذا الحرف بشكل تدريجي."
        ),
        "hint": parsed.get(
            "hint",
            "استمع جيدًا ثم أعد المحاولة ببطء."
        )
    }