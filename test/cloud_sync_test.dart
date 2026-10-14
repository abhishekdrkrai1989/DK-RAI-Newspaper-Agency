import 'package:flutter_test/flutter_test.dart';
import 'package:newspaper_delivery_app/providers/delivery_provider.dart';
import 'package:newspaper_delivery_app/services/cloud_sync_service.dart';
import 'package:newspaper_delivery_app/services/local_storage_service.dart';

void main() {
  group('CloudSyncService Unit Tests', () {
    test('sanitizeUrl handles various formats correctly', () {
      expect(CloudSyncService.sanitizeUrl('xyz.supabase.co'),
          'https://xyz.supabase.co');
      expect(CloudSyncService.sanitizeUrl('https://xyz.supabase.co/'),
          'https://xyz.supabase.co');
      expect(CloudSyncService.sanitizeUrl('https://wfaayogqdezoscftqmcp.supabase.co/rest/v1/'),
          'https://wfaayogqdezoscftqmcp.supabase.co');
      expect(CloudSyncService.sanitizeUrl('https://wfaayogqdezoscftqmcp.supabase.co/rest/v1'),
          'https://wfaayogqdezoscftqmcp.supabase.co');
      expect(CloudSyncService.sanitizeUrl('  http://my-api.com/  '),
          'http://my-api.com');
      expect(CloudSyncService.sanitizeUrl(''), '');
    });

    test('sqlSetupScript contains necessary tables and RLS policies', () {
      final sql = CloudSyncService.sqlSetupScript;
      expect(sql.contains('create table if not exists publications'), isTrue);
      expect(sql.contains('create table if not exists customers'), isTrue);
      expect(sql.contains('create table if not exists delivery_boys'), isTrue);
      expect(sql.contains('enable row level security'), isTrue);
      expect(sql.contains('Allow all on publications for anon'), isTrue);
      expect(sql.contains('Allow all on customers for anon'), isTrue);
      expect(sql.contains('Allow all on delivery_boys for anon'), isTrue);
    });

    test('testConnection fails gracefully on empty credentials', () async {
      final service = CloudSyncService();
      final res = await service.testConnection(url: '', anonKey: '');
      expect(res.success, isFalse);
      expect(res.message.contains('Please provide both'), isTrue);
    });

    test('deleteCustomerFromCloud and deletePublicationFromCloud fail gracefully on empty credentials', () async {
      final service = CloudSyncService();
      final resCust = await service.deleteCustomerFromCloud(url: '', anonKey: '', customerId: 'cust_1');
      expect(resCust, isFalse);
      final resPub = await service.deletePublicationFromCloud(url: '', anonKey: '', publicationId: 'pub_1');
      expect(resPub, isFalse);
      final resBoy = await service.deleteDeliveryBoyFromCloud(url: '', anonKey: '', boyId: 'boy_1');
      expect(resBoy, isFalse);
    });
  });

  group('DeliveryProvider Cloud Sync Integration Tests', () {
    test('Cloud credentials save, load, and update isCloudConfigured status',
        () async {
      final storage = await LocalStorageService.init(inMemoryForTests: true);
      final provider = DeliveryProvider(storage);

      // Default credentials provided by user are pre-configured
      expect(provider.isCloudConfigured, isTrue);
      expect(provider.supabaseUrl, 'https://wfaayogqdezoscftqmcp.supabase.co');
      expect(provider.supabaseAnonKey, LocalStorageService.defaultSupabaseAnonKey);
      expect(provider.autoSync, isTrue);

      await provider.saveCloudConfig(
        url: 'https://test-project.supabase.co',
        anonKey: 'sample-anon-key-12345',
        autoSync: true,
      );

      expect(provider.isCloudConfigured, isTrue);
      expect(provider.supabaseUrl, 'https://test-project.supabase.co');
      expect(provider.supabaseAnonKey, 'sample-anon-key-12345');
      expect(provider.autoSync, isTrue);

      // Verify persistence in LocalStorageService
      expect(storage.loadSupabaseUrl(), 'https://test-project.supabase.co');
      expect(storage.loadSupabaseAnonKey(), 'sample-anon-key-12345');
      expect(storage.loadAutoSync(), isTrue);
    });

    test('syncWithCloud reports error when cloud is unconfigured', () async {
      final storage = await LocalStorageService.init(inMemoryForTests: true);
      final provider = DeliveryProvider(storage);
      await provider.saveCloudConfig(url: '', anonKey: '', autoSync: false);

      final result = await provider.syncWithCloud();
      expect(result.success, isFalse);
      expect(result.message.contains('not configured'), isTrue);
      expect(provider.lastSyncSuccess, isFalse);
    });
  });
}
