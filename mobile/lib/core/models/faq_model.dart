class FaqModel {
  final int id;
  final String question;
  final String answer;
  final int order;

  const FaqModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.order,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) => FaqModel(
        id: json['id'] as int,
        question: json['question'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
        order: json['order'] as int? ?? 0,
      );
}
