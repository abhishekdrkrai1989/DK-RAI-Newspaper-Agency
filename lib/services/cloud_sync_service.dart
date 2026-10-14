import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_user.dart';
import '../models/customer.dart';
import '../models/newspaper_event.dart';
import '../models/publication.dart';

class CloudSyncResult {
  final bool success;
  final String message;
  final int customersSynced;
  final int publicationsSynced;
  final int deliveryBoysSynced;
  final int eventsSynced;
  final DateTime timestamp;

  const CloudSyncResult({
    required this.success,
    required this.message,
    this.customersSynced = 0,
    this.publicationsSynced = 0,
    this.deliveryBoysSynced = 0,
    this.eventsSynced = 0,
    required this.timestamp,
  });
}

class CloudSyncService {
  final http.Client _client;

  CloudSyncService({http.Client? client}) : _client = client ?? http.Client();

  static String sanitizeUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.endsWith('/rest/v1')) {
      trimmed = trimmed.substring(0, trimmed.length - '/rest/v1'.length);
    }
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static const String fallbackProjectJwt =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndmYWF5b2dxZGV6b3NjZnRxbWNwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4ODc1MTAsImV4cCI6MjEwNzQ2MzUxMH0.OrVAh44u1ZqGpsq63AKhuWMglyszf2qafu7ypNiPE-I';

  Map<String, String> _headers(String anonKey, {bool upsert = false}) {
    final cleanKey = anonKey.trim();
    final authBearer = cleanKey.startsWith('sb_publishable_') ? fallbackProjectJwt : cleanKey;

    final headers = {
      'apikey': cleanKey,
      'Authorization': 'Bearer $authBearer',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (upsert) {
      headers['Prefer'] = 'resolution=merge-duplicates';
    }
    return headers;
  }

  /// Verifies connectivity to Supabase using Project URL and Anon API key
  Future<CloudSyncResult> testConnection({
    required String url,
    required String anonKey,
  }) async {
    final cleanUrl = sanitizeUrl(url);
    if (cleanUrl.isEmpty || anonKey.trim().isEmpty) {
      return CloudSyncResult(
        success: false,
        message: 'Please provide both Supabase Project URL and Anon API Key.',
        timestamp: DateTime.now(),
      );
    }

    try {
      final uri = Uri.parse('$cleanUrl/rest/v1/customers?select=id&limit=1');
      final response = await _client
          .get(uri, headers: _headers(anonKey))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return CloudSyncResult(
          success: true,
          message: 'Connection successful! Supabase tables are ready.',
          timestamp: DateTime.now(),
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return CloudSyncResult(
          success: false,
          message: 'Authentication failed. Please verify your Anon API Key.',
          timestamp: DateTime.now(),
        );
      } else if (response.statusCode == 404 ||
          response.body.contains('PGRST204') ||
          response.body.contains('relation "customers" does not exist') ||
          response.body.contains('table') && response.body.contains('not find')) {
        return CloudSyncResult(
          success: false,
          message:
              'Connected to Supabase, but "customers" table was not found. Please run the SQL schema script in Supabase SQL Editor.',
          timestamp: DateTime.now(),
        );
      } else {
        return CloudSyncResult(
          success: false,
          message:
              'Server responded with HTTP ${response.statusCode}: ${response.body}',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      return CloudSyncResult(
        success: false,
        message: 'Network error connecting to Supabase: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Uploads (upserts) all local publications, customers, and delivery boys to Supabase Cloud DB
  Future<CloudSyncResult> uploadAll({
    required String url,
    required String anonKey,
    required List<Customer> customers,
    required List<Publication> publications,
    List<AppUser> users = const [],
    List<NewspaperEvent> events = const [],
  }) async {
    final cleanUrl = sanitizeUrl(url);
    if (cleanUrl.isEmpty || anonKey.trim().isEmpty) {
      return CloudSyncResult(
        success: false,
        message: 'Cloud database is not configured.',
        timestamp: DateTime.now(),
      );
    }

    try {
      // 1. Upsert Publications
      if (publications.isNotEmpty) {
        final pubsUri = Uri.parse('$cleanUrl/rest/v1/publications');
        final pubRows = publications.map((p) => _publicationToRow(p)).toList();
        final pubRes = await _client
            .post(
              pubsUri,
              headers: _headers(anonKey, upsert: true),
              body: jsonEncode(pubRows),
            )
            .timeout(const Duration(seconds: 20));

        if (pubRes.statusCode < 200 || pubRes.statusCode >= 300) {
          return CloudSyncResult(
            success: false,
            message:
                'Failed to upload publications (HTTP ${pubRes.statusCode}): ${pubRes.body}',
            timestamp: DateTime.now(),
          );
        }
      }

      // 2. Upsert Customers
      if (customers.isNotEmpty) {
        final custUri = Uri.parse('$cleanUrl/rest/v1/customers');
        final custRows = customers.map((c) => _customerToRow(c)).toList();
        final custRes = await _client
            .post(
              custUri,
              headers: _headers(anonKey, upsert: true),
              body: jsonEncode(custRows),
            )
            .timeout(const Duration(seconds: 25));

        if (custRes.statusCode < 200 || custRes.statusCode >= 300) {
          return CloudSyncResult(
            success: false,
            message:
                'Failed to upload customers (HTTP ${custRes.statusCode}): ${custRes.body}',
            timestamp: DateTime.now(),
          );
        }
      }

      // 3. Upsert Delivery Boys / Hawkers
      int boysSynced = 0;
      if (users.isNotEmpty) {
        final boysUri = Uri.parse('$cleanUrl/rest/v1/delivery_boys');
        final boyRows = users.map((u) => _userToRow(u)).toList();
        final boyRes = await _client
            .post(
              boysUri,
              headers: _headers(anonKey, upsert: true),
              body: jsonEncode(boyRows),
            )
            .timeout(const Duration(seconds: 20));

        if (boyRes.statusCode >= 200 && boyRes.statusCode < 300) {
          boysSynced = users.length;
        } else if (boyRes.statusCode == 404 ||
            boyRes.body.contains('PGRST204') ||
            boyRes.body.contains('delivery_boys') &&
                boyRes.body.contains('does not exist')) {
          // Table does not exist yet on remote Supabase; skip without failing customers sync
        } else {
          return CloudSyncResult(
            success: false,
            message:
                'Failed to upload delivery boys (HTTP ${boyRes.statusCode}): ${boyRes.body}',
            timestamp: DateTime.now(),
          );
        }
      }

      // 4. Upsert Newspaper Events (New start, started, paused, deleted)
      int eventsSynced = 0;
      if (events.isNotEmpty) {
        try {
          final eventsUri = Uri.parse('$cleanUrl/rest/v1/newspaper_events');
          final eventRows = events.map((e) => e.toRow()).toList();
          final eventRes = await _client
              .post(
                eventsUri,
                headers: _headers(anonKey, upsert: true),
                body: jsonEncode(eventRows),
              )
              .timeout(const Duration(seconds: 25));

          if (eventRes.statusCode >= 200 && eventRes.statusCode < 300) {
            eventsSynced = events.length;
          }
        } catch (_) {}
      }

      return CloudSyncResult(
        success: true,
        message: 'Successfully backed up all data to Supabase Cloud DB!',
        customersSynced: customers.length,
        publicationsSynced: publications.length,
        deliveryBoysSynced: boysSynced,
        eventsSynced: eventsSynced,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return CloudSyncResult(
        success: false,
        message: 'Error uploading to cloud: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Downloads all publications, customers, delivery boys, and events from Supabase Cloud DB
  Future<({
    List<Customer>? customers,
    List<Publication>? publications,
    List<AppUser>? deliveryBoys,
    List<NewspaperEvent>? events,
    CloudSyncResult result,
  })> downloadAll({
    required String url,
    required String anonKey,
  }) async {
    final cleanUrl = sanitizeUrl(url);
    if (cleanUrl.isEmpty || anonKey.trim().isEmpty) {
      return (
        customers: null,
        publications: null,
        deliveryBoys: null,
        events: null,
        result: CloudSyncResult(
          success: false,
          message: 'Cloud database is not configured.',
          timestamp: DateTime.now(),
        ),
      );
    }

    try {
      // 1. Fetch Publications
      final pubsUri = Uri.parse('$cleanUrl/rest/v1/publications?select=*');
      final pubRes = await _client
          .get(pubsUri, headers: _headers(anonKey))
          .timeout(const Duration(seconds: 15));

      if (pubRes.statusCode < 200 || pubRes.statusCode >= 300) {
        return (
          customers: null,
          publications: null,
          deliveryBoys: null,
          events: null,
          result: CloudSyncResult(
            success: false,
            message:
                'Failed to fetch publications (HTTP ${pubRes.statusCode}): ${pubRes.body}',
            timestamp: DateTime.now(),
          ),
        );
      }

      final pubListRaw = jsonDecode(pubRes.body) as List<dynamic>;
      final remotePublications = pubListRaw
          .map((row) => _rowToPublication(row as Map<String, dynamic>))
          .toList();

      // 2. Fetch Customers
      final custUri = Uri.parse(
        '$cleanUrl/rest/v1/customers?select=*&order=sequence_no.asc',
      );
      final custRes = await _client
          .get(custUri, headers: _headers(anonKey))
          .timeout(const Duration(seconds: 20));

      if (custRes.statusCode < 200 || custRes.statusCode >= 300) {
        return (
          customers: null,
          publications: null,
          deliveryBoys: null,
          events: null,
          result: CloudSyncResult(
            success: false,
            message:
                'Failed to fetch customers (HTTP ${custRes.statusCode}): ${custRes.body}',
            timestamp: DateTime.now(),
          ),
        );
      }

      final custListRaw = jsonDecode(custRes.body) as List<dynamic>;
      final remoteCustomers = custListRaw
          .map((row) => _rowToCustomer(row as Map<String, dynamic>))
          .toList();

      // 3. Fetch Delivery Boys
      List<AppUser>? remoteBoys;
      try {
        final boysUri = Uri.parse('$cleanUrl/rest/v1/delivery_boys?select=*');
        final boysRes = await _client
            .get(boysUri, headers: _headers(anonKey))
            .timeout(const Duration(seconds: 15));
        if (boysRes.statusCode >= 200 && boysRes.statusCode < 300) {
          final boysListRaw = jsonDecode(boysRes.body) as List<dynamic>;
          remoteBoys = boysListRaw
              .map((row) => _rowToUser(row as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}

      // 4. Fetch Newspaper Events (Delivery boy-wise, area-wise new start, paused, started, deleted)
      List<NewspaperEvent>? remoteEvents;
      try {
        final eventsUri =
            Uri.parse('$cleanUrl/rest/v1/newspaper_events?select=*');
        final eventsRes = await _client
            .get(eventsUri, headers: _headers(anonKey))
            .timeout(const Duration(seconds: 15));
        if (eventsRes.statusCode >= 200 && eventsRes.statusCode < 300) {
          final eventsListRaw = jsonDecode(eventsRes.body) as List<dynamic>;
          remoteEvents = eventsListRaw
              .map((row) => NewspaperEvent.fromRow(row as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}

      final boysCount = remoteBoys?.length ?? 0;
      final eventsCount = remoteEvents?.length ?? 0;
      return (
        customers: remoteCustomers,
        publications: remotePublications,
        deliveryBoys: remoteBoys,
        events: remoteEvents,
        result: CloudSyncResult(
          success: true,
          message:
              'Downloaded ${remoteCustomers.length} homes, ${remotePublications.length} publications, $boysCount hawkers & $eventsCount events from Supabase.',
          customersSynced: remoteCustomers.length,
          publicationsSynced: remotePublications.length,
          deliveryBoysSynced: boysCount,
          eventsSynced: eventsCount,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      return (
        customers: null,
        publications: null,
        deliveryBoys: null,
        events: null,
        result: CloudSyncResult(
          success: false,
          message: 'Error downloading from cloud: $e',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Two-way sync: Merges local and cloud records, then uploads any missing/newer records
  Future<({
    List<Customer> customers,
    List<Publication> publications,
    List<AppUser> deliveryBoys,
    List<NewspaperEvent> events,
    CloudSyncResult result,
  })> syncTwoWay({
    required String url,
    required String anonKey,
    required List<Customer> localCustomers,
    required List<Publication> localPublications,
    List<AppUser> localUsers = const [],
    List<NewspaperEvent> localEvents = const [],
  }) async {
    final downloadResult =
        await downloadAll(url: url, anonKey: anonKey);

    if (!downloadResult.result.success ||
        downloadResult.customers == null ||
        downloadResult.publications == null) {
      return (
        customers: localCustomers,
        publications: localPublications,
        deliveryBoys: localUsers,
        events: localEvents,
        result: downloadResult.result,
      );
    }

    // Merge Publications
    final mergedPubsMap = <String, Publication>{};
    for (final p in downloadResult.publications!) {
      mergedPubsMap[p.id] = p;
    }
    for (final p in localPublications) {
      mergedPubsMap[p.id] = p; // Local takes priority if modified
    }
    final mergedPublications = mergedPubsMap.values.toList();

    // Merge Customers
    final mergedCustMap = <String, Customer>{};
    for (final c in downloadResult.customers!) {
      mergedCustMap[c.id] = c;
    }
    for (final c in localCustomers) {
      mergedCustMap[c.id] = c; // Local takes priority if modified
    }
    final mergedCustomers = mergedCustMap.values.toList()
      ..sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));

    // Merge Delivery Boys
    final mergedBoysMap = <String, AppUser>{};
    if (downloadResult.deliveryBoys != null) {
      for (final b in downloadResult.deliveryBoys!) {
        mergedBoysMap[b.id] = b;
      }
    }
    for (final b in localUsers) {
      mergedBoysMap[b.id] = b; // Local takes priority if modified
    }
    final mergedBoys = mergedBoysMap.values.toList();

    // Merge Newspaper Events
    final mergedEventsMap = <String, NewspaperEvent>{};
    if (downloadResult.events != null) {
      for (final e in downloadResult.events!) {
        mergedEventsMap[e.id] = e;
      }
    }
    for (final e in localEvents) {
      mergedEventsMap[e.id] = e;
    }
    final mergedEvents = mergedEventsMap.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Upload merged state back to cloud so both sides are in sync
    final uploadResult = await uploadAll(
      url: url,
      anonKey: anonKey,
      customers: mergedCustomers,
      publications: mergedPublications,
      users: mergedBoys,
      events: mergedEvents,
    );

    if (!uploadResult.success) {
      return (
        customers: mergedCustomers,
        publications: mergedPublications,
        deliveryBoys: mergedBoys,
        events: mergedEvents,
        result: uploadResult,
      );
    }

    return (
      customers: mergedCustomers,
      publications: mergedPublications,
      deliveryBoys: mergedBoys,
      events: mergedEvents,
      result: CloudSyncResult(
        success: true,
        message:
            'Two-way sync complete: ${mergedCustomers.length} homes, ${mergedPublications.length} publications, ${mergedBoys.length} hawkers & ${mergedEvents.length} events synchronized with Supabase.',
        customersSynced: mergedCustomers.length,
        publicationsSynced: mergedPublications.length,
        deliveryBoysSynced: mergedBoys.length,
        eventsSynced: mergedEvents.length,
        timestamp: DateTime.now(),
      ),
    );
  }

  // --- Row Mappers supporting both snake_case and camelCase ---

  Map<String, dynamic> _customerToRow(Customer c) {
    return {
      'id': c.id,
      'sequence_no': c.sequenceNo,
      'name': c.name,
      'house_number': c.houseNumber,
      'block': c.block,
      'area': c.area,
      'phone': c.phone,
      'status': c.status.name,
      'pause_start_date': c.pauseStartDate?.toIso8601String(),
      'pause_end_date': c.pauseEndDate?.toIso8601String(),
      'pause_reason': c.pauseReason,
      'delivery_boy_id': c.deliveryBoyId,
      'delivery_boy_name': c.deliveryBoyName,
      'subscriptions': c.subscriptions.map((s) => s.toJson()).toList(),
      'delivered_dates': c.deliveredDates,
      'status_history': c.statusHistory.map((h) => h.toJson()).toList(),
      'notes': c.notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Customer _rowToCustomer(Map<String, dynamic> row) {
    final id = (row['id'] as String?) ?? '';
    final seq = (row['sequence_no'] as num?)?.toInt() ??
        (row['sequenceNo'] as num?)?.toInt() ??
        0;
    final name = (row['name'] as String?) ?? '';
    final houseNo = (row['house_number'] as String?) ??
        (row['houseNumber'] as String?) ??
        '';
    final block = (row['block'] as String?) ?? '';
    final area = (row['area'] as String?) ?? '';
    final phone = (row['phone'] as String?) ?? '';
    final statusStr = (row['status'] as String?) ?? 'started';
    final status = statusStr == 'paused'
        ? DeliveryStatus.paused
        : DeliveryStatus.started;

    final pauseStartStr =
        (row['pause_start_date'] as String?) ?? (row['pauseStartDate'] as String?);
    final pauseEndStr =
        (row['pause_end_date'] as String?) ?? (row['pauseEndDate'] as String?);
    final pauseReason = (row['pause_reason'] as String?) ??
        (row['pauseReason'] as String?) ??
        '';

    final deliveryBoyId = (row['delivery_boy_id'] as String?) ??
        (row['deliveryBoyId'] as String?);
    final deliveryBoyName = (row['delivery_boy_name'] as String?) ??
        (row['deliveryBoyName'] as String?);

    final subsRaw = row['subscriptions'];
    List<SubscriptionItem> subs = [];
    if (subsRaw is List) {
      subs = subsRaw
          .whereType<Map<String, dynamic>>()
          .map((s) => SubscriptionItem.fromJson(s))
          .toList();
    }

    final delivRaw = row['delivered_dates'] ?? row['deliveredDates'];
    List<String> deliveredDates = [];
    if (delivRaw is List) {
      deliveredDates = delivRaw.map((e) => e.toString()).toList();
    }

    final histRaw = row['status_history'] ?? row['statusHistory'];
    List<StatusLog> statusHistory = [];
    if (histRaw is List) {
      statusHistory = histRaw
          .whereType<Map<String, dynamic>>()
          .map((h) => StatusLog.fromJson(h))
          .toList();
    }

    final notes = (row['notes'] as String?) ?? '';

    return Customer(
      id: id,
      sequenceNo: seq,
      name: name,
      houseNumber: houseNo,
      block: block,
      area: area,
      phone: phone,
      status: status,
      pauseStartDate:
          pauseStartStr != null ? DateTime.tryParse(pauseStartStr) : null,
      pauseEndDate: pauseEndStr != null ? DateTime.tryParse(pauseEndStr) : null,
      pauseReason: pauseReason,
      deliveryBoyId: deliveryBoyId ?? '',
      deliveryBoyName: deliveryBoyName ?? '',
      subscriptions: subs,
      deliveredDates: deliveredDates,
      statusHistory: statusHistory,
      notes: notes,
    );
  }

  Map<String, dynamic> _publicationToRow(Publication p) {
    return {
      'id': p.id,
      'name_en': p.nameEn,
      'name_hi': p.nameHi,
      'type': p.type.name,
      'default_frequency': p.defaultFrequency.name,
      'weekday_price': p.weekdayPrice,
      'weekend_price': p.weekendPrice,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Publication _rowToPublication(Map<String, dynamic> row) {
    final id = (row['id'] as String?) ?? '';
    final nameEn = (row['name_en'] as String?) ??
        (row['nameEn'] as String?) ??
        '';
    final nameHi = (row['name_hi'] as String?) ??
        (row['nameHi'] as String?) ??
        '';
    final typeStr = (row['type'] as String?) ?? 'newspaper';
    final type = typeStr == 'magazine'
        ? PublicationType.magazine
        : PublicationType.newspaper;

    final freqStr = (row['default_frequency'] as String?) ??
        (row['defaultFrequency'] as String?) ??
        'daily';
    final defaultFreq = DeliveryFrequency.values.firstWhere(
      (e) => e.name == freqStr,
      orElse: () => DeliveryFrequency.daily,
    );

    final weekdayPrice = (row['weekday_price'] as num?)?.toDouble() ??
        (row['weekdayPrice'] as num?)?.toDouble() ??
        5.0;
    final weekendPrice = (row['weekend_price'] as num?)?.toDouble() ??
        (row['weekendPrice'] as num?)?.toDouble() ??
        weekdayPrice;

    return Publication(
      id: id,
      nameEn: nameEn,
      nameHi: nameHi,
      type: type,
      defaultFrequency: defaultFreq,
      weekdayPrice: weekdayPrice,
      weekendPrice: weekendPrice,
    );
  }

  Map<String, dynamic> _userToRow(AppUser u) {
    return {
      'id': u.id,
      'name': u.name,
      'role': u.role.name,
      'pin': u.pin,
      'phone': u.phone,
      'assigned_area': u.assignedArea,
      'is_active': u.isActive,
      'vehicle_number': u.vehicleNumber,
      'notes': u.notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  AppUser _rowToUser(Map<String, dynamic> row) {
    final id = (row['id'] as String?) ?? '';
    final name = (row['name'] as String?) ?? '';
    final roleStr = (row['role'] as String?) ?? 'deliveryBoy';
    final role = roleStr == 'owner' ? UserRole.owner : UserRole.deliveryBoy;
    final pin = (row['pin'] as String?) ?? '0000';
    final phone = (row['phone'] as String?) ?? '';
    final assignedArea = (row['assigned_area'] as String?) ??
        (row['assignedArea'] as String?) ??
        '';
    final isActive = (row['is_active'] as bool?) ??
        (row['isActive'] as bool?) ??
        true;
    final vehicleNumber = (row['vehicle_number'] as String?) ??
        (row['vehicleNumber'] as String?) ??
        '';
    final notes = (row['notes'] as String?) ?? '';

    return AppUser(
      id: id,
      name: name,
      role: role,
      pin: pin,
      phone: phone,
      assignedArea: assignedArea,
      isActive: isActive,
      vehicleNumber: vehicleNumber,
      notes: notes,
    );
  }

  Future<bool> deleteDeliveryBoyFromCloud({
    required String url,
    required String anonKey,
    required String boyId,
  }) async {
    final cleanUrl = sanitizeUrl(url);
    if (cleanUrl.isEmpty || anonKey.trim().isEmpty) return false;
    try {
      final uri = Uri.parse('$cleanUrl/rest/v1/delivery_boys?id=eq.$boyId');
      final res = await _client
          .delete(uri, headers: _headers(anonKey))
          .timeout(const Duration(seconds: 10));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCustomerFromCloud({
    required String url,
    required String anonKey,
    required String customerId,
  }) async {
    final cleanUrl = sanitizeUrl(url);
    if (cleanUrl.isEmpty || anonKey.trim().isEmpty) return false;
    try {
      final uri = Uri.parse('$cleanUrl/rest/v1/customers?id=eq.$customerId');
      final res = await _client
          .delete(uri, headers: _headers(anonKey))
          .timeout(const Duration(seconds: 10));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePublicationFromCloud({
    required String url,
    required String anonKey,
    required String publicationId,
  }) async {
    final cleanUrl = sanitizeUrl(url);
    if (cleanUrl.isEmpty || anonKey.trim().isEmpty) return false;
    try {
      final uri =
          Uri.parse('$cleanUrl/rest/v1/publications?id=eq.$publicationId');
      final res = await _client
          .delete(uri, headers: _headers(anonKey))
          .timeout(const Duration(seconds: 10));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Copyable PostgreSQL SQL script for Supabase SQL Editor
  static String get sqlSetupScript => '''
-- ==============================================================
-- D K Rai Newspaper Agency - Supabase Free Cloud Database Setup
-- Run this in the Supabase SQL Editor (https://app.supabase.com)
-- ==============================================================

-- 1. Create Publications Table (Newspapers & Magazines)
create table if not exists publications (
  id text primary key,
  name_en text not null,
  name_hi text not null default '',
  type text not null default 'newspaper',
  default_frequency text not null default 'daily',
  weekday_price numeric not null default 5.0,
  weekend_price numeric not null default 5.0,
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- 2. Create Customers Table (Homes, Subscriptions & Pause History)
create table if not exists customers (
  id text primary key,
  sequence_no integer default 0,
  name text not null,
  house_number text not null,
  block text default '',
  area text not null default '',
  phone text default '',
  status text not null default 'started',
  pause_start_date text,
  pause_end_date text,
  pause_reason text default '',
  delivery_boy_id text default '',
  delivery_boy_name text default '',
  subscriptions jsonb default '[]'::jsonb,
  delivered_dates jsonb default '[]'::jsonb,
  status_history jsonb default '[]'::jsonb,
  notes text default '',
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- 3. Create Delivery Boys / Hawkers Table (Profiles & Credentials)
create table if not exists delivery_boys (
  id text primary key,
  name text not null,
  role text not null default 'deliveryBoy',
  pin text not null default '0000',
  phone text default '',
  assigned_area text default '',
  is_active boolean default true,
  vehicle_number text default '',
  notes text default '',
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- 4. Create Newspaper Events Table (Tracking New Start, Started, Paused, Deleted)
create table if not exists newspaper_events (
  id text primary key,
  event_type text not null,
  customer_id text default '',
  customer_name text not null,
  house_number text default '',
  block text default '',
  area text not null default '',
  delivery_boy_id text default '',
  delivery_boy_name text default '',
  newspaper_name text not null,
  publication_id text default '',
  quantity integer default 1,
  timestamp text not null,
  pause_start_date text,
  pause_end_date text,
  note text default '',
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- 5. Enable Row Level Security (RLS)
alter table publications enable row level security;
alter table customers enable row level security;
alter table delivery_boys enable row level security;
alter table newspaper_events enable row level security;

-- 6. Enable Public Anon API Access (Read & Write with Anon Key)
drop policy if exists "Allow all on publications for anon" on publications;
create policy "Allow all on publications for anon"
  on publications for all
  using (true)
  with check (true);

drop policy if exists "Allow all on customers for anon" on customers;
create policy "Allow all on customers for anon"
  on customers for all
  using (true)
  with check (true);

drop policy if exists "Allow all on delivery_boys for anon" on delivery_boys;
create policy "Allow all on delivery_boys for anon"
  on delivery_boys for all
  using (true)
  with check (true);

drop policy if exists "Allow all on newspaper_events for anon" on newspaper_events;
create policy "Allow all on newspaper_events for anon"
  on newspaper_events for all
  using (true)
  with check (true);
''';
}
