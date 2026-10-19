import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newspaper_delivery_app/models/yearly_booking_scheme.dart';
import 'package:newspaper_delivery_app/models/yearly_subscription.dart';
import 'package:newspaper_delivery_app/providers/delivery_provider.dart';
import 'package:newspaper_delivery_app/screens/yearly_subscriptions_screen.dart';
import 'package:newspaper_delivery_app/services/cloud_sync_service.dart';
import 'package:newspaper_delivery_app/services/local_storage_service.dart';

void main() {
  group('Yearly Schemes & Subscriptions Unit Tests', () {
    test('Default yearly booking schemes contain all 13 specified schemes', () {
      final schemes = YearlyBookingScheme.defaultSchemes();
      expect(schemes.length, 13);

      const expected = [
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

      final names = schemes.map((s) => s.name).toList();
      for (final exp in expected) {
        expect(names.contains(exp), isTrue,
            reason: 'Scheme $exp should be in default schemes');
      }
    });

    test('YearlyBookingScheme toRow and fromRow serialization works accurately', () {
      final scheme = YearlyBookingScheme(
        id: 'scheme_ht_mint',
        name: 'Hindustan Times+Mint',
        price: 1599.0,
        description: 'Yearly combo offer',
        isActive: true,
        updatedAt: DateTime.parse('2026-10-19 12:00:00'),
      );

      final row = scheme.toRow();
      expect(row['id'], 'scheme_ht_mint');
      expect(row['name'], 'Hindustan Times+Mint');
      expect(row['price'], 1599.0);
      expect(row['is_active'], isTrue);

      final parsed = YearlyBookingScheme.fromRow(row);
      expect(parsed.id, scheme.id);
      expect(parsed.name, scheme.name);
      expect(parsed.price, scheme.price);
      expect(parsed.description, scheme.description);
      expect(parsed.isActive, scheme.isActive);
    });

    test('YearlySubscription stores all fields and computes getters correctly', () {
      final now = DateTime.now();
      final sub = YearlySubscription(
        id: 'sub_101',
        customerName: 'Anil Verma',
        customerId: 'cust_1',
        address: 'Flat 402, Block A, Shanti Nagar',
        phone: '9876543210',
        newspaperScheme: 'Hindustan Times+Hindustan',
        startDate: now.subtract(const Duration(days: 100)),
        endDate: now.add(const Duration(days: 265)),
        couponType: CouponType.mCoupon,
        couponCode: 'MC-2026-889',
        isGiftApplicable: true,
        isGiftDelivered: false,
        giftItem: 'Stainless Steel Cooker',
        notes: 'Delivery between 6 AM and 7 AM',
        updatedAt: now,
      );

      expect(sub.customerName, 'Anil Verma');
      expect(sub.address, 'Flat 402, Block A, Shanti Nagar');
      expect(sub.newspaperScheme, 'Hindustan Times+Hindustan');
      expect(sub.couponType, CouponType.mCoupon);
      expect(sub.couponType.displayName, 'M-Coupon');
      expect(sub.isGiftApplicable, isTrue);
      expect(sub.isGiftDelivered, isFalse);
      expect(sub.isGiftPending, isTrue);
      expect(sub.isActive, isTrue);
      expect(sub.isExpired, isFalse);

      final row = sub.toRow();
      expect(row['id'], 'sub_101');
      expect(row['customer_name'], 'Anil Verma');
      expect(row['coupon_type'], 'M-Coupon');
      expect(row['gift_item'], 'Stainless Steel Cooker');
      expect(row['is_gift_applicable'], isTrue);
      expect(row['is_gift_delivered'], isFalse);

      final parsed = YearlySubscription.fromRow(row);
      expect(parsed.id, sub.id);
      expect(parsed.customerName, sub.customerName);
      expect(parsed.address, sub.address);
      expect(parsed.newspaperScheme, sub.newspaperScheme);
      expect(parsed.couponType, CouponType.mCoupon);
      expect(parsed.isGiftApplicable, isTrue);
      expect(parsed.isGiftDelivered, isFalse);
      expect(parsed.giftItem, sub.giftItem);
    });

    test('sqlSetupScript contains yearly_booking_schemes and yearly_subscriptions tables', () {
      final sql = CloudSyncService.sqlSetupScript;
      expect(sql.contains('create table if not exists yearly_booking_schemes'), isTrue);
      expect(sql.contains('create table if not exists yearly_subscriptions'), isTrue);
      expect(sql.contains('Allow all on yearly_booking_schemes for anon'), isTrue);
      expect(sql.contains('Allow all on yearly_subscriptions for anon'), isTrue);
    });
  });

  group('DeliveryProvider Yearly Subscriptions Integration Tests', () {
    late LocalStorageService storage;
    late DeliveryProvider provider;

    setUp(() async {
      storage = await LocalStorageService.init(inMemoryForTests: true);
      provider = DeliveryProvider(storage);
    });

    test('Initializes with default 13 schemes and empty subscriptions', () {
      expect(provider.yearlySchemes.length, 13);
      expect(provider.yearlySubscriptions.length, 0);
      expect(provider.totalYearlySubscriptionsCount, 0);
      expect(provider.activeYearlySubscriptionsCount, 0);
      expect(provider.pendingGiftsCount, 0);
    });

    test('Add, edit, toggle gift, and delete yearly subscription', () async {
      final now = DateTime.now();
      final sub = YearlySubscription(
        id: 'sub_test_1',
        customerName: 'Sunita Sharma',
        address: 'B-105, Galaxy Heights',
        phone: '9988776655',
        newspaperScheme: 'Times Of India+Navbharat Times',
        startDate: now,
        endDate: now.add(const Duration(days: 365)),
        couponType: CouponType.physicalCoupon,
        couponCode: 'PHY-5544',
        isGiftApplicable: true,
        isGiftDelivered: false,
        giftItem: 'Wall Clock',
        updatedAt: now,
      );

      // Add subscription
      await provider.saveYearlySubscription(sub);
      expect(provider.totalYearlySubscriptionsCount, 1);
      expect(provider.activeYearlySubscriptionsCount, 1);
      expect(provider.pendingGiftsCount, 1);

      // Toggle gift delivered
      await provider.toggleGiftDelivered('sub_test_1');
      expect(provider.pendingGiftsCount, 0);
      expect(provider.yearlySubscriptions.first.isGiftDelivered, isTrue);
      expect(provider.yearlySubscriptions.first.giftDeliveredDate, isNotNull);

      // Toggle back to pending
      await provider.toggleGiftDelivered('sub_test_1');
      expect(provider.pendingGiftsCount, 1);
      expect(provider.yearlySubscriptions.first.isGiftDelivered, isFalse);

      // Delete subscription
      await provider.deleteYearlySubscription('sub_test_1');
      expect(provider.totalYearlySubscriptionsCount, 0);
    });

    test('Add, edit, and delete custom yearly scheme', () async {
      final initialCount = provider.yearlySchemes.length;
      final newScheme = YearlyBookingScheme(
        id: 'scheme_custom_1',
        name: 'The Hindu + Frontline',
        price: 2499.0,
        description: 'Newspaper plus fortnightly magazine',
        isActive: true,
        updatedAt: DateTime.now(),
      );

      await provider.saveYearlyBookingScheme(newScheme);
      expect(provider.yearlySchemes.length, initialCount + 1);
      expect(provider.yearlySchemes.any((s) => s.name == 'The Hindu + Frontline'), isTrue);

      await provider.deleteYearlyBookingScheme('scheme_custom_1');
      expect(provider.yearlySchemes.length, initialCount);
    });
  });

  group('YearlySubscriptionsScreen Widget Tests', () {
    late LocalStorageService storage;
    late DeliveryProvider provider;

    setUp(() async {
      storage = await LocalStorageService.init(inMemoryForTests: true);
      await storage.saveAutoSync(false);
      provider = DeliveryProvider(storage);

      // Add sample subscription
      final now = DateTime.now();
      await provider.saveYearlySubscription(
        YearlySubscription(
          id: 'sub_sample',
          customerName: 'Rajesh Khanna',
          address: 'House 55, Block B',
          newspaperScheme: 'Hindustan Times+Mint',
          startDate: now,
          endDate: now.add(const Duration(days: 365)),
          couponType: CouponType.mCoupon,
          couponCode: 'MC-1234',
          isGiftApplicable: true,
          isGiftDelivered: false,
          giftItem: 'Dinner Set',
          updatedAt: now,
        ),
      );
    });

    testWidgets('Renders tabs, metrics, and subscription card', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: YearlySubscriptionsScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and tabs
      expect(find.text('Yearly Subscriptions & Schemes'), findsOneWidget);
      expect(find.text('Bookings (1)'), findsOneWidget);
      expect(find.text('Yearly Schemes (13)'), findsOneWidget);

      // Check card content
      expect(find.text('Rajesh Khanna'), findsOneWidget);
      expect(find.text('Hindustan Times+Mint'), findsOneWidget);
      expect(find.textContaining('Dinner Set'), findsOneWidget);

      // Switch to Schemes tab
      await tester.tap(find.text('Yearly Schemes (13)'));
      await tester.pumpAndSettle();

      expect(find.text('Hindustan Times'), findsOneWidget);
      expect(find.text('Times Of India'), findsOneWidget);
      expect(find.text('Amar Ujala'), findsOneWidget);

      // Verify top Add Scheme button is rendered
      expect(find.text('+ Add New Annual Subscription Scheme'), findsOneWidget);

      // Verify Edit and Delete buttons are rendered on scheme cards
      expect(find.text('Edit'), findsWidgets);
      expect(find.text('Delete'), findsWidgets);
    });

    testWidgets('Add, Edit, and Delete scheme via UI buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: YearlySubscriptionsScreen(
            provider: provider,
            initialTabIndex: 1, // Directly open Schemes tab
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify top Add New Scheme button
      final addSchemeBtn = find.text('+ Add New Annual Subscription Scheme');
      expect(addSchemeBtn, findsOneWidget);

      // Tap + Add New Annual Subscription Scheme button
      await tester.tap(addSchemeBtn);
      await tester.pumpAndSettle();

      // Check dialog is open
      expect(find.text('Add New Yearly Scheme'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3)); // Name, Price, Description

      // Enter scheme details
      await tester.enterText(find.byType(TextField).at(0), 'Business Standard');
      await tester.enterText(find.byType(TextField).at(1), '2500');
      await tester.enterText(find.byType(TextField).at(2), 'Financial daily newspaper');

      // Tap 'Confirm' button inside dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
      await tester.pumpAndSettle();

      // Verify provider has new scheme
      expect(provider.yearlySchemes.any((s) => s.name == 'Business Standard'), isTrue);
      expect(find.text('Business Standard'), findsOneWidget);

      // Tap Edit on Business Standard
      final editBtn = find.widgetWithText(ElevatedButton, 'Edit').first;
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(find.text('Edit Booking Scheme'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), '2600');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
      await tester.pumpAndSettle();

      // Tap Delete on first scheme
      final deleteBtn = find.widgetWithText(ElevatedButton, 'Delete').first;
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Confirm delete dialog
      expect(find.text('Delete Scheme?'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete Scheme'));
      await tester.pumpAndSettle();
    });
  });
}
