import '../l10n/app_strings.dart';

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

  String actionName(AppStrings s) {
    switch (actionType) {
      case ApprovalActionType.addCustomer:
        return s.tr('New Customer Added', 'नया ग्राहक जोड़ा गया');
      case ApprovalActionType.editCustomer:
        return s.tr('Customer Details Updated', 'ग्राहक विवरण बदला गया');
      case ApprovalActionType.deleteCustomer:
        return s.tr('Customer Deletion Requested', 'ग्राहक हटाने का अनुरोध');
      case ApprovalActionType.startPaper:
        return s.tr('Paper Resumed', 'अखबार चालू किया गया');
      case ApprovalActionType.pausePaper:
        return s.tr('Paper Paused', 'अखबार बंद किया गया');
      case ApprovalActionType.addPublication:
        return s.tr('Publication Added', 'अखबार/पत्रिका जोड़ी गई');
      case ApprovalActionType.deletePublication:
        return s.tr('Publication Deleted', 'अखबार/पत्रिका हटाई गई');
    }
  }

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

  Map<String, dynamic> toRow() => {
        'id': id,
        'action_type': actionType.name,
        'title': title,
        'description': description,
        'target_id': targetId,
        'requested_by': requestedBy,
        'requested_at': requestedAt.toUtc().toIso8601String(),
        'status': status.name,
        'reviewed_by': reviewedBy,
        'reviewed_at': reviewedAt?.toUtc().toIso8601String(),
        'review_note': reviewNote,
        'payload': payload,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  factory ApprovalRequest.fromRow(Map<String, dynamic> row) {
    final id = (row['id'] as String?) ?? '';
    final actionTypeStr = (row['action_type'] as String?) ??
        (row['actionType'] as String?) ??
        'pausePaper';
    final actionType = ApprovalActionType.values.firstWhere(
      (e) => e.name == actionTypeStr,
      orElse: () => ApprovalActionType.pausePaper,
    );
    final title = (row['title'] as String?) ?? 'Action Request';
    final description = (row['description'] as String?) ?? '';
    final targetId = (row['target_id'] as String?) ??
        (row['targetId'] as String?) ??
        '';
    final requestedBy = (row['requested_by'] as String?) ??
        (row['requestedBy'] as String?) ??
        'Delivery Boy';
    final requestedAt = DateTime.tryParse(
          (row['requested_at'] as String?) ??
              (row['requestedAt'] as String?) ??
              '',
        ) ??
        DateTime.now();
    final statusStr = (row['status'] as String?) ?? 'pending';
    final status = ApprovalStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => ApprovalStatus.pending,
    );
    final reviewedBy = (row['reviewed_by'] as String?) ??
        (row['reviewedBy'] as String?);
    final reviewedAt = DateTime.tryParse(
      (row['reviewed_at'] as String?) ??
          (row['reviewedAt'] as String?) ??
          '',
    );
    final reviewNote = (row['review_note'] as String?) ??
        (row['reviewNote'] as String?);

    final rawPayload = row['payload'];
    Map<String, dynamic> payload = const {};
    if (rawPayload is Map<String, dynamic>) {
      payload = rawPayload;
    } else if (rawPayload is Map) {
      payload = Map<String, dynamic>.from(rawPayload);
    }

    return ApprovalRequest(
      id: id,
      actionType: actionType,
      title: title,
      description: description,
      targetId: targetId,
      requestedBy: requestedBy,
      requestedAt: requestedAt,
      status: status,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt,
      reviewNote: reviewNote,
      payload: payload,
    );
  }

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) =>
      ApprovalRequest.fromRow(json);
}
