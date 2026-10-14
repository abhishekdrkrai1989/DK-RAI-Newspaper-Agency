import 'package:flutter_test/flutter_test.dart';
import 'package:newspaper_delivery_app/main.dart';
import 'package:newspaper_delivery_app/models/customer.dart';
import 'package:newspaper_delivery_app/models/publication.dart';
import 'package:newspaper_delivery_app/providers/delivery_provider.dart';
import 'package:newspaper_delivery_app/services/local_storage_service.dart';

void main() {
  testWidgets(
      'Distribution list loads, filters by Block/Society, and toggles Started/Paused status',
      (WidgetTester tester) async {
    final storage = await LocalStorageService.init(inMemoryForTests: true);
    final provider = DeliveryProvider(storage);

    await tester.pumpWidget(NewspaperDeliveryApp(provider: provider));
    await tester.pumpAndSettle();

    // Verify app heading in English
    expect(find.text('D K Rai Newspaper Agency'), findsOneWidget);

    // Verify app heading updates when language toggles to Hindi
    await provider.toggleLanguage();
    await tester.pumpAndSettle();
    expect(find.text('डी के राय न्यूजपेपर एजेंसी'), findsOneWidget);

    // Toggle back to English
    await provider.toggleLanguage();
    await tester.pumpAndSettle();
    expect(find.text('D K Rai Newspaper Agency'), findsOneWidget);

    expect(provider.allCustomers.length, 5);

    // Verify Society filter
    provider.setSelectedArea('Shanti Nagar Society');
    expect(provider.filteredCustomers.length, 2);
    expect(provider.availableBlocks, ['Block A']);

    // Verify Block filter
    provider.clearLocationFilters();
    provider.setSelectedBlock('Block B');
    expect(provider.filteredCustomers.length, 2);

    provider.clearLocationFilters();
    expect(provider.filteredCustomers.length, 5);

    // Verify daily vs weekend frequency logic
    const weekendSub = SubscriptionItem(
      publicationId: 'pub_toi',
      frequency: DeliveryFrequency.weekendsOnly,
      quantity: 1,
    );
    final wednesday = DateTime(2026, 10, 14); // Wednesday
    final sunday = DateTime(2026, 10, 18); // Sunday
    expect(weekendSub.isDeliverableOnDate(wednesday), isFalse);
    expect(weekendSub.isDeliverableOnDate(sunday), isTrue);

    // Pause a started customer and verify persistence in local storage
    final firstCustomer = provider.allCustomers.first;
    expect(firstCustomer.status, DeliveryStatus.started);
    await provider.pauseCustomerPaper(firstCustomer.id, reason: 'Vacation');

    final reloadedCustomers = storage.loadCustomers();
    final updated =
        reloadedCustomers.firstWhere((c) => c.id == firstCustomer.id);
    expect(updated.status, DeliveryStatus.paused);
    expect(updated.pauseReason, 'Vacation');
  });
}
