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
    this.isActive = true,
    this.vehicleNumber = '',
    this.notes = '',
  });

  bool get isOwner => role == UserRole.owner;
  bool get isDeliveryBoy => role == UserRole.deliveryBoy;

  String get roleLabel => isOwner ? 'Owner (Admin)' : 'Delivery Boy';
  String get roleLabelHi => isOwner ? 'मालिक (एडमिन)' : 'हॉकर (डिलीवरी बॉय)';

  AppUser copyWith({
    String? id,
    String? name,
    UserRole? role,
    String? pin,
    String? phone,
    String? assignedArea,
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
        'isActive': isActive,
        'vehicleNumber': vehicleNumber,
        'notes': notes,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? 'user_owner',
      name: json['name'] as String? ?? 'D K Rai',
      role: (json['role'] as String?) == 'deliveryBoy'
          ? UserRole.deliveryBoy
          : UserRole.owner,
      pin: json['pin'] as String? ?? '1234',
      phone: json['phone'] as String? ?? '',
      assignedArea: json['assignedArea'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      vehicleNumber: json['vehicleNumber'] as String? ?? '',
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
          isActive: true,
        ),
        AppUser(
          id: 'user_delivery',
          name: 'Ramesh (Delivery Boy)',
          role: UserRole.deliveryBoy,
          pin: '0000',
          phone: '9123456780',
          assignedArea: 'Block A, Shanti Nagar Society',
          isActive: true,
          vehicleNumber: 'Hero Splendor (UP 65 AB 1234)',
          notes: 'Morning route: 5:30 AM - 7:00 AM',
        ),
      ];
}
