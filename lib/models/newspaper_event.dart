import '../l10n/app_strings.dart';

enum NewspaperEventType {
  newStart,
  started,
  paused,
  deleted;

  String label(AppStrings s) {
    switch (this) {
      case NewspaperEventType.newStart:
        return s.isHindi ? 'नया चालू' : 'New Start';
      case NewspaperEventType.started:
        return s.isHindi ? 'चालू' : 'Started';
      case NewspaperEventType.paused:
        return s.isHindi ? 'बंद' : 'Paused';
      case NewspaperEventType.deleted:
        return s.isHindi ? 'हटाया गया' : 'Deleted';
    }
  }

  static NewspaperEventType fromString(String val) {
    switch (val.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_')) {
      case 'newstart':
      case 'new_start':
        return NewspaperEventType.newStart;
      case 'started':
      case 'resumed':
        return NewspaperEventType.started;
      case 'paused':
      case 'stopped':
        return NewspaperEventType.paused;
      case 'deleted':
      case 'removed':
        return NewspaperEventType.deleted;
      default:
        return NewspaperEventType.newStart;
    }
  }
}

class NewspaperEvent {
  final String id;
  final NewspaperEventType eventType;
  final String customerId;
  final String customerName;
  final String houseNumber;
  final String block;
  final String area;
  final String deliveryBoyId;
  final String deliveryBoyName;
  final String newspaperName;
  final String publicationId;
  final int quantity;
  final DateTime timestamp;
  final DateTime? pauseStartDate;
  final DateTime? pauseEndDate;
  final String note;

  const NewspaperEvent({
    required this.id,
    required this.eventType,
    this.customerId = '',
    required this.customerName,
    this.houseNumber = '',
    this.block = '',
    required this.area,
    this.deliveryBoyId = '',
    this.deliveryBoyName = '',
    required this.newspaperName,
    this.publicationId = '',
    this.quantity = 1,
    required this.timestamp,
    this.pauseStartDate,
    this.pauseEndDate,
    this.note = '',
  });

  String eventTypeLabel(AppStrings s) => eventType.label(s);

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventType': eventType.name,
        'customerId': customerId,
        'customerName': customerName,
        'houseNumber': houseNumber,
        'block': block,
        'area': area,
        'deliveryBoyId': deliveryBoyId,
        'deliveryBoyName': deliveryBoyName,
        'newspaperName': newspaperName,
        'publicationId': publicationId,
        'quantity': quantity,
        'timestamp': timestamp.toIso8601String(),
        'pauseStartDate': pauseStartDate?.toIso8601String(),
        'pauseEndDate': pauseEndDate?.toIso8601String(),
        'note': note,
      };

  factory NewspaperEvent.fromJson(Map<String, dynamic> json) {
    return NewspaperEvent(
      id: (json['id'] as String?) ?? '',
      eventType: NewspaperEventType.fromString(
        (json['eventType'] as String?) ?? (json['event_type'] as String?) ?? '',
      ),
      customerId: (json['customerId'] as String?) ??
          (json['customer_id'] as String?) ??
          '',
      customerName: (json['customerName'] as String?) ??
          (json['customer_name'] as String?) ??
          '',
      houseNumber: (json['houseNumber'] as String?) ??
          (json['house_number'] as String?) ??
          '',
      block: (json['block'] as String?) ?? '',
      area: (json['area'] as String?) ?? '',
      deliveryBoyId: (json['deliveryBoyId'] as String?) ??
          (json['delivery_boy_id'] as String?) ??
          '',
      deliveryBoyName: (json['deliveryBoyName'] as String?) ??
          (json['delivery_boy_name'] as String?) ??
          '',
      newspaperName: (json['newspaperName'] as String?) ??
          (json['newspaper_name'] as String?) ??
          '',
      publicationId: (json['publicationId'] as String?) ??
          (json['publication_id'] as String?) ??
          '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      pauseStartDate: json['pauseStartDate'] != null
          ? DateTime.tryParse(json['pauseStartDate'] as String)
          : (json['pause_start_date'] != null
              ? DateTime.tryParse(json['pause_start_date'] as String)
              : null),
      pauseEndDate: json['pauseEndDate'] != null
          ? DateTime.tryParse(json['pauseEndDate'] as String)
          : (json['pause_end_date'] != null
              ? DateTime.tryParse(json['pause_end_date'] as String)
              : null),
      note: (json['note'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'event_type': eventType.name,
        'customer_id': customerId,
        'customer_name': customerName,
        'house_number': houseNumber,
        'block': block,
        'area': area,
        'delivery_boy_id': deliveryBoyId,
        'delivery_boy_name': deliveryBoyName,
        'newspaper_name': newspaperName,
        'publication_id': publicationId,
        'quantity': quantity,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'pause_start_date': pauseStartDate?.toUtc().toIso8601String(),
        'pause_end_date': pauseEndDate?.toUtc().toIso8601String(),
        'note': note,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  factory NewspaperEvent.fromRow(Map<String, dynamic> row) =>
      NewspaperEvent.fromJson(row);

  NewspaperEvent copyWith({
    String? id,
    NewspaperEventType? eventType,
    String? customerId,
    String? customerName,
    String? houseNumber,
    String? block,
    String? area,
    String? deliveryBoyId,
    String? deliveryBoyName,
    String? newspaperName,
    String? publicationId,
    int? quantity,
    DateTime? timestamp,
    DateTime? pauseStartDate,
    DateTime? pauseEndDate,
    String? note,
  }) {
    return NewspaperEvent(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      houseNumber: houseNumber ?? this.houseNumber,
      block: block ?? this.block,
      area: area ?? this.area,
      deliveryBoyId: deliveryBoyId ?? this.deliveryBoyId,
      deliveryBoyName: deliveryBoyName ?? this.deliveryBoyName,
      newspaperName: newspaperName ?? this.newspaperName,
      publicationId: publicationId ?? this.publicationId,
      quantity: quantity ?? this.quantity,
      timestamp: timestamp ?? this.timestamp,
      pauseStartDate: pauseStartDate ?? this.pauseStartDate,
      pauseEndDate: pauseEndDate ?? this.pauseEndDate,
      note: note ?? this.note,
    );
  }
}
