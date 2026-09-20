import 'package:flutter/material.dart';
import 'animal_prompt_screen.dart';
import 'book_screen.dart';

class SunScreen extends StatelessWidget {
  const SunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnimalPromptScreen(
      backgroundImage: 'assets/images/lion_game_screen.png',
      characterImage: 'assets/images/shams.png',
      fullPromptText: 'هذه صديقتي الشمس \nهل تستطيع أن تقول: شمس؟',
      wordOnlyText: 'شمس',
      targetPhoneme: 'ش',
position: 'initial',
      characterLeft: 780,
      characterBottom: 90,
      characterWidth: 320,
      nextScreen: BookScreen(),
    );
  }
}