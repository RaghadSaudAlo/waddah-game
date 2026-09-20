import 'package:flutter/material.dart';
import '../services/user_profile_store.dart';

class PhonemesLibraryScreen extends StatefulWidget {
  const PhonemesLibraryScreen({super.key});

  @override
  State<PhonemesLibraryScreen> createState() => _PhonemesLibraryScreenState();
}

class _PhonemesLibraryScreenState extends State<PhonemesLibraryScreen> {
  int childAge = 6;

  final List<Map<String, dynamic>> phonemes = [
    {'phoneme': 'ء', 'name': 'الهمزة', 'expectedAge': 5, 'image': 'assets/images/asad.png', 'words': ['أم', 'أب', 'أخ', 'أسد', 'ماء']},
    {'phoneme': 'ب', 'name': 'الباء', 'expectedAge': 3, 'image': 'assets/images/battah.png', 'words': ['باب', 'دب', 'برتقال']},

{'phoneme': 'ت', 'name': 'التاء', 'expectedAge': 4, 'image': 'assets/images/tuffah.png', 'words': ['تفاح', 'بيت', 'مفتاح']},

{'phoneme': 'ث', 'name': 'الثاء', 'expectedAge': 6, 'image': 'assets/images/thalab.png', 'words': ['ثلاجة', 'ثلاثة', 'مثلث']},

{'phoneme': 'ج', 'name': 'الجيم', 'expectedAge': 5, 'image': 'assets/images/jamal.png', 'words': ['جزر', 'درج', 'شجرة']},

{'phoneme': 'ح', 'name': 'الحاء', 'expectedAge': 6, 'image': 'assets/images/masbah.png', 'words': ['حصان', 'أحمر', 'مسبح']},
    {'phoneme': 'خ', 'name': 'الخاء', 'expectedAge': 6, 'image': null, 'words': ['خيمة', 'مخدة', 'مطبخ']},
    {'phoneme': 'د', 'name': 'الدال', 'expectedAge': 4, 'image': null, 'words': ['دجاجة', 'ولد', 'وردة']},
    {'phoneme': 'ذ', 'name': 'الذال', 'expectedAge': 6, 'image': null, 'words': ['ذرة', 'أذن', 'قنفذ']},
    {'phoneme': 'ر', 'name': 'الراء', 'expectedAge': 6, 'image': null, 'words': ['رأس', 'كورة', 'سرير']},
    {'phoneme': 'ز', 'name': 'الزاي', 'expectedAge': 5, 'image': null, 'words': ['زرافة', 'أزرق', 'خبز']},
    {'phoneme': 'س', 'name': 'السين', 'expectedAge': 5, 'image': null, 'words': ['ساعة', 'سمك', 'سيارة', 'مدرسة']},
    {'phoneme': 'ش', 'name': 'الشين', 'expectedAge': 5, 'image': 'assets/images/shams.png', 'words': ['شمس', 'شجرة', 'فرشاة', 'ريش']},
    {'phoneme': 'ص', 'name': 'الصاد', 'expectedAge': 6, 'image': null, 'words': ['صحن', 'مقص', 'عصفور']},
    {'phoneme': 'ض', 'name': 'الضاد', 'expectedAge': 7, 'image': null, 'words': ['ضفدع', 'بيض', 'أخضر']},
    {'phoneme': 'ط', 'name': 'الطاء', 'expectedAge': 6, 'image': null, 'words': ['طيارة', 'مشط', 'شنطة']},
    {'phoneme': 'ظ', 'name': 'الظاء', 'expectedAge': 7, 'image': null, 'words': ['ظهر', 'نظارة', 'محافظ']},
    {'phoneme': 'ع', 'name': 'العين', 'expectedAge': 6, 'image': null, 'words': ['عين', 'عصير', 'ساعة']},
    {'phoneme': 'غ', 'name': 'الغين', 'expectedAge': 6, 'image': null, 'words': ['غسالة', 'يغسل', 'شماغ']},
    {'phoneme': 'ف', 'name': 'الفاء', 'expectedAge': 4, 'image': 'assets/images/fil.png', 'words': ['فيل', 'فم', 'تلفون', 'خروف']},
    {'phoneme': 'ق', 'name': 'القاف', 'expectedAge': 6, 'image': null, 'words': ['قرد', 'بقرة', 'صندوق']},
    {'phoneme': 'ك', 'name': 'الكاف', 'expectedAge': 4, 'image': 'assets/images/kitab.png', 'words': ['كتاب', 'كيك', 'سمكة', 'كرسي']},
    {'phoneme': 'ل', 'name': 'اللام', 'expectedAge': 5, 'image': null, 'words': ['لون', 'لعبة', 'لبن', 'جميل']},
    {'phoneme': 'م', 'name': 'الميم', 'expectedAge': 3, 'image': null, 'words': ['ماء', 'موز', 'مقص', 'قمر']},
    {'phoneme': 'ن', 'name': 'النون', 'expectedAge': 4, 'image': null, 'words': ['نور', 'نجم', 'نمر', 'عنب']},
    {'phoneme': 'ه', 'name': 'الهاء', 'expectedAge': 5, 'image': null, 'words': ['هاتف', 'هلال', 'نهر', 'شفاه']},
    {'phoneme': 'و', 'name': 'الواو', 'expectedAge': 4, 'image': null, 'words': ['ورد', 'وجه', 'وسادة', 'دلو']},
    {'phoneme': 'ي', 'name': 'الياء', 'expectedAge': 4, 'image': null, 'words': ['يد', 'خيار', 'كرسي']},
  ];

  @override
  void initState() {
    super.initState();
    _loadChildAge();
  }

  Future<void> _loadChildAge() async {
    final savedAge = await UserProfileStore.getAge();

    if (!mounted) return;

    setState(() {
      childAge = savedAge;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/home_screen.png',
            fit: BoxFit.cover,
          ),

          Positioned(
            top: 32,
            left: 24,
            child: _TopCircleButton(
              icon: Icons.arrow_forward_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),

          const Positioned(
            top: 38,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'مكتبة الحروف والشخصيات',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF27A9C9),
                ),
              ),
            ),
          ),

          Positioned(
            top: 105,
            left: 60,
            right: 60,
            bottom: 35,
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: phonemes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final item = phonemes[index];

                return _PhonemeRow(
                  phoneme: item['phoneme'],
                  name: item['name'],
                  expectedAge: item['expectedAge'],
                  childAge: childAge,
                  image: item['image'],
                  words: List<String>.from(item['words']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PhonemeRow extends StatelessWidget {
  final String phoneme;
  final String name;
  final int expectedAge;
  final int childAge;
  final String? image;
  final List<String> words;

  const _PhonemeRow({
    required this.phoneme,
    required this.name,
    required this.expectedAge,
    required this.childAge,
    required this.image,
    required this.words,
  });

  @override
  Widget build(BuildContext context) {
    final needsAttention = childAge >= expectedAge;

    return Container(
  constraints: const BoxConstraints(
    minHeight: 145,
  ),
  padding: const EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 18,
  ),
  decoration: BoxDecoration(
        color: const Color(0xFFFFF7DE).withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: needsAttention
              ? const Color(0xFFFFB7A8)
              : const Color(0xFFBFEFDD),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _characterCircle(),
          const SizedBox(width: 24),

          Expanded(
            child: Row(
              children: [
                _infoBlock(
                  title: 'الحرف المستهدف',
                  value: '$name  ($phoneme)',
                ),
                _divider(),
                _infoBlock(
                  title: 'عمر الطفل',
                  value: '$childAge سنوات',
                ),
                _divider(),
                _infoBlock(
                  title: 'العمر المتوقع',
                  value: '$expectedAge سنوات',
                ),
                _divider(),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'الكلمات',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF27A9C9),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: words.map((word) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              word,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D2D2D),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _characterCircle() {
    return Container(
      width: 105,
      height: 105,
      decoration: const BoxDecoration(
        color: Color(0xFFFFE08A),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: image == null
            ? Text(
                phoneme,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF27A9C9),
                ),
              )
            : Image.asset(
                image!,
                width: 78,
                fit: BoxFit.contain,
              ),
      ),
    );
  }

  Widget _infoBlock({
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF27A9C9),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2D2D2D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 2,
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: const Color(0xFFE8DDAE),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE08A),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 24,
          color: const Color(0xFF2D2D2D),
        ),
      ),
    );
  }
}