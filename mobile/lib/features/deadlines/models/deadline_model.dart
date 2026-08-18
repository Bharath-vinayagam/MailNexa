class DeadlineModel {
  final String id;
  final String title;
  final String description;
  final String source;
  final DateTime dueDate;
  final bool isCompleted;
  final bool isOverdue;
  final DateTime? completedAt;
  final String category;

  const DeadlineModel({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
    required this.dueDate,
    required this.isCompleted,
    required this.isOverdue,
    this.completedAt,
    required this.category,
  });

  factory DeadlineModel.fromJson(Map<String, dynamic> json) {
    return DeadlineModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      source: json['source'] as String? ?? '',
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isOverdue: json['isOverdue'] as bool? ?? false,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'] as String) : null,
      category: json['category'] as String? ?? 'General',
    );
  }

  DeadlineModel copyWith({bool? isCompleted}) {
    return DeadlineModel(
      id: id,
      title: title,
      description: description,
      source: source,
      dueDate: dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isOverdue: isOverdue,
      completedAt: completedAt,
      category: category,
    );
  }
}
