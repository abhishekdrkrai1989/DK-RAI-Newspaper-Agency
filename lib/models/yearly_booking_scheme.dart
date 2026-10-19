class YearlyBookingScheme {
  final String id;
  final String name;
  final double price;
  final String description;
  final bool isActive;
  final DateTime updatedAt;

  const YearlyBookingScheme({
    required this.id,
    required this.name,
    this.price = 0.0,
    this.description = '',
    this.isActive = true,
    required this.updatedAt,
  });

  YearlyBookingScheme copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return YearlyBookingScheme(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'description': description,
        'isActive': isActive,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory YearlyBookingScheme.fromJson(Map<String, dynamic> json) =>
      YearlyBookingScheme.fromRow(json);

  Map<String, dynamic> toRow() => {
        'id': id,
        'name': name,
        'price': price,
        'description': description,
        'is_active': isActive,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory YearlyBookingScheme.fromRow(Map<String, dynamic> row) {
    final id = (row['id'] as String?) ?? '';
    final name = (row['name'] as String?) ?? '';
    final price = (row['price'] as num?)?.toDouble() ?? 0.0;
    final description = (row['description'] as String?) ?? '';
    final isActive = (row['is_active'] as bool?) ??
        (row['isActive'] as bool?) ??
        true;
    final updatedStr = (row['updated_at'] as String?) ??
        (row['updatedAt'] as String?);
    final updatedAt = updatedStr != null
        ? DateTime.tryParse(updatedStr) ?? DateTime.now()
        : DateTime.now();

    return YearlyBookingScheme(
      id: id,
      name: name,
      price: price,
      description: description,
      isActive: isActive,
      updatedAt: updatedAt,
    );
  }

  /// Default predefined schemes based on yearly newspaper subscription offers
  static List<YearlyBookingScheme> defaultSchemes() {
    final now = DateTime.now();
    const schemeNames = [
      'Hindustan Times',
      'Hindustan',
      'Hindustan Times+Hindustan',
      'Mint',
      'Hindustan Times+Mint',
      'Times Of India',
      'Navbharat Times',
      'Economic Times',
      'Times Of India+Navbharat Times',
      'Times of India+Economic Times',
      'Amar Ujala',
      'Dainik Jagran',
      'Indian Express',
    ];

    return schemeNames.asMap().entries.map((entry) {
      final index = entry.key;
      final name = entry.value;
      final slug = name
          .toLowerCase()
          .replaceAll('+', '_plus_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
          .replaceAll(RegExp(r'_+'), '_');

      return YearlyBookingScheme(
        id: 'scheme_${index + 1}_$slug',
        name: name,
        price: 0.0,
        description: 'Yearly Scheme for $name',
        isActive: true,
        updatedAt: now,
      );
    }).toList();
  }
}
