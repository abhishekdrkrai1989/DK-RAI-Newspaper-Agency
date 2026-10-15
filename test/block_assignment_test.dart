import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newspaper_delivery_app/main.dart';
import 'package:newspaper_delivery_app/models/app_user.dart';
import 'package:newspaper_delivery_app/models/customer.dart';
import 'package:newspaper_delivery_app/models/publication.dart';
import 'package:newspaper_delivery_app/providers/delivery_provider.dart';
import 'package:newspaper_delivery_app/screens/home_screen.dart';
import 'package:newspaper_delivery_app/screens/manage_blocks_screen.dart';
import 'package:newspaper_delivery_app/services/local_storage_service.dart';

void main() {
  group('Block Assignment & Access Restriction Tests', () {
    late LocalStorageService storage;
    late DeliveryProvider provider;

    setUp(() async {
      storage = await LocalStorageService.init(inMemoryForTests: true);
      provider = DeliveryProvider(storage);

      // Create test customers across Block A and Block B
      final custA = Customer(
        id: 'cust_a1',
        sequenceNo: 1,
        name: 'Amit Kumar',
        houseNumber: 'A-101',
        block: 'Block A',
        area: 'Shanti Nagar',
        status: DeliveryStatus.started,
        subscriptions: const [
          SubscriptionItem(
            publicationId: 'pub_dainik_jagran',
            frequency: DeliveryFrequency.daily,
            quantity: 1,
          ),
        ],
      );

      final custB = Customer(
        id: 'cust_b1',
        sequenceNo: 2,
        name: 'Brijesh Singh',
        houseNumber: 'B-201',
        block: 'Block B',
        area: 'Shanti Nagar',
        status: DeliveryStatus.started,
        subscriptions: const [
          SubscriptionItem(
            publicationId: 'pub_times_of_india',
            frequency: DeliveryFrequency.daily,
            quantity: 1,
          ),
        ],
      );

      // Save as owner initially
      final owner = provider.allUsers.firstWhere((u) => u.isOwner);
      await provider.switchUser(owner);
      await provider.saveCustomer(custA);
      await provider.saveCustomer(custB);
    });

    test('Owner can see all customers across all blocks', () {
      final owner = provider.allUsers.firstWhere((u) => u.isOwner);
      provider.switchUser(owner);

      expect(provider.isOwner, isTrue);
      expect(provider.allCustomers.length >= 2, isTrue);
      expect(provider.allCustomers.any((c) => c.id == 'cust_a1'), isTrue);
      expect(provider.allCustomers.any((c) => c.id == 'cust_b1'), isTrue);
    });

    test('Delivery boy can ONLY see customers in their assigned block', () async {
      final boy = provider.allUsers.firstWhere((u) => u.isDeliveryBoy);
      // Ensure boy is assigned only Block A
      final boyWithBlockA = boy.copyWith(assignedBlocks: ['Block A']);
      await provider.saveDeliveryBoy(boyWithBlockA);
      await provider.switchUser(boyWithBlockA);

      expect(provider.isDeliveryBoy, isTrue);
      expect(provider.currentUser?.assignedBlocks, ['Block A']);

      // Visible customer list is strictly scoped to Block A
      final visible = provider.allCustomers;
      expect(visible.isNotEmpty, isTrue);
      expect(visible.every((c) => c.block.trim().toLowerCase() == 'block a'),
          isTrue);
      expect(visible.any((c) => c.id == 'cust_a1'), isTrue);

      // Block B customer is NOT visible
      expect(visible.any((c) => c.id == 'cust_b1'), isFalse);
      expect(visible.any((c) => c.block.trim().toLowerCase() == 'block b'),
          isFalse);

      // Available blocks for delivery boy only includes Block A
      expect(provider.availableBlocks, ['Block A']);
      expect(provider.allUniqueBlocks, ['Block A']);

      // Block counts are scoped
      expect(provider.countForBlock('Block A') > 0, isTrue);
      expect(provider.countForBlock('Block B'), 0);
    });

    test('Delivery boy CANNOT add customer to another block', () async {
      final boy = provider.allUsers.firstWhere((u) => u.isDeliveryBoy);
      final boyWithBlockA = boy.copyWith(assignedBlocks: ['Block A']);
      await provider.saveDeliveryBoy(boyWithBlockA);
      await provider.switchUser(boyWithBlockA);

      final custUnauthorized = Customer(
        id: 'cust_b2',
        sequenceNo: 3,
        name: 'Unauthorized User',
        houseNumber: 'B-202',
        block: 'Block B',
        area: 'Shanti Nagar',
        status: DeliveryStatus.started,
        subscriptions: const [
          SubscriptionItem(
            publicationId: 'pub_dainik_jagran',
            frequency: DeliveryFrequency.daily,
            quantity: 1,
          ),
        ],
      );

      final success = await provider.saveCustomer(custUnauthorized);
      expect(success, isFalse);

      // Customer must not be added to provider._customers
      expect(provider.adminAllCustomers.any((c) => c.id == 'cust_b2'), isFalse);
    });

    test('Delivery boy CAN add customer to their assigned block', () async {
      final boy = provider.allUsers.firstWhere((u) => u.isDeliveryBoy);
      final boyWithBlockA = boy.copyWith(assignedBlocks: ['Block A']);
      await provider.saveDeliveryBoy(boyWithBlockA);
      await provider.switchUser(boyWithBlockA);

      final custAuthorized = Customer(
        id: 'cust_a2',
        sequenceNo: 3,
        name: 'Authorized New User',
        houseNumber: 'A-102',
        block: 'Block A',
        area: 'Shanti Nagar',
        status: DeliveryStatus.started,
        subscriptions: const [
          SubscriptionItem(
            publicationId: 'pub_dainik_jagran',
            frequency: DeliveryFrequency.daily,
            quantity: 1,
          ),
        ],
      );

      final success = await provider.saveCustomer(custAuthorized);
      expect(success, isTrue);

      expect(provider.allCustomers.any((c) => c.id == 'cust_a2'), isTrue);
    });

    test('Delivery boy CANNOT edit or delete customer in another block', () async {
      final boy = provider.allUsers.firstWhere((u) => u.isDeliveryBoy);
      final boyWithBlockA = boy.copyWith(assignedBlocks: ['Block A']);
      await provider.saveDeliveryBoy(boyWithBlockA);
      await provider.switchUser(boyWithBlockA);

      // Attempt to edit Block B customer
      final modifiedB = Customer(
        id: 'cust_b1',
        sequenceNo: 2,
        name: 'Hacked Brijesh Singh',
        houseNumber: 'B-201',
        block: 'Block B',
        area: 'Shanti Nagar',
        status: DeliveryStatus.started,
        subscriptions: const [
          SubscriptionItem(
            publicationId: 'pub_times_of_india',
            frequency: DeliveryFrequency.daily,
            quantity: 1,
          ),
        ],
      );

      final editSuccess = await provider.saveCustomer(modifiedB);
      expect(editSuccess, isFalse);

      // Attempt to delete Block B customer
      final deleteSuccess = await provider.deleteCustomer('cust_b1');
      expect(deleteSuccess, isFalse);

      // Customer should still exist in admin list with original name
      expect(
          provider.adminAllCustomers
              .firstWhere((c) => c.id == 'cust_b1')
              .name,
          'Brijesh Singh');
    });

    test('Delivery boy CANNOT start or pause paper for another block', () async {
      final boy = provider.allUsers.firstWhere((u) => u.isDeliveryBoy);
      final boyWithBlockA = boy.copyWith(assignedBlocks: ['Block A']);
      await provider.saveDeliveryBoy(boyWithBlockA);
      await provider.switchUser(boyWithBlockA);

      // cust_b1 is in Block B
      await provider.pauseCustomerPaper('cust_b1', reason: 'Vacation');
      final target =
          provider.adminAllCustomers.firstWhere((c) => c.id == 'cust_b1');
      expect(target.status, DeliveryStatus.started); // Did not pause!

      await provider.toggleSubscriptionItemPause(
          'cust_b1', 'pub_times_of_india');
      expect(target.subscriptions.first.isPaused, isFalse); // Did not pause sub!
    });

    test('Admin can manage blocks: add, assign, unassign, and delete', () async {
      final owner = provider.allUsers.firstWhere((u) => u.isOwner);
      await provider.switchUser(owner);

      // 1. Add new custom block (Tower 9)
      await provider.addCustomBlock('Tower 9');
      expect(provider.allManagedBlocks, contains('Tower 9'));

      // 2. Assign Tower 9 to delivery boy
      final boy = provider.allUsers.firstWhere((u) => u.isDeliveryBoy);
      await provider.assignBlockToDeliveryBoy('Tower 9', boy.id);

      final updatedBoy = provider.allUsers.firstWhere((u) => u.id == boy.id);
      expect(updatedBoy.assignedBlocks, contains('Tower 9'));

      // 3. Unassign Tower 9
      await provider.unassignBlock('Tower 9');
      final unassignedBoy =
          provider.allUsers.firstWhere((u) => u.id == boy.id);
      expect(unassignedBoy.assignedBlocks.contains('Tower 9'), isFalse);

      // 4. Remove custom block Tower 9
      await provider.removeCustomBlock('Tower 9');
      expect(provider.allManagedBlocks.contains('Tower 9'), isFalse);
    });
  });

  group('ManageBlocksScreen & HomeScreen UI Tests', () {
    testWidgets('ManageBlocksScreen renders blocks, metrics and allows adding new block',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final storage = await LocalStorageService.init(inMemoryForTests: true);
      final provider = DeliveryProvider(storage);
      final owner = provider.allUsers.firstWhere((u) => u.isOwner);
      await provider.switchUser(owner);

      await tester.pumpWidget(
        MaterialApp(
          home: ManageBlocksScreen(provider: provider),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Check header and metric cards
      expect(find.text(provider.strings.manageBlocksTitle), findsOneWidget);
      expect(find.text(provider.strings.totalBlocksCount), findsOneWidget);
      expect(find.text(provider.strings.assignedBlocksCount), findsOneWidget);
      expect(find.text(provider.strings.unassignedBlocksCount), findsOneWidget);

      // Check Add Block FAB
      final addBlockBtn = find.text(provider.strings.addNewBlockBtn);
      expect(addBlockBtn, findsOneWidget);

      await tester.tap(addBlockBtn);
      await tester.pumpAndSettle();

      expect(find.text(provider.strings.addNewBlockBtn), findsWidgets);

      // Enter new block name in dialog TextField
      await tester.enterText(find.byType(TextField).last, 'Block D');
      await tester.pumpAndSettle();

      // Tap Save Block button inside dialog
      await tester.tap(find.text('Save Block'));
      await tester.pumpAndSettle();

      expect(provider.allManagedBlocks, contains('Block D'));
      expect(find.text('Block D'), findsOneWidget);
    });

    testWidgets('HomeScreen shows Manage Blocks button and chip for Owner',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final storage = await LocalStorageService.init(inMemoryForTests: true);
      final provider = DeliveryProvider(storage);
      final owner = provider.allUsers.firstWhere((u) => u.isOwner);
      await provider.switchUser(owner);

      await tester.pumpWidget(NewspaperDeliveryApp(provider: provider));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Check Manage Blocks Action Button and chip exist
      expect(find.byIcon(Icons.domain_add), findsWidgets);
      expect(find.textContaining(provider.strings.manageBlocksBtn), findsWidgets);
    });
  });
}
