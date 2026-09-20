/// Full pronunciation word list for وضّاح
class WordBank {
  WordBank._();

  static const List<String> all = [
    'أسد','برتقال','تفاح','ثلاجة','جزر','حصان','خيمة','دجاجه','ذرة','راس',
    'زرافة','سيارة','شمس','صحن','ضفدع','طيارة','ظهر','عصير','غسالة','فيل',
    'قرد','كتاب','ليمون','مسجد','نار','هدايا','واحد','يد','باب','دباب',
    'مفتاح','ثلاثة','شجرة','احمر','مخدة','وردة','اذن','كورة','ازرق','اسود',
    'فرشاة','عصفور','أخضر','شنطة','نظارة','ساعة','يغسل','تلفون','بقرة','سمكة',
    'قلم','تمر','عنب','قهوه','موز','خيار','يقرا','دب','بيت','مثلث',
    'درج','مسبح','مطبخ','ولد','قنفذ','سرير','خبز','بطاطس','ريش','مقص',
    'بيض','مشط','محافظ','اصبع','شماغ','خروف','صندوق','كيك','عسل','علم',
    'عين','سكينه','شامبو','كرسي',
  ];

  /// أول حرف عربي
  static String firstLetter(String word) {
    if (word.isEmpty) return '؟';
    return String.fromCharCode(word.runes.first);
  }

  /// كلمات للثيرابي حسب الحرف
  static List<String> wordsForWeakLetter(String letter) {
    final key = letter.trim();
    if (key.isEmpty) return all.take(12).toList();

    final starts =
        all.where((w) => w.isNotEmpty && firstLetter(w) == key).toList();

    if (starts.length >= 4) return starts;

    final contains = all
        .where((w) => w.contains(key))
        .where((w) => !starts.contains(w))
        .toList();

    final merged = [...starts, ...contains];

    if (merged.length >= 6) return merged.take(16).toList();

    return [
      ...merged,
      ...all.where((w) => !merged.contains(w))
    ].take(16).toList();
  }

  /// الكلمة التالية
  static String? nextWordAfter(String current) {
    final i = all.indexOf(current);
    if (i < 0 || i >= all.length - 1) return null;
    return all[i + 1];
  }

  /// اختيار عشوائي (بدون كراش 🔥)
  static String randomWord([String? avoid]) {
    // مهم: نسوي نسخة قابلة للتعديل
    final List<String> pool = avoid == null
        ? List<String>.from(all)
        : all.where((w) => w != avoid).toList();

    if (pool.isEmpty) return all.first;

    pool.shuffle();
    return pool.first;
  }
}