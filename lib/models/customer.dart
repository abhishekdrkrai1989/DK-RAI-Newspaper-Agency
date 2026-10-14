import 'publication.dart';

enum DeliveryStatus {
  started,
  paused,
}

class StatusLog {
  final DeliveryStatus status;
  final DateTime timestamp;
  final String note;

  const StatusLog({
    required this.status,
    required this.timestamp,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
      };

  factory StatusLog.fromJson(Map<String, dynamic> json) {
    return StatusLog(
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DeliveryStatus.started,
      ),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      note: json['note'] as String? ?? '',
    );
  }
}

class Customer {
  final String id;
  final int sequenceNo;
  final String name;
  final String houseNumber;
  final String block;
  final String area;
  final String phone;
  final DeliveryStatus status;
  final DateTime? pauseStartDate;
  final DateTime? pauseEndDate;
  final String pauseReason;
  final List<SubscriptionItem> subscriptions;
  final List<String> deliveredDates;
  final List<StatusLog> statusHistory;
  final String notes;

  const Customer({
    required this.id,
    required this.sequenceNo,
    required this.name,
    required this.houseNumber,
    this.block = '',
    required this.area,
    this.phone = '',
    this.status = DeliveryStatus.started,
    this.pauseStartDate,
    this.pauseEndDate,
    this.pauseReason = '',
    required this.subscriptions,
    this.deliveredDates = const [],
    this.statusHistory = const [],
    this.notes = '',
  });

  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Infers Block name from house number (e.g., "A-101" -> "Block A") when not explicitly set
  static String inferBlockFromHouseNumber(String houseNumber) {
    final trimmed = houseNumber.trim();
    final match = RegExp(r'^([A-Za-z]+)\s*[-/]\s*\d+').firstMatch(trimmed);
    if (match != null) {
      return 'Block ${match.group(1)!.toUpperCase()}';
    }
    return '';
  }

  /// Determines whether the customer's paper delivery is active (started) on [date].
  /// Supports both manual indefinite pause and scheduled date-range pause.
  bool isStartedOnDate(DateTime date) {
    if (status == DeliveryStatus.started) {
      return true;
    }
    if (pauseStartDate == null && pauseEndDate == null) {
      return false; // Indefinitely paused until manually started
    }
    final target = dateOnly(date);
    final start = pauseStartDate != null ? dateOnly(pauseStartDate!) : null;
    final end = pauseEndDate != null ? dateOnly(pauseEndDate!) : null;

    if (start != null && target.isBefore(start)) {
      return true; // Pause hasn't started yet
    }
    if (end != null && target.isAfter(end)) {
      return true; // Pause period has ended (auto-started)
    }
    return false; // Currently within paused date window
  }

  /// Returns all subscription items that should be delivered on [date],
  /// accounting for customer pause status, individual paper pause, and weekday/weekend variant.
  List<SubscriptionItem> deliverableSubscriptionsOnDate(DateTime date) {
    if (!isStartedOnDate(date)) return const [];
    return subscriptions
        .where((sub) => sub.isDeliverableOnDate(date))
        .toList();
  }

  int totalCopiesOnDate(DateTime date) {
    return deliverableSubscriptionsOnDate(date)
        .fold<int>(0, (sum, item) => sum + item.quantity);
  }

  bool isDeliveredOnDate(DateTime date) {
    return deliveredDates.contains(dateKey(date));
  }

  Customer copyWith({
    String? id,
    int? sequenceNo,
    String? name,
    String? houseNumber,
    String? block,
    String? area,
    String? phone,
    DeliveryStatus? status,
    DateTime? pauseStartDate,
    bool clearPauseStartDate = false,
    DateTime? pauseEndDate,
    bool clearPauseEndDate = false,
    String? pauseReason,
    List<SubscriptionItem>? subscriptions,
    List<String>? deliveredDates,
    List<StatusLog>? statusHistory,
    String? notes,
  }) {
    return Customer(
      id: id ?? this.id,
      sequenceNo: sequenceNo ?? this.sequenceNo,
      name: name ?? this.name,
      houseNumber: houseNumber ?? this.houseNumber,
      block: block ?? this.block,
      area: area ?? this.area,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      pauseStartDate:
          clearPauseStartDate ? null : (pauseStartDate ?? this.pauseStartDate),
      pauseEndDate:
          clearPauseEndDate ? null : (pauseEndDate ?? this.pauseEndDate),
      pauseReason: pauseReason ?? this.pauseReason,
      subscriptions: subscriptions ?? this.subscriptions,
      deliveredDates: deliveredDates ?? this.deliveredDates,
      statusHistory: statusHistory ?? this.statusHistory,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sequenceNo': sequenceNo,
      'name': name,
      'houseNumber': houseNumber,
      'block': block,
      'area': area,
      'phone': phone,
      'status': status.name,
      'pauseStartDate': pauseStartDate?.toIso8601String(),
      'pauseEndDate': pauseEndDate?.toIso8601String(),
      'pauseReason': pauseReason,
      'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
      'deliveredDates': deliveredDates,
      'statusHistory': statusHistory.map((h) => h.toJson()).toList(),
      'notes': notes,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    final houseNo = json['houseNumber'] as String? ?? '';
    final rawBlock = (json['block'] as String? ?? '').trim();
    return Customer(
      id: json['id'] as String,
      sequenceNo: (json['sequenceNo'] as num?)?.toInt() ?? 1,
      name: json['name'] as String? ?? '',
      houseNumber: houseNo,
      block: rawBlock.isNotEmpty
          ? rawBlock
          : inferBlockFromHouseNumber(houseNo),
      area: json['area'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DeliveryStatus.started,
      ),
      pauseStartDate: json['pauseStartDate'] != null
          ? DateTime.tryParse(json['pauseStartDate'] as String)
          : null,
      pauseEndDate: json['pauseEndDate'] != null
          ? DateTime.tryParse(json['pauseEndDate'] as String)
          : null,
      pauseReason: json['pauseReason'] as String? ?? '',
      subscriptions: (json['subscriptions'] as List<dynamic>? ?? [])
          .map((e) => SubscriptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      deliveredDates: (json['deliveredDates'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      statusHistory: (json['statusHistory'] as List<dynamic>? ?? [])
          .map((e) => StatusLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String? ?? '',
    );
  }
}
