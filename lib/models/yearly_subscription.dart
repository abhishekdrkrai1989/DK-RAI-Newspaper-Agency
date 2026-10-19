enum CouponType {
  mCoupon,
  physicalCoupon;

  String get displayName {
    switch (this) {
      case CouponType.mCoupon:
        return 'M-Coupon';
      case CouponType.physicalCoupon:
        return 'Physical Coupon';
    }
  }

  static CouponType fromString(String? val) {
    if (val == null) return CouponType.physicalCoupon;
    final lower = val.toLowerCase().trim();
    if (lower.contains('m-coupon') ||
        lower.contains('mcoupon') ||
        lower == 'm') {
      return CouponType.mCoupon;
    }
    return CouponType.physicalCoupon;
  }
}

class YearlySubscription {
  final String id;
  final String customerName;
  final String customerId;
  final String address;
  final String phone;
  final String newspaperScheme;
  final DateTime startDate;
  final DateTime endDate;
  final CouponType couponType;
  final String couponCode;
  final bool isGiftApplicable;
  final bool isGiftDelivered;
  final String giftItem;
  final DateTime? giftDeliveredDate;
  final String notes;
  final DateTime updatedAt;

  const YearlySubscription({
    required this.id,
    required this.customerName,
    this.customerId = '',
    required this.address,
    this.phone = '',
    required this.newspaperScheme,
    required this.startDate,
    required this.endDate,
    this.couponType = CouponType.physicalCoupon,
    this.couponCode = '',
    this.isGiftApplicable = false,
    this.isGiftDelivered = false,
    this.giftItem = '',
    this.giftDeliveredDate,
    this.notes = '',
    required this.updatedAt,
  });

  bool get isActive {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !today.isBefore(start) && !today.isAfter(end);
  }

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(today).inDays;
  }

  bool get isExpiringSoon => daysRemaining >= 0 && daysRemaining <= 30;

  bool get isExpired => daysRemaining < 0;

  bool get isGiftPending => isGiftApplicable && !isGiftDelivered;

  YearlySubscription copyWith({
    String? id,
    String? customerName,
    String? customerId,
    String? address,
    String? phone,
    String? newspaperScheme,
    DateTime? startDate,
    DateTime? endDate,
    CouponType? couponType,
    String? couponCode,
    bool? isGiftApplicable,
    bool? isGiftDelivered,
    String? giftItem,
    DateTime? giftDeliveredDate,
    String? notes,
    DateTime? updatedAt,
  }) {
    return YearlySubscription(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      newspaperScheme: newspaperScheme ?? this.newspaperScheme,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      couponType: couponType ?? this.couponType,
      couponCode: couponCode ?? this.couponCode,
      isGiftApplicable: isGiftApplicable ?? this.isGiftApplicable,
      isGiftDelivered: isGiftDelivered ?? this.isGiftDelivered,
      giftItem: giftItem ?? this.giftItem,
      giftDeliveredDate: giftDeliveredDate ?? this.giftDeliveredDate,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'customerId': customerId,
        'address': address,
        'phone': phone,
        'newspaperScheme': newspaperScheme,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'couponType': couponType.name,
        'couponCode': couponCode,
        'isGiftApplicable': isGiftApplicable,
        'isGiftDelivered': isGiftDelivered,
        'giftItem': giftItem,
        'giftDeliveredDate': giftDeliveredDate?.toIso8601String(),
        'notes': notes,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory YearlySubscription.fromJson(Map<String, dynamic> json) =>
      YearlySubscription.fromRow(json);

  Map<String, dynamic> toRow() => {
        'id': id,
        'customer_name': customerName,
        'customer_id': customerId,
        'address': address,
        'phone': phone,
        'newspaper_scheme': newspaperScheme,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'coupon_type': couponType.displayName,
        'coupon_code': couponCode,
        'is_gift_applicable': isGiftApplicable,
        'is_gift_delivered': isGiftDelivered,
        'gift_item': giftItem,
        'gift_delivered_date': giftDeliveredDate?.toIso8601String(),
        'notes': notes,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory YearlySubscription.fromRow(Map<String, dynamic> row) {
    final id = (row['id'] as String?) ?? '';
    final custName = (row['customer_name'] as String?) ??
        (row['customerName'] as String?) ??
        '';
    final custId = (row['customer_id'] as String?) ??
        (row['customerId'] as String?) ??
        '';
    final address = (row['address'] as String?) ?? '';
    final phone = (row['phone'] as String?) ?? '';
    final scheme = (row['newspaper_scheme'] as String?) ??
        (row['newspaperScheme'] as String?) ??
        '';

    final startStr =
        (row['start_date'] as String?) ?? (row['startDate'] as String?);
    final endStr = (row['end_date'] as String?) ?? (row['endDate'] as String?);
    final startDate = startStr != null
        ? DateTime.tryParse(startStr) ?? DateTime.now()
        : DateTime.now();
    final endDate = endStr != null
        ? DateTime.tryParse(endStr) ??
            startDate.add(const Duration(days: 365))
        : startDate.add(const Duration(days: 365));

    final couponStr =
        (row['coupon_type'] as String?) ?? (row['couponType'] as String?);
    final couponType = CouponType.fromString(couponStr);

    final couponCode = (row['coupon_code'] as String?) ??
        (row['couponCode'] as String?) ??
        '';
    final isGiftApplicable = (row['is_gift_applicable'] as bool?) ??
        (row['isGiftApplicable'] as bool?) ??
        false;
    final isGiftDelivered = (row['is_gift_delivered'] as bool?) ??
        (row['isGiftDelivered'] as bool?) ??
        false;
    final giftItem = (row['gift_item'] as String?) ??
        (row['giftItem'] as String?) ??
        '';

    final giftDelivStr = (row['gift_delivered_date'] as String?) ??
        (row['giftDeliveredDate'] as String?);
    final giftDeliveredDate =
        giftDelivStr != null ? DateTime.tryParse(giftDelivStr) : null;

    final notes = (row['notes'] as String?) ?? '';
    final updatedStr = (row['updated_at'] as String?) ??
        (row['updatedAt'] as String?);
    final updatedAt = updatedStr != null
        ? DateTime.tryParse(updatedStr) ?? DateTime.now()
        : DateTime.now();

    return YearlySubscription(
      id: id,
      customerName: custName,
      customerId: custId,
      address: address,
      phone: phone,
      newspaperScheme: scheme,
      startDate: startDate,
      endDate: endDate,
      couponType: couponType,
      couponCode: couponCode,
      isGiftApplicable: isGiftApplicable,
      isGiftDelivered: isGiftDelivered,
      giftItem: giftItem,
      giftDeliveredDate: giftDeliveredDate,
      notes: notes,
      updatedAt: updatedAt,
    );
  }
}
