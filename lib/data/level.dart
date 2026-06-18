/// A single puzzle level loaded from assets/data/levels.json.
class Level {
  final int level;
  final String question;
  final String answer;
  final String hint;
  final String solution;

  const Level({
    required this.level,
    required this.question,
    required this.answer,
    required this.hint,
    required this.solution,
  });

  factory Level.fromJson(Map<String, dynamic> json) => Level(
        level: json['level'] as int,
        question: json['question'] as String,
        answer: json['answer'] as String,
        hint: json['hint'] as String,
        solution: json['solution'] as String,
      );

  /// Normalised form used for answer comparison.
  static String normalize(String input) =>
      input.trim().toLowerCase().replaceAll(' ', '');

  bool isCorrect(String input) => normalize(input) == normalize(answer);
}
