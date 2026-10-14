import '../l10n/app_strings.dart';

enum PublicationType {
  newspaper,
  magazine,
}

enum DeliveryFrequency {
  daily,
  weekdaysOnly,
  weekendsOnly,
  sundayOnly,
  saturdayOnly,
}

extension DeliveryFrequencyX on DeliveryFrequency {
  bool matchesDate(DateTime date) {
    final wd = date.weekday; // 1 = Mon ... 6 = Sat, 7 = Sun
    switch (this) {
      case DeliveryFrequency.daily:
        return true;
      case DeliveryFrequency.weekdaysOnly:
        return wd >= DateTime.monday && wd <= DateTime.friday;
      case DeliveryFrequency.weekendsOnly:
        return wd == DateTime.saturday || wd == DateTime.sunday;
      case DeliveryFrequency.sundayOnly:
        return wd == DateTime.sunday;
      case DeliveryFrequency.saturdayOnly:
        return wd == DateTime.saturday;
    }
  }

  String label(AppStrings s) {
    switch (this) {
      case DeliveryFrequency.daily:
        return s.freqDaily;
      case DeliveryFrequency.weekdaysOnly:
        return s.freqWeekdays;
      case DeliveryFrequency.weekendsOnly:
        return s.freqWeekends;
      case DeliveryFrequency.sundayOnly:
        return s.freqSundayOnly;
      case DeliveryFrequency.saturdayOnly:
        return s.freqSaturdayOnly;
    }
  }

  String shortLabel(AppStrings s) {
    switch (this) {
      case DeliveryFrequency.daily:
        return s.freqDailyShort;
      case DeliveryFrequency.weekdaysOnly:
        return s.freqWeekdaysShort;
      case DeliveryFrequency.weekendsOnly:
        return s.freqWeekendsShort;
      case DeliveryFrequency.sundayOnly:
        return s.freqSundayShort;
      case DeliveryFrequency.saturdayOnly:
        return s.freqSaturdayShort;
    }
  }
}

class Publication {
  final String id;
  final String nameEn;
  final String nameHi;
  final PublicationType type;
  final DeliveryFrequency defaultFrequency;
  final double weekdayPrice;
  final double weekendPrice;

  const Publication({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.type,
    this.defaultFrequency = DeliveryFrequency.daily,
    required this.weekdayPrice,
    required this.weekendPrice,
  });

  String displayName(AppStrings s) =>
      s.isHindi && nameHi.trim().isNotEmpty ? nameHi : nameEn;

  double priceForDate(DateTime date) {
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    return isWeekend ? weekendPrice : weekdayPrice;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameHi': nameHi,
      'type': type.name,
      'defaultFrequency': defaultFrequency.name,
      'weekdayPrice': weekdayPrice,
      'weekendPrice': weekendPrice,
    };
  }

  factory Publication.fromJson(Map<String, dynamic> json) {
    return Publication(
      id: json['id'] as String,
      nameEn: json['nameEn'] as String? ?? '',
      nameHi: json['nameHi'] as String? ?? '',
      type: PublicationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PublicationType.newspaper,
      ),
      defaultFrequency: DeliveryFrequency.values.firstWhere(
        (e) => e.name == json['defaultFrequency'],
        orElse: () => DeliveryFrequency.daily,
      ),
      weekdayPrice: (json['weekdayPrice'] as num?)?.toDouble() ?? 5.0,
      weekendPrice: (json['weekendPrice'] as num?)?.toDouble() ?? 7.0,
    );
  }
}

class SubscriptionItem {
  final String publicationId;
  final DeliveryFrequency frequency;
  final int quantity;
  final bool isPaused;

  const SubscriptionItem({
    required this.publicationId,
    this.frequency = DeliveryFrequency.daily,
    this.quantity = 1,
    this.isPaused = false,
  });

  SubscriptionItem copyWith({
    String? publicationId,
    DeliveryFrequency? frequency,
    int? quantity,
    bool? isPaused,
  }) {
    return SubscriptionItem(
      publicationId: publicationId ?? this.publicationId,
      frequency: frequency ?? this.frequency,
      quantity: quantity ?? this.quantity,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  bool isDeliverableOnDate(DateTime date) {
    if (isPaused) return false;
    return frequency.matchesDate(date);
  }

  Map<String, dynamic> toJson() {
    return {
      'publicationId': publicationId,
      'frequency': frequency.name,
      'quantity': quantity,
      'isPaused': isPaused,
    };
  }

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionItem(
      publicationId: json['publicationId'] as String,
      frequency: DeliveryFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => DeliveryFrequency.daily,
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      isPaused: json['isPaused'] as bool? ?? false,
    );
  }
}
