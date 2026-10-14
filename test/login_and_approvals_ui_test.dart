import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newspaper_delivery_app/main.dart';
import 'package:newspaper_delivery_app/providers/delivery_provider.dart';
import 'package:newspaper_delivery_app/screens/approvals_screen.dart';
import 'package:newspaper_delivery_app/screens/login_screen.dart';
import 'package:newspaper_delivery_app/services/local_storage_service.dart';

void main() {
  testWidgets('LoginScreen renders, switches roles, and opens ApprovalsScreen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final storage = await LocalStorageService.init(inMemoryForTests: true);
    final provider = DeliveryProvider(storage);

    // Explicitly logout so app opens on LoginScreen
    await provider.logout();

    await tester.pumpWidget(NewspaperDeliveryApp(provider: provider));
    await tester.pumpAndSettle();

    // Verify LoginScreen is shown
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('D K Rai Newspaper Agency'), findsOneWidget);
    expect(find.text('Owner (Admin)'), findsOneWidget);
    expect(find.text('Delivery Boy'), findsOneWidget);

    // Tap Delivery Boy card
    await tester.tap(find.text('Delivery Boy'));
    await tester.pumpAndSettle();

    // Tap "Instant Login (No PIN)" button
    await tester.tap(find.text('Instant Login (No PIN)'));
    await tester.pumpAndSettle();

    // Now logged in as Delivery Boy
    expect(provider.isDeliveryBoy, isTrue);

    // Delivery boy banner is visible
    expect(
      find.text(
        'Logged in as Delivery Boy. All start/stop & customer changes are submitted for Owner approval.',
      ),
      findsOneWidget,
    );

    // Delivery Boy pauses first customer
    final firstCust = provider.allCustomers.first;
    await provider.pauseCustomerPaper(firstCust.id, reason: 'Vacation');
    await tester.pumpAndSettle();

    expect(provider.pendingApprovalsCount, 1);

    // Switch user to Owner
    final ownerUser = provider.allUsers.firstWhere((u) => u.isOwner);
    await provider.switchUser(ownerUser);
    await tester.pumpAndSettle();

    expect(provider.isOwner, isTrue);

    // Verify Owner banner showing 1 pending approval
    expect(
      find.text('1 delivery boy actions are waiting for your approval.'),
      findsOneWidget,
    );

    // Tap the approval banner to open ApprovalsScreen
    await tester.tap(find.text('1 delivery boy actions are waiting for your approval.'));
    await tester.pumpAndSettle();

    // Verify ApprovalsScreen is pushed
    expect(find.byType(ApprovalsScreen), findsOneWidget);
    expect(find.text('Owner Approval Center'), findsOneWidget);
    expect(find.text('Approve Action'), findsOneWidget);

    // Tap Approve Action
    await tester.tap(find.text('Approve Action'));
    await tester.pumpAndSettle();

    // Pending count is now 0
    expect(provider.pendingApprovalsCount, 0);
  });
}
