import 'package:flutter/material.dart';
import '../models/therapy_target.dart';

class CharactersCatalogScreen extends StatelessWidget {
  const CharactersCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = _catalogItems;

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
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE08A),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ),
          ),

          const Positioned(
            top: 38,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'الحروف والشخصيات',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF27A9C9),
                ),
              ),
            ),
          ),

          Positioned(
            top: 110,
            left: 40,
            right: 40,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7DE).withOpacity(0.95),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE08A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'الشخصية / الكلمة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'الحرف المستهدف',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'العمر',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFBFEFDD),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 62,
                                      height: 62,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFF3C4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: item.imagePath != null
                                          ? Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Image.asset(
                                                item.imagePath!,
                                                fit: BoxFit.contain,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.image_outlined,
                                              color: Color(0xFF2D2D2D),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item.word,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF2D2D2D),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.targetPhoneme,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF27A9C9),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${item.minAge}+',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2D2D2D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const List<TherapyTarget> _catalogItems = [
  TherapyTarget(
    word: 'أسد',
    targetPhoneme: 'ء',
    minAge: 5,
    needsTherapy: true,
    imagePath: 'assets/images/asad.png',
  ),
  TherapyTarget(
    word: 'شمس',
    targetPhoneme: 'ش',
    minAge: 5,
    needsTherapy: true,
    imagePath: 'assets/images/shams.png',
  ),
  TherapyTarget(
    word: 'كتاب',
    targetPhoneme: 'ك',
    minAge: 5,
    needsTherapy: true,
    imagePath: 'assets/images/kitab.png',
  ),
  TherapyTarget(
    word: 'فيل',
    targetPhoneme: 'ف',
    minAge: 5,
    needsTherapy: true,
    imagePath: 'assets/images/fil.png',
  ),

  // أضيفي الصورة لاحقًا
  TherapyTarget(
    word: 'حصان',
    targetPhoneme: 'ح',
    minAge: 5,
    needsTherapy: true,
    imagePath: null,
  ),

  // أضيفي الصورة لاحقًا
  TherapyTarget(
    word: 'برتقال',
    targetPhoneme: 'ب',
    minAge: 5,
    needsTherapy: true,
    imagePath: null,
  ),

  // أضيفي الصورة لاحقًا
  TherapyTarget(
    word: 'عسل',
    targetPhoneme: 'ع',
    minAge: 5,
    needsTherapy: true,
    imagePath: null,
  ),
];