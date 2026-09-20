import 'package:flutter/material.dart';

class SceneBackground extends StatelessWidget {
  const SceneBackground({
    super.key,
    required this.assetPath,
    this.overlayGradient,
  });

  final String assetPath;
  final Gradient? overlayGradient;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          assetPath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, _, _) => Container(
            color: const Color(0xFFB8EBD5),
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported_outlined, size: 48),
          ),
        ),
        if (overlayGradient != null)
          DecoratedBox(
            decoration: BoxDecoration(gradient: overlayGradient),
          ),
      ],
    );
  }
}
