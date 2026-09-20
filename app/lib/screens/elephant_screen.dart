import 'package:flutter/material.dart';
import 'animal_prompt_screen.dart';
import 'sun_screen.dart';

class ElephantScreen extends StatelessWidget {
  const ElephantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnimalPromptScreen(
      backgroundImage: 'assets/images/lion_game_screen.png',
      characterImage: 'assets/images/fil.png',
      fullPromptText: 'هذا صديقي الفيل \nهل تستطيع أن تقول: فيل؟',
      wordOnlyText: 'فيل',
      targetPhoneme: 'ف',
position: 'initial',
      characterLeft: 780,
      characterBottom: 90,
      characterWidth: 360,
      nextScreen: SunScreen(),
    );
  }
}