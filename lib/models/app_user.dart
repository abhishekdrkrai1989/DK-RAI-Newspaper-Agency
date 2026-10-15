enum UserRole {
  owner,
  deliveryBoy,
}

class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String pin;
  final String phone;
  final String assignedArea;
  final List<String> assignedBlocks;
  final bool isActive;
  final String vehicleNumber;
  final String notes;

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.pin,
    this.phone = '',
    this.assignedArea = '',
    this.assignedBlocks = const [],
    this.isActive = true,
    this.vehicleNumber = '',
    this.notes = '',
  });

  bool get isOwner => role == UserRole.owner;
  bool get isDeliveryBoy => role == UserRole.deliveryBoy;

  String get roleLabel => isOwner ? 'Owner (Admin)' : 'Delivery Boy';
  String get roleLabelHi => isOwner ? 'मालिक (एडमिन)' : 'हॉकर (डिलीवरी बॉय)';

  /// Checks if this user has access to view/manage the specified block.
  /// Admin/Owner has unrestricted access to all blocks.
  /// Delivery boy can only access their assigned block(s).
  bool canAccessBlock(String block) {
    if (isOwner) return true;
    final trimmed = block.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    for (final b in assignedBlocks) {
      final bLower = b.trim().toLowerCase();
      if (bLower == lower) return true;
      final bStripped = bLower.replaceAll('block', '').trim();
      final targetStripped = lower.replaceAll('block', '').trim();
      if (bStripped.isNotEmpty && bStripped == targetStripped) return true;
    }
    return false;
  }

  AppUser copyWith({
    String? id,
    String? name,
    UserRole? role,
    String? pin,
    String? phone,
    String? assignedArea,
    List<String>? assignedBlocks,
    bool? isActive,
    String? vehicleNumber,
    String? notes,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      pin: pin ?? this.pin,
      phone: phone ?? this.phone,
      assignedArea: assignedArea ?? this.assignedArea,
      assignedBlocks: assignedBlocks ?? this.assignedBlocks,
      isActive: isActive ?? this.isActive,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'pin': pin,
        'phone': phone,
        'assignedArea': assignedArea,
        'assignedBlocks': assignedBlocks,
        'isActive': isActive,
        'vehicleNumber': vehicleNumber,
        'notes': notes,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final role = (json['role'] as String?) == 'deliveryBoy'
        ? UserRole.deliveryBoy
        : UserRole.owner;
    final assignedArea = (json['assignedArea'] as String?) ??
        (json['assigned_area'] as String?) ??
        '';

    final rawBlocks = json['assignedBlocks'] ?? json['assigned_blocks'];
    List<String> assignedBlocks = const [];
    if (rawBlocks is List) {
      assignedBlocks = rawBlocks
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (rawBlocks is String && rawBlocks.trim().isNotEmpty) {
      assignedBlocks = rawBlocks
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // Fallback: If legacy delivery boy data has empty assignedBlocks, extract block from assignedArea if present
    if (assignedBlocks.isEmpty && role == UserRole.deliveryBoy) {
      if (assignedArea.contains('Block A')) {
        assignedBlocks = const ['Block A'];
      }
    }

    // Ensure assignedArea includes assigned blocks for delivery boys
    String finalAssignedArea = assignedArea;
    if (role == UserRole.deliveryBoy && assignedBlocks.isNotEmpty) {
      if (finalAssignedArea.trim().isEmpty) {
        finalAssignedArea = assignedBlocks.join(', ');
      } else {
        final missing = assignedBlocks.where(
          (b) => !finalAssignedArea.toLowerCase().contains(b.toLowerCase()),
        );
        if (missing.isNotEmpty) {
          finalAssignedArea = '${missing.join(", ")}, $finalAssignedArea';
        }
      }
    }

    return AppUser(
      id: json['id'] as String? ?? 'user_owner',
      name: json['name'] as String? ?? 'D K Rai',
      role: role,
      pin: json['pin'] as String? ?? '1234',
      phone: json['phone'] as String? ?? '',
      assignedArea: finalAssignedArea,
      assignedBlocks: assignedBlocks,
      isActive: json['isActive'] as bool? ??
          json['is_active'] as bool? ??
          true,
      vehicleNumber: (json['vehicleNumber'] as String?) ??
          (json['vehicle_number'] as String?) ??
          '',
      notes: json['notes'] as String? ?? '',
    );
  }

  static List<AppUser> defaultUsers() => const [
        AppUser(
          id: 'user_owner',
          name: 'D K Rai (Owner)',
          role: UserRole.owner,
          pin: '1234',
          phone: '9876543210',
          assignedArea: 'All Societies / सभी क्षेत्र',
          assignedBlocks: [],
          isActive: true,
        ),
        AppUser(
          id: 'user_delivery',
          name: 'Ramesh (Delivery Boy)',
          role: UserRole.deliveryBoy,
          pin: '0000',
          phone: '9123456780',
          assignedArea: 'Block A, Shanti Nagar Society',
          assignedBlocks: ['Block A'],
          isActive: true,
          vehicleNumber: 'Hero Splendor (UP 65 AB 1234)',
          notes: 'Morning route: 5:30 AM - 7:00 AM',
        ),
      ];
}
