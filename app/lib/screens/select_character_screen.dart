import 'package:flutter/material.dart';
import '../screens/animal_prompt_screen.dart';

class SelectCharacterScreen extends StatelessWidget {
  const SelectCharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "اختر شخصية",
            style: TextStyle(fontSize: 28),
          ),

          const SizedBox(height: 30),

          Wrap(
            spacing: 20,
            children: [
              _item(context, "أسد", 'assets/images/asad.png'),
              _item(context, "شمس", 'assets/images/shams.png'),
              _item(context, "كتاب", 'assets/images/kitab.png'),
            ],
          )
        ],
      ),
    );
  }

  Widget _item(context, word, image) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnimalPromptScreen(
  wordOnlyText: word,
  fullPromptText: "هذا $word، قل: $word",
  characterImage: image,
  backgroundImage: 'assets/images/lion_game_screen.png',

  targetPhoneme: word[0],
  position: "initial",
),
          ),
        );
      },
      child: Column(
        children: [
          Image.asset(image, width: 100),
          Text(word),
        ],
      ),
    );
  }
}