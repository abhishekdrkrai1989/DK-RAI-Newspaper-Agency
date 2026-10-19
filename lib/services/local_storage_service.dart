import 'dart:convert';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import '../models/approval_request.dart';
import '../models/customer.dart';
import '../models/newspaper_event.dart';
import '../models/publication.dart';
import '../models/yearly_booking_scheme.dart';
import '../models/yearly_subscription.dart';
import 'storage_backend.dart';

class LocalStorageService {
  static const String _keyCustomers = 'newspaper_app_customers_v1';
  static const String _keyPublications = 'newspaper_app_publications_v1';
  static const String _keyLanguage = 'newspaper_app_language_v1';
  static const String _keySeeded = 'newspaper_app_seeded_v1';
  static const String _keySupabaseUrl = 'newspaper_app_supabase_url_v1';
  static const String _keySupabaseAnonKey = 'newspaper_app_supabase_anon_key_v1';
  static const String _keyAutoSync = 'newspaper_app_auto_sync_v1';
  static const String _keyLastSyncTime = 'newspaper_app_last_sync_time_v1';
  static const String _keyUsers = 'newspaper_app_users_v1';
  static const String _keyCurrentUser = 'newspaper_app_current_user_v1';
  static const String _keyApprovalRequests = 'newspaper_app_approval_requests_v1';
  static const String _keyNewspaperEvents = 'newspaper_app_events_v1';
  static const String _keyCustomBlocks = 'newspaper_app_custom_blocks_v1';
  static const String _keyYearlySchemes = 'newspaper_app_yearly_schemes_v1';
  static const String _keyYearlySubscriptions = 'newspaper_app_yearly_subscriptions_v1';

  final StorageBackend _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init({bool inMemoryForTests = false}) async {
    final prefs = await StorageBackend.init(inMemoryForTests: inMemoryForTests);
    final service = LocalStorageService(prefs);
    await service._ensureSeedData();
    return service;
  }

  AppLanguage loadLanguage() {
    final code = _prefs.getString(_keyLanguage) ?? 'en';
    return code == 'hi' ? AppLanguage.hi : AppLanguage.en;
  }

  Future<void> saveLanguage(AppLanguage language) async {
    await _prefs.setString(_keyLanguage, language.name);
  }

  static const String defaultSupabaseUrl =
      'https://wfaayogqdezoscftqmcp.supabase.co';
  static const String defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndmYWF5b2dxZGV6b3NjZnRxbWNwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4ODc1MTAsImV4cCI6MjEwNzQ2MzUxMH0.OrVAh44u1ZqGpsq63AKhuWMglyszf2qafu7ypNiPE-I';

  String loadSupabaseUrl() {
    final stored = _prefs.getString(_keySupabaseUrl);
    if (stored != null && stored.trim().isNotEmpty) return stored;
    return defaultSupabaseUrl;
  }

  Future<void> saveSupabaseUrl(String url) async {
    await _prefs.setString(_keySupabaseUrl, url.trim());
  }

  String loadSupabaseAnonKey() {
    final stored = _prefs.getString(_keySupabaseAnonKey);
    if (stored != null && stored.trim().isNotEmpty) return stored;
    return defaultSupabaseAnonKey;
  }

  Future<void> saveSupabaseAnonKey(String key) async {
    await _prefs.setString(_keySupabaseAnonKey, key.trim());
  }

  bool loadAutoSync() {
    return _prefs.getBool(_keyAutoSync) ?? true;
  }

  Future<void> saveAutoSync(bool enabled) async {
    await _prefs.setBool(_keyAutoSync, enabled);
  }

  DateTime? loadLastSyncTime() {
    final raw = _prefs.getString(_keyLastSyncTime);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveLastSyncTime(DateTime time) async {
    await _prefs.setString(_keyLastSyncTime, time.toIso8601String());
  }

  List<AppUser> loadUsers() {
    final raw = _prefs.getString(_keyUsers);
    if (raw == null || raw.isEmpty) {
      return List<AppUser>.from(AppUser.defaultUsers());
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return List<AppUser>.from(AppUser.defaultUsers());
    }
  }

  Future<void> saveUsers(List<AppUser> users) async {
    final encoded = jsonEncode(users.map((u) => u.toJson()).toList());
    await _prefs.setString(_keyUsers, encoded);
  }

  AppUser? loadCurrentUser() {
    final raw = _prefs.getString(_keyCurrentUser);
    if (raw == null || raw.isEmpty) {
      // Default to Owner if not set
      return AppUser.defaultUsers().first;
    }
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppUser.defaultUsers().first;
    }
  }

  Future<void> saveCurrentUser(AppUser? user) async {
    if (user == null) {
      await _prefs.setString(_keyCurrentUser, '');
    } else {
      await _prefs.setString(_keyCurrentUser, jsonEncode(user.toJson()));
    }
  }

  List<ApprovalRequest> loadApprovalRequests() {
    final raw = _prefs.getString(_keyApprovalRequests);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .map((item) => ApprovalRequest.fromJson(item as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveApprovalRequests(List<ApprovalRequest> requests) async {
    final encoded = jsonEncode(requests.map((r) => r.toJson()).toList());
    await _prefs.setString(_keyApprovalRequests, encoded);
  }

  List<NewspaperEvent> loadNewspaperEvents() {
    final raw = _prefs.getString(_keyNewspaperEvents);
    if (raw == null || raw.isEmpty) {
      return defaultNewspaperEvents();
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .map((item) => NewspaperEvent.fromJson(item as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (_) {
      return defaultNewspaperEvents();
    }
  }

  Future<void> saveNewspaperEvents(List<NewspaperEvent> events) async {
    final encoded = jsonEncode(events.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyNewspaperEvents, encoded);
  }

  List<String> loadCustomBlocks() {
    final raw = _prefs.getString(_keyCustomBlocks);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomBlocks(List<String> blocks) async {
    final clean = blocks.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList()..sort();
    final encoded = jsonEncode(clean);
    await _prefs.setString(_keyCustomBlocks, encoded);
  }

  List<YearlyBookingScheme> loadYearlyBookingSchemes() {
    final raw = _prefs.getString(_keyYearlySchemes);
    if (raw == null || raw.isEmpty) {
      return YearlyBookingScheme.defaultSchemes();
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .map((item) =>
              YearlyBookingScheme.fromJson(item as Map<String, dynamic>))
          .toList();
      return list.isNotEmpty ? list : YearlyBookingScheme.defaultSchemes();
    } catch (_) {
      return YearlyBookingScheme.defaultSchemes();
    }
  }

  Future<void> saveYearlyBookingSchemes(
      List<YearlyBookingScheme> schemes) async {
    final encoded = jsonEncode(schemes.map((s) => s.toJson()).toList());
    await _prefs.setString(_keyYearlySchemes, encoded);
  }

  List<YearlySubscription> loadYearlySubscriptions() {
    final raw = _prefs.getString(_keyYearlySubscriptions);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .map((item) =>
              YearlySubscription.fromJson(item as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveYearlySubscriptions(
      List<YearlySubscription> subscriptions) async {
    final encoded =
        jsonEncode(subscriptions.map((s) => s.toJson()).toList());
    await _prefs.setString(_keyYearlySubscriptions, encoded);
  }

  List<Publication> loadPublications() {
    final raw = _prefs.getString(_keyPublications);
    if (raw == null || raw.isEmpty) {
      return defaultPublications();
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Publication.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return defaultPublications();
    }
  }

  Future<void> savePublications(List<Publication> publications) async {
    final encoded = jsonEncode(publications.map((p) => p.toJson()).toList());
    await _prefs.setString(_keyPublications, encoded);
  }

  List<Customer> loadCustomers() {
    final raw = _prefs.getString(_keyCustomers);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .map((item) => Customer.fromJson(item as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomers(List<Customer> customers) async {
    final sorted = [...customers]
      ..sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));
    final encoded = jsonEncode(sorted.map((c) => c.toJson()).toList());
    await _prefs.setString(_keyCustomers, encoded);
  }

  Future<void> _ensureSeedData() async {
    final seeded = _prefs.getBool(_keySeeded) ?? false;
    if (!seeded) {
      final pubs = defaultPublications();
      await savePublications(pubs);
      final customers = defaultCustomers();
      await saveCustomers(customers);
      await saveNewspaperEvents(defaultNewspaperEvents());
      await _prefs.setBool(_keySeeded, true);
    }
  }

  Future<void> resetToDemoData() async {
    await savePublications(defaultPublications());
    await saveCustomers(defaultCustomers());
    await saveNewspaperEvents(defaultNewspaperEvents());
    await _prefs.setBool(_keySeeded, true);
  }

  static List<Publication> defaultPublications() {
    return const [
      Publication(
        id: 'pub_bhaskar',
        nameEn: 'Dainik Bhaskar',
        nameHi: 'दैनिक भास्कर',
        type: PublicationType.newspaper,
        defaultFrequency: DeliveryFrequency.daily,
        weekdayPrice: 5.0,
        weekendPrice: 6.0,
      ),
      Publication(
        id: 'pub_toi',
        nameEn: 'The Times of India',
        nameHi: 'टाइम्स ऑफ इंडिया',
        type: PublicationType.newspaper,
        defaultFrequency: DeliveryFrequency.daily,
        weekdayPrice: 6.0,
        weekendPrice: 8.0,
      ),
      Publication(
        id: 'pub_jagran',
        nameEn: 'Dainik Jagran',
        nameHi: 'दैनिक जागरण',
        type: PublicationType.newspaper,
        defaultFrequency: DeliveryFrequency.daily,
        weekdayPrice: 5.0,
        weekendPrice: 6.0,
      ),
      Publication(
        id: 'pub_hindu',
        nameEn: 'The Hindu',
        nameHi: 'द हिंदू',
        type: PublicationType.newspaper,
        defaultFrequency: DeliveryFrequency.daily,
        weekdayPrice: 8.0,
        weekendPrice: 10.0,
      ),
      Publication(
        id: 'pub_et',
        nameEn: 'The Economic Times',
        nameHi: 'इकोनॉमिक टाइम्स',
        type: PublicationType.newspaper,
        defaultFrequency: DeliveryFrequency.weekdaysOnly,
        weekdayPrice: 7.0,
        weekendPrice: 10.0,
      ),
      Publication(
        id: 'pub_indiatoday',
        nameEn: 'India Today (Magazine)',
        nameHi: 'इंडिया टुडे (पत्रिका)',
        type: PublicationType.magazine,
        defaultFrequency: DeliveryFrequency.sundayOnly,
        weekdayPrice: 30.0,
        weekendPrice: 30.0,
      ),
      Publication(
        id: 'pub_champak',
        nameEn: 'Champak (Kids Magazine)',
        nameHi: 'चंपक (बाल पत्रिका)',
        type: PublicationType.magazine,
        defaultFrequency: DeliveryFrequency.weekendsOnly,
        weekdayPrice: 25.0,
        weekendPrice: 25.0,
      ),
    ];
  }

  static List<Customer> defaultCustomers() {
    final now = DateTime.now();
    return [
      Customer(
        id: 'cust_1',
        sequenceNo: 1,
        name: 'Rajesh Sharma / राजेश शर्मा',
        houseNumber: 'A-101',
        block: 'Block A',
        area: 'Shanti Nagar Society',
        phone: '9876543210',
        status: DeliveryStatus.started,
        subscriptions: const [
          SubscriptionItem(
            publicationId: 'pub_bhaskar',
            frequency: DeliveryFrequency.daily,
            quantity: 1,
          ),
          SubscriptionItem(
            publicationId: 'pub_toi',
            frequency: DeliveryFrequency.weekendsOnly,
            quantity: 1,
          ),
        ],
        statusHistory: [
          StatusLog(
            status: DeliveryStatus.started,
            timestamp: now.subtract(const Duration(days: 5)),
            note: 'Added Newspaper: The Times of India (Weekends)',
          ),
          StatusLog(
            status: DeliveryStatus.started,
            timestamp: now.subtract(const Duration(days: 15)),
            note: 'Regular subscription started (Dainik Bhaskar)',
          ),
        ],
        notes: 'Drop inside main gate / मुख्य गेट के अंदर डालें',
      ),
      Customer(
        id: 'cust_2',
        sequenceNo: 2,
        name: 'Amit Verma / अमित वर्मा',
        houseNumber: 'A-104',
        block: 'Block A',
        area: 'Shanti Nagar Society',
        phone: '9811122233',
        status: DeliveryStatus.paused,
        pauseStartDate: now.subtract(const Duration(days: 1)),
        pauseEndDate: now.add(const Duration(days: 4)),
        pauseReason: 'Out of station with family / परिवार के साथ बाहर गए हैं',
        subscriptions: const [
          SubscriptionItem(
            publicationId: 'pub_jagran',
            frequency: DeliveryFrequency.daily,
            quantity: 1,
          ),
          SubscriptionItem(
            publicationId: 'pub_indiatoday',
            frequency: DeliveryFrequency.sundayOnly,
            quantity: 1,
          ),
        ],
        statusHistory: [
          StatusLog(
            status: DeliveryStatus.paused,
            timestamp: now.subtract(const Duration(days: 1)),
            note: 'Paused for 5 days (Out of station with family)',
          ),
        ],
        notes: '1st Floor Balcony / पहली मंजिल की बालकनी',
      ),
      Customer(
        id: 'cust_3',
        sequenceNo: 3,
        name: 'Dr. S. K. Gupta / डॉ. एस. के. गुप्ता',
        houseNumber: 'B-12',
        block: 'Block B',
        area: 'Green Park Colony',
        phone: '9822233344',
        status: DeliveryStatus.started,
        subscriptions: const [
          SubscriptionItem(
            publicationId: 'pub_hindu',
            frequency: DeliveryFrequency.daily,
            quantity: 1,
          ),
          SubscriptionItem(
            publicationId: 'pub_et',
            frequency: DeliveryFrequency.weekdaysOnly,
            quantity: 1,
          ),
          SubscriptionItem(
            publicationId: 'pub_bhaskar',
            frequency: DeliveryFrequency.daily,
            quantity: 1,
          ),
        ],
        statusHistory: [
          StatusLog(
            status: DeliveryStatus.started,
            timestamp: now.subtract(const Duration(days: 8)),
            note: 'Added Newspaper: The Economic Times (Mon-Fri)',
          ),
          StatusLog(
            status: DeliveryStatus.started,
            timestamp: now.subtract(const Duration(days: 25)),
            note: 'Clinic & Residence papers started',
          ),
        ],
        notes: 'Give to guard at gate / गेट पर गार्ड को दें',
      ),
      Customer(
        id: 'cust_4',
        sequenceNo: 4,
        name: 'Suresh Patel / सुरेश पटेल',
        houseNumber: 'B-18',
        block: 'Block B',
        area: 'Green Park Colony',
        phone: '9988776655',
        status: DeliveryStatus.paused,
        pauseReason: 'Paused until further notice / अगले आदेश तक बंद',
        subscriptions: const [
          SubscriptionItem(
            publicationId: 'pub_bhaskar',
            frequency: DeliveryFrequency.daily,
            quantity: 1,
          ),
        ],
        statusHistory: [
          StatusLog(
            status: DeliveryStatus.paused,
            timestamp: now.subtract(const Duration(days: 3)),
            note: 'Paused until further notice',
          ),
          StatusLog(
            status: DeliveryStatus.paused,
            timestamp: now.subtract(const Duration(days: 10)),
            note: 'Removed Newspaper: Dainik Jagran',
          ),
        ],
      ),
      Customer(
        id: 'cust_5',
        sequenceNo: 5,
        name: 'Priya Nair / प्रिया नायर',
        houseNumber: 'C-202',
        block: 'Block C',
        area: 'Sunrise Apartments',
        phone: '9765432109',
        status: DeliveryStatus.started,
        subscriptions: const [
          SubscriptionItem(
            publicationId: 'pub_toi',
            frequency: DeliveryFrequency.daily,
            quantity: 1,
          ),
          SubscriptionItem(
            publicationId: 'pub_champak',
            frequency: DeliveryFrequency.weekendsOnly,
            quantity: 1,
          ),
        ],
        statusHistory: [
          StatusLog(
            status: DeliveryStatus.started,
            timestamp: now.subtract(const Duration(days: 20)),
            note: 'Started daily TOI + Weekend magazine',
          ),
        ],
        notes: 'Keep in door holder / दरवाजे के होल्डर में रखें',
      ),
    ];
  }

  static List<NewspaperEvent> defaultNewspaperEvents() {
    final now = DateTime.now();
    return [
      NewspaperEvent(
        id: 'evt_1',
        eventType: NewspaperEventType.newStart,
        customerId: 'cust_1',
        customerName: 'Rajesh Sharma / राजेश शर्मा',
        houseNumber: 'A-101',
        block: 'Block A',
        area: 'Shanti Nagar Society',
        deliveryBoyId: 'user_delivery_1',
        deliveryBoyName: 'Ramesh Kumar (हॉकर)',
        newspaperName: 'Dainik Jagran (दैनिक जागरण)',
        publicationId: 'pub_jagran',
        quantity: 1,
        timestamp: now.subtract(const Duration(days: 15)),
        note: 'New subscription started / नया अखबार शुरू किया',
      ),
      NewspaperEvent(
        id: 'evt_2',
        eventType: NewspaperEventType.newStart,
        customerId: 'cust_2',
        customerName: 'Amit Verma / अमित वर्मा',
        houseNumber: 'A-104',
        block: 'Block A',
        area: 'Shanti Nagar Society',
        deliveryBoyId: 'user_delivery_1',
        deliveryBoyName: 'Ramesh Kumar (हॉकर)',
        newspaperName: 'Amar Ujala (अमर उजाला)',
        publicationId: 'pub_ujala',
        quantity: 1,
        timestamp: now.subtract(const Duration(days: 12)),
        note: 'New customer subscribed',
      ),
      NewspaperEvent(
        id: 'evt_3',
        eventType: NewspaperEventType.paused,
        customerId: 'cust_2',
        customerName: 'Amit Verma / अमित वर्मा',
        houseNumber: 'A-104',
        block: 'Block A',
        area: 'Shanti Nagar Society',
        deliveryBoyId: 'user_delivery_1',
        deliveryBoyName: 'Ramesh Kumar (हॉकर)',
        newspaperName: 'Amar Ujala (अमर उजाला)',
        publicationId: 'pub_ujala',
        quantity: 1,
        timestamp: now.subtract(const Duration(days: 1)),
        pauseStartDate: now.subtract(const Duration(days: 1)),
        pauseEndDate: now.add(const Duration(days: 4)),
        note: 'Out of station with family / परिवार के साथ बाहर गए हैं',
      ),
      NewspaperEvent(
        id: 'evt_4',
        eventType: NewspaperEventType.newStart,
        customerId: 'cust_3',
        customerName: 'Dr. S. K. Gupta / डॉ. एस. के. गुप्ता',
        houseNumber: 'B-12',
        block: 'Block B',
        area: 'Shanti Nagar Society',
        deliveryBoyId: 'user_delivery_1',
        deliveryBoyName: 'Ramesh Kumar (हॉकर)',
        newspaperName: 'The Times of India',
        publicationId: 'pub_toi',
        quantity: 1,
        timestamp: now.subtract(const Duration(days: 25)),
        note: 'Clinic & Residence paper started',
      ),
      NewspaperEvent(
        id: 'evt_5',
        eventType: NewspaperEventType.paused,
        customerId: 'cust_4',
        customerName: 'Suresh Patel / सुरेश पटेल',
        houseNumber: 'B-18',
        block: 'Block B',
        area: 'Green Park Colony',
        deliveryBoyId: 'user_delivery_1',
        deliveryBoyName: 'Ramesh Kumar (हॉकर)',
        newspaperName: 'Dainik Bhaskar (दैनिक भास्कर)',
        publicationId: 'pub_bhaskar',
        quantity: 1,
        timestamp: now.subtract(const Duration(days: 3)),
        note: 'Paused until further notice / अगले आदेश तक बंद',
      ),
      NewspaperEvent(
        id: 'evt_6',
        eventType: NewspaperEventType.deleted,
        customerId: 'cust_4',
        customerName: 'Suresh Patel / सुरेश पटेल',
        houseNumber: 'B-18',
        block: 'Block B',
        area: 'Green Park Colony',
        deliveryBoyId: 'user_delivery_1',
        deliveryBoyName: 'Ramesh Kumar (हॉकर)',
        newspaperName: 'Dainik Jagran (दैनिक जागरण)',
        publicationId: 'pub_jagran',
        quantity: 1,
        timestamp: now.subtract(const Duration(days: 10)),
        note: 'Removed Newspaper: Dainik Jagran',
      ),
      NewspaperEvent(
        id: 'evt_7',
        eventType: NewspaperEventType.started,
        customerId: 'cust_5',
        customerName: 'Priya Nair / प्रिया नायर',
        houseNumber: 'C-202',
        block: 'Block C',
        area: 'Sunrise Apartments',
        deliveryBoyId: 'user_delivery_1',
        deliveryBoyName: 'Ramesh Kumar (हॉकर)',
        newspaperName: 'The Times of India',
        publicationId: 'pub_toi',
        quantity: 1,
        timestamp: now.subtract(const Duration(days: 20)),
        note: 'Started daily TOI + Weekend magazine',
      ),
    ];
  }
}
