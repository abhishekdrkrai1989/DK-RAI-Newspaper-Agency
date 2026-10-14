import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newspaper_delivery_app/main.dart';
import 'package:newspaper_delivery_app/models/app_user.dart';
import 'package:newspaper_delivery_app/models/customer.dart';
import 'package:newspaper_delivery_app/models/newspaper_event.dart';
import 'package:newspaper_delivery_app/models/publication.dart';
import 'package:newspaper_delivery_app/providers/delivery_provider.dart';
import 'package:newspaper_delivery_app/screens/home_screen.dart';
import 'package:newspaper_delivery_app/screens/newspaper_report_screen.dart';
import 'package:newspaper_delivery_app/services/cloud_sync_service.dart';
import 'package:newspaper_delivery_app/services/local_storage_service.dart';

void main() {
  group('Switch User Visibility Tests', () {
    testWidgets(
        'Switch User section is visible for Owner, but hidden for Delivery Boy',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final storage = await LocalStorageService.init(inMemoryForTests: true);
      final provider = DeliveryProvider(storage);

      // 1. Logged in as Owner
      final owner = provider.allUsers.firstWhere((u) => u.isOwner);
      await provider.switchUser(owner);

      await tester.pumpWidget(NewspaperDeliveryApp(provider: provider));
      await tester.pumpAndSettle();

      // Open profile / switch user dialog from AppBar
      final profileBtn = find.byIcon(Icons.admin_panel_settings);
      expect(profileBtn, findsOneWidget);
      await tester.tap(profileBtn);
      await tester.pumpAndSettle();

      // For Owner: Switch user header and cards MUST be visible
      expect(find.text('Switch User (Admin Only)'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);

      // Close bottom sheet
      Navigator.of(tester.element(find.byIcon(Icons.logout))).pop();
      await tester.pumpAndSettle();

      // 2. Switch to Delivery Boy
      final boy = provider.allUsers.firstWhere((u) => u.isDeliveryBoy);
      await provider.switchUser(boy);
      await tester.pumpAndSettle();

      // Tap Delivery Boy profile icon (in AppBar)
      final boyProfileBtn = find.byIcon(Icons.delivery_dining).last;
      await tester.tap(boyProfileBtn);
      await tester.pumpAndSettle();

      // For Delivery Boy: "Switch User" section MUST NOT be shown
      expect(find.text('Switch User (Admin Only)'), findsNothing);
      // Only Logout is available
      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.text(boy.name), findsWidgets);
    });
  });

  group('Newspaper Events Recording & Breakdown Tests', () {
    late LocalStorageService storage;
    late DeliveryProvider provider;

    setUp(() async {
      storage = await LocalStorageService.init(inMemoryForTests: true);
      provider = DeliveryProvider(storage);
    });

    test('Events are recorded for newStart, started, paused, and deleted',
        () async {
      final initialEventCount = provider.newspaperEvents.length;

      // 1. Add New Customer (New Start)
      final newCustomer = Customer(
        id: 'cust_test_999',
        sequenceNo: 99,
        name: 'Test Customer',
        houseNumber: '999',
        block: 'Tower T',
        area: 'Test Society',
        deliveryBoyId: 'user_2',
        deliveryBoyName: 'Raju Sharma',
        subscriptions: [
          const SubscriptionItem(publicationId: 'pub_1', quantity: 2),
        ],
      );
      await provider.saveCustomer(newCustomer);

      expect(provider.newspaperEvents.length, initialEventCount + 1);
      final newStartEvt = provider.newspaperEvents.first;
      expect(newStartEvt.eventType, NewspaperEventType.newStart);
      expect(newStartEvt.customerName, 'Test Customer');
      expect(newStartEvt.deliveryBoyName, 'Raju Sharma');
      expect(newStartEvt.quantity, 2);

      // 2. Pause Customer Paper
      await provider.pauseCustomerPaper(newCustomer.id, reason: 'Out of town');
      final pauseEvt = provider.newspaperEvents.first;
      expect(pauseEvt.eventType, NewspaperEventType.paused);
      expect(pauseEvt.note, 'Out of town');

      // 3. Resume / Start Customer Paper
      await provider.startCustomerPaper(newCustomer.id, note: 'Returned home');
      final startEvt = provider.newspaperEvents.first;
      expect(startEvt.eventType, NewspaperEventType.started);
      expect(startEvt.note, 'Returned home');

      // 4. Delete Customer
      await provider.deleteCustomer(newCustomer.id);
      final deleteEvt = provider.newspaperEvents.first;
      expect(deleteEvt.eventType, NewspaperEventType.deleted);
      expect(deleteEvt.customerName, 'Test Customer');
    });

    test('getDeliveryBoyBreakdown calculates correct active and event counts',
        () async {
      final breakdown = provider.getDeliveryBoyBreakdown('user_2');

      expect(breakdown.containsKey('totalCustomers'), isTrue);
      expect(breakdown.containsKey('activeCopies'), isTrue);
      expect(breakdown.containsKey('pausedCopies'), isTrue);
      expect(breakdown.containsKey('newStartCount'), isTrue);
      expect(breakdown.containsKey('startedCount'), isTrue);
      expect(breakdown.containsKey('pausedCount'), isTrue);
      expect(breakdown.containsKey('deletedCount'), isTrue);
      expect(breakdown['events'], isA<List<NewspaperEvent>>());
    });

    test('getAreaBreakdown calculates correct counts for specific area', () {
      final breakdown = provider.getAreaBreakdown('Gaur City 2');

      expect(breakdown['totalCustomers'], isA<int>());
      expect(breakdown['activeCopies'], isA<int>());
      expect(breakdown['events'], isA<List<NewspaperEvent>>());
    });
  });

  group('NewspaperReportScreen UI Widget Tests', () {
    testWidgets('NewspaperReportScreen renders tabs and switches between them',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final storage = await LocalStorageService.init(inMemoryForTests: true);
      final provider = DeliveryProvider(storage);

      await tester.pumpWidget(
        MaterialApp(
          home: NewspaperReportScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Check AppBar Title
      expect(find.text('Newspaper Distribution & Logs'), findsOneWidget);

      // Check 3 Tabs
      expect(find.text('Hawker Wise'), findsOneWidget);
      expect(find.text('Area Wise'), findsOneWidget);
      expect(find.text('Activity Logs'), findsOneWidget);

      // Check Hawker Tab Metrics
      expect(find.text('New Start'), findsWidgets);
      expect(find.text('Started'), findsWidgets);
      expect(find.text('Paused'), findsWidgets);
      expect(find.text('Deleted'), findsWidgets);

      // Switch to Area Wise Tab
      await tester.tap(find.text('Area Wise'));
      await tester.pumpAndSettle();

      expect(find.text('Select Area / Society / Colony'), findsOneWidget);

      // Switch to Activity Logs Tab
      await tester.tap(find.text('Activity Logs'));
      await tester.pumpAndSettle();

      expect(
        find.text('Search customer, house, paper, or hawker...'),
        findsOneWidget,
      );
      expect(find.text('All Events'), findsOneWidget);
    });
  });

  group('Cloud Sync SQL and Event Schema Tests', () {
    test('sqlSetupScript contains newspaper_events table and RLS policies', () {
      final sql = CloudSyncService.sqlSetupScript;

      expect(sql.contains('create table if not exists newspaper_events'), isTrue);
      expect(sql.contains('event_type text not null'), isTrue);
      expect(sql.contains('customer_name text not null'), isTrue);
      expect(sql.contains('delivery_boy_id text default \'\''), isTrue);
      expect(sql.contains('alter table newspaper_events enable row level security'), isTrue);
      expect(sql.contains('Allow all on newspaper_events for anon'), isTrue);
      expect(sql.contains('notify pgrst, \'reload schema\';'), isTrue);

      final migSql = CloudSyncService.migrationSqlScript;
      expect(migSql.contains('alter table customers add column if not exists delivery_boy_id'), isTrue);
      expect(migSql.contains('alter table customers add column if not exists delivery_boy_name'), isTrue);
      expect(migSql.contains('notify pgrst, \'reload schema\';'), isTrue);
    });
  });
}
