/// A seller-authored FAQ scoped to this one store — `solvexo-api`'s
/// `src/store-faq` (`StoreFaq` schema). Distinct from the platform-wide
/// `FaqModel` (`lib/app/modules/help_center`), which answers questions about
/// Solvexo itself, not any individual store.
class StoreFaqModel {
  final String id;
  final String question;
  final String answer;
  final int order;

  const StoreFaqModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.order,
  });

  factory StoreFaqModel.fromJson(Map<String, dynamic> json) => StoreFaqModel(
    id: json['_id']?.toString() ?? '',
    question: json['question'] as String? ?? '',
    answer: json['answer'] as String? ?? '',
    order: json['order'] as int? ?? 0,
  );
}
