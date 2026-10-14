import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newspaper_delivery_app/models/app_user.dart';
import 'package:newspaper_delivery_app/providers/delivery_provider.dart';
import 'package:newspaper_delivery_app/screens/delivery_boys_screen.dart';
import 'package:newspaper_delivery_app/services/local_storage_service.dart';

void main() {
  group('Delivery Boys Management Unit Tests', () {
    late LocalStorageService storage;
    late DeliveryProvider provider;

    setUp(() async {
      storage = await LocalStorageService.init(inMemoryForTests: true);
      provider = DeliveryProvider(storage);
    });

    test('Initial delivery boys list contains default delivery boy', () {
      final boys = provider.deliveryBoys;
      expect(boys.length, 1);
      expect(boys.first.name, contains('Ramesh'));
      expect(boys.first.role, UserRole.deliveryBoy);
      expect(boys.first.isActive, true);
    });

    test('Admin can create a new delivery boy', () async {
      final newBoy = AppUser(
        id: 'user_delivery_test_1',
        name: 'Suresh Kumar',
        role: UserRole.deliveryBoy,
        pin: '5566',
        phone: '9876501234',
        assignedArea: 'Block B, Green Park Colony',
        vehicleNumber: 'Hero Splendor (UP 65 X 9999)',
        notes: 'Morning shift 5:30 AM',
        isActive: true,
      );

      await provider.saveDeliveryBoy(newBoy);

      expect(provider.deliveryBoys.length, 2);
      final found = provider.deliveryBoys.firstWhere((b) => b.id == newBoy.id);
      expect(found.name, 'Suresh Kumar');
      expect(found.pin, '5566');
      expect(found.phone, '9876501234');
      expect(found.assignedArea, 'Block B, Green Park Colony');
      expect(found.vehicleNumber, 'Hero Splendor (UP 65 X 9999)');
    });

    test('Admin can update existing delivery boy details', () async {
      final defaultBoy = provider.deliveryBoys.first;
      final updatedBoy = defaultBoy.copyWith(
        name: 'Ramesh Sharma (Promoted)',
        phone: '9998887776',
        pin: '4321',
        assignedArea: 'Block A + Block C, Sunrise Society',
      );

      await provider.saveDeliveryBoy(updatedBoy);

      final found = provider.deliveryBoys.firstWhere((b) => b.id == defaultBoy.id);
      expect(found.name, 'Ramesh Sharma (Promoted)');
      expect(found.phone, '9998887776');
      expect(found.pin, '4321');
      expect(found.assignedArea, 'Block A + Block C, Sunrise Society');
    });

    test('Admin can toggle delivery boy active/inactive status', () async {
      final defaultBoy = provider.deliveryBoys.first;
      expect(defaultBoy.isActive, true);

      // Deactivate
      await provider.toggleDeliveryBoyActive(defaultBoy.id);
      var found = provider.deliveryBoys.firstWhere((b) => b.id == defaultBoy.id);
      expect(found.isActive, false);

      // Inactive delivery boy cannot log in
      final loginSuccess = await provider.login(found.id, found.pin);
      expect(loginSuccess, false);

      // Reactivate
      await provider.toggleDeliveryBoyActive(defaultBoy.id);
      found = provider.deliveryBoys.firstWhere((b) => b.id == defaultBoy.id);
      expect(found.isActive, true);

      // Active delivery boy can now log in
      final loginSuccessAfterReactivate =
          await provider.login(found.id, found.pin);
      expect(loginSuccessAfterReactivate, true);
    });

    test('Admin can delete a delivery boy, but cannot delete Owner', () async {
      final newBoy = AppUser(
        id: 'user_delivery_temp',
        name: 'Temporary Boy',
        role: UserRole.deliveryBoy,
        pin: '9999',
        phone: '9000000000',
      );
      await provider.saveDeliveryBoy(newBoy);
      expect(provider.deliveryBoys.any((b) => b.id == newBoy.id), true);

      // Delete delivery boy
      final deleted = await provider.deleteDeliveryBoy(newBoy.id);
      expect(deleted, true);
      expect(provider.deliveryBoys.any((b) => b.id == newBoy.id), false);

      // Attempt to delete Owner should fail
      final owner = provider.allUsers.firstWhere((u) => u.isOwner);
      final ownerDeleted = await provider.deleteDeliveryBoy(owner.id);
      expect(ownerDeleted, false);
      expect(provider.allUsers.any((u) => u.id == owner.id), true);
    });
  });

  group('DeliveryBoysScreen UI Widget Tests', () {
    late LocalStorageService storage;
    late DeliveryProvider provider;

    setUp(() async {
      storage = await LocalStorageService.init(inMemoryForTests: true);
      provider = DeliveryProvider(storage);
    });

    testWidgets('DeliveryBoysScreen renders list, summary metrics, and FAB',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryBoysScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Delivery Boys Management'), findsOneWidget);

      // Verify default delivery boy "Ramesh" is rendered
      expect(find.textContaining('Ramesh'), findsOneWidget);

      // Verify FAB to add delivery boy is present
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Tap FAB to open create sheet
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify Add New Delivery Boy form is opened
      expect(find.text('Add New Delivery Boy'), findsAtLeastNWidgets(1));
      expect(find.text('Delivery Boy Name'), findsOneWidget);
      expect(find.text('Mobile / Phone Number'), findsOneWidget);
    });
  });
}
