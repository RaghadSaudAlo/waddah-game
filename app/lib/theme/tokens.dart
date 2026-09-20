import 'package:flutter/material.dart';

class AppColors {
  static const cream = Color(0xFFFFF8F0);
  static const mint = Color(0xFFB8EBD5);
  static const peach = Color(0xFFFFD6C9);
  static const lavender = Color(0xFFDCE3FF);
  static const coral = Color(0xFFFF8A7A);
  static const deepMint = Color(0xFF2D6A4F);
  static const sky = Color(0xFF7EC8E3);
  static const gold = Color(0xFFFFD166);
  static const ink = Color(0xFF2B2D42);
}

class AppGradients {
  static const toyCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF0FFF7),
    ],
  );
}
