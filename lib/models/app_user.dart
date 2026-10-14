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

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.pin,
    this.phone = '',
  });

  bool get isOwner => role == UserRole.owner;
  bool get isDeliveryBoy => role == UserRole.deliveryBoy;

  String get roleLabel => isOwner ? 'Owner (Admin)' : 'Delivery Boy';
  String get roleLabelHi => isOwner ? 'मालिक (एडमिन)' : 'हॉकर (डिलीवरी बॉय)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'pin': pin,
        'phone': phone,
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
    );
  }

  static List<AppUser> defaultUsers() => const [
        AppUser(
          id: 'user_owner',
          name: 'D K Rai (Owner)',
          role: UserRole.owner,
          pin: '1234',
          phone: '9876543210',
        ),
        AppUser(
          id: 'user_delivery',
          name: 'Ramesh (Delivery Boy)',
          role: UserRole.deliveryBoy,
          pin: '0000',
          phone: '9123456780',
        ),
      ];
}
