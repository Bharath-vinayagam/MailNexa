class StatusHistoryItem {
  final String status;
  final DateTime changedAt;
  final String? note;

  const StatusHistoryItem({
    required this.status,
    required this.changedAt,
    this.note,
  });

  factory StatusHistoryItem.fromJson(Map<String, dynamic> json) {
    return StatusHistoryItem(
      status: json['status'] as String? ?? 'Applied',
      changedAt: DateTime.tryParse(json['changedAt'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String?,
    );
  }
}

class ApplicationModel {
  final String id;
  final String companyName;
  final String role;
  final String location;
  final String status;
  final String notes;
  final List<StatusHistoryItem> statusHistory;
  final DateTime appliedAt;

  const ApplicationModel({
    required this.id,
    required this.companyName,
    required this.role,
    required this.location,
    required this.status,
    required this.notes,
    required this.statusHistory,
    required this.appliedAt,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      role: json['role'] as String? ?? '',
      location: json['location'] as String? ?? '',
      status: json['status'] as String? ?? 'Applied',
      notes: json['notes'] as String? ?? '',
      statusHistory: List<StatusHistoryItem>.from(
        (json['statusHistory'] as List? ?? []).map((e) => StatusHistoryItem.fromJson(e as Map<String, dynamic>)),
      ),
      appliedAt: DateTime.tryParse(json['appliedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
