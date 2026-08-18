class EmailModel {
  final String id;
  final String gmailId;
  final String sender;
  final String senderEmail;
  final String subject;
  final String snippet;
  final String body;
  final String category;
  final String priority;
  final DateTime? deadline;
  final String? deadlineDescription;
  final List<String> labels;
  final bool isRead;
  final bool isApplied;
  final bool isShortlisted;
  final List<Map<String, dynamic>> attachments;
  final List<Map<String, dynamic>> events;
  final bool manualOverride;
  final double aiConfidence;
  final String? aiReasoning;
  /// Auto-generated summary using user's custom AI prompt (populated at sync time)
  final String? autoSummary;
  final DateTime receivedAt;
  final DateTime? createdAt;

  const EmailModel({
    required this.id,
    required this.gmailId,
    required this.sender,
    required this.senderEmail,
    required this.subject,
    required this.snippet,
    required this.body,
    required this.category,
    required this.priority,
    this.deadline,
    this.deadlineDescription,
    required this.labels,
    required this.isRead,
    required this.isApplied,
    this.isShortlisted = false,
    this.attachments = const [],
    this.events = const [],
    required this.manualOverride,
    required this.aiConfidence,
    this.aiReasoning,
    this.autoSummary,
    required this.receivedAt,
    this.createdAt,
  });

  factory EmailModel.fromJson(Map<String, dynamic> json) {
    return EmailModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      gmailId: json['gmailId'] as String? ?? '',
      sender: json['sender'] as String? ?? '',
      senderEmail: json['senderEmail'] as String? ?? '',
      subject: json['subject'] as String? ?? '(No Subject)',
      snippet: json['snippet'] as String? ?? '',
      body: json['body'] as String? ?? '',
      category: json['category'] as String? ?? 'Others',
      priority: json['priority'] as String? ?? 'Low',
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'] as String) : null,
      deadlineDescription: json['deadlineDescription'] as String?,
      labels: List<String>.from(json['labels'] as List? ?? []),
      isRead: json['isRead'] as bool? ?? false,
      isApplied: json['isApplied'] as bool? ?? false,
      isShortlisted: json['isShortlisted'] as bool? ?? false,
      attachments: List<Map<String, dynamic>>.from(json['attachments'] as List? ?? []),
      events: List<Map<String, dynamic>>.from(json['events'] as List? ?? []),
      manualOverride: json['manualOverride'] as bool? ?? false,
      aiConfidence: (json['aiConfidence'] as num?)?.toDouble() ?? 0.0,
      aiReasoning: json['aiReasoning'] as String?,
      autoSummary: json['autoSummary'] as String?,
      receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ?? DateTime.now(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }

  bool get isHighPriority => priority == 'High';
  bool get isMediumPriority => priority == 'Medium';
  bool get isPlacement => category == 'Placement';
  bool get hasDeadline => deadline != null;

  EmailModel copyWith({bool? isRead, bool? isApplied, String? category, String? priority}) {
    return EmailModel(
      id: id,
      gmailId: gmailId,
      sender: sender,
      senderEmail: senderEmail,
      subject: subject,
      snippet: snippet,
      body: body,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      deadline: deadline,
      deadlineDescription: deadlineDescription,
      labels: labels,
      isRead: isRead ?? this.isRead,
      isApplied: isApplied ?? this.isApplied,
      isShortlisted: isShortlisted,
      attachments: attachments,
      events: events,
      manualOverride: manualOverride,
      aiConfidence: aiConfidence,
      aiReasoning: aiReasoning,
      autoSummary: autoSummary,
      receivedAt: receivedAt,
      createdAt: createdAt,
    );
  }
}
