import 'package:flutter/material.dart';
import 'animal_prompt_screen.dart';

class BookScreen extends StatelessWidget {
  const BookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnimalPromptScreen(
      backgroundImage: 'assets/images/lion_game_screen.png',
      characterImage: 'assets/images/kitab.png',
      fullPromptText: 'هذا صديقي الكتاب \nهل تستطيع أن تقول: كتاب؟',
      wordOnlyText: 'كتاب',
      targetPhoneme: 'ك',
position: 'initial',
      characterLeft: 780,
      characterBottom: 90,
      characterWidth: 320,
      nextScreen: null,
    );
  }
}