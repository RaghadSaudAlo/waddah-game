import 'package:flutter/material.dart';
import 'animal_prompt_screen.dart';
import 'elephant_screen.dart';

class LionScreen extends StatelessWidget {
  const LionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnimalPromptScreen(
      backgroundImage: 'assets/images/lion_game_screen.png',
      characterImage: 'assets/images/asad.png',
      fullPromptText: 'هذا صديقي الأسد \nهل تستطيع أن تقول: أسد؟',
      wordOnlyText: 'أسد',
      targetPhoneme: 'ء',
      position: 'initial',
      characterLeft: 780,
      characterBottom: 90,
      characterWidth: 360,
      nextScreen: ElephantScreen(),
    );
  }
}