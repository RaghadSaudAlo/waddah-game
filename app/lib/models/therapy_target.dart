class TherapyTarget {
  final String word;
  final String targetPhoneme;
  final int minAge;
  final String? imagePath;
  final bool needsTherapy;

  const TherapyTarget({
    required this.word,
    required this.targetPhoneme,
    required this.minAge,
    required this.needsTherapy,
    this.imagePath,
  });
}