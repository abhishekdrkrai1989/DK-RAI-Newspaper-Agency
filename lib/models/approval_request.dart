enum ApprovalActionType {
  pausePaper,
  startPaper,
  addCustomer,
  deleteCustomer,
  editCustomer,
  addPublication,
  deletePublication,
}

enum ApprovalStatus {
  pending,
  approved,
  rejected,
}

class ApprovalRequest {
  final String id;
  final ApprovalActionType actionType;
  final String title;
  final String description;
  final String targetId;
  final String requestedBy;
  final DateTime requestedAt;
  final ApprovalStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final Map<String, dynamic> payload;

  const ApprovalRequest({
    required this.id,
    required this.actionType,
    required this.title,
    required this.description,
    required this.targetId,
    required this.requestedBy,
    required this.requestedAt,
    this.status = ApprovalStatus.pending,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
    this.payload = const {},
  });

  bool get isPending => status == ApprovalStatus.pending;
  bool get isApproved => status == ApprovalStatus.approved;
  bool get isRejected => status == ApprovalStatus.rejected;

  ApprovalRequest copyWith({
    ApprovalStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? reviewNote,
  }) {
    return ApprovalRequest(
      id: id,
      actionType: actionType,
      title: title,
      description: description,
      targetId: targetId,
      requestedBy: requestedBy,
      requestedAt: requestedAt,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNote: reviewNote ?? this.reviewNote,
      payload: payload,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'actionType': actionType.name,
        'title': title,
        'description': description,
        'targetId': targetId,
        'requestedBy': requestedBy,
        'requestedAt': requestedAt.toIso8601String(),
        'status': status.name,
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt?.toIso8601String(),
        'reviewNote': reviewNote,
        'payload': payload,
      };

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      id: json['id'] as String? ?? 'req_${DateTime.now().millisecondsSinceEpoch}',
      actionType: ApprovalActionType.values.firstWhere(
        (e) => e.name == json['actionType'],
        orElse: () => ApprovalActionType.pausePaper,
      ),
      title: json['title'] as String? ?? 'Action Request',
      description: json['description'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      requestedBy: json['requestedBy'] as String? ?? 'Delivery Boy',
      requestedAt: DateTime.tryParse(json['requestedAt'] as String? ?? '') ??
          DateTime.now(),
      status: ApprovalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: DateTime.tryParse(json['reviewedAt'] as String? ?? ''),
      reviewNote: json['reviewNote'] as String?,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    );
  }
}
