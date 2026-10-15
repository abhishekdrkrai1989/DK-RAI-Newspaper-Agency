import 'dart:async';
import 'package:flutter/foundation.dart';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import '../models/approval_request.dart';
import '../models/customer.dart';
import '../models/newspaper_event.dart';
import '../models/publication.dart';
import '../services/cloud_sync_service.dart';
import '../services/local_storage_service.dart';

enum DistributionFilter {
  all,
  started,
  paused,
  pendingToday,
}

class DeliveryProvider extends ChangeNotifier {
  final LocalStorageService _storage;
  final CloudSyncService _cloudService;

  late AppLanguage _language;
  late List<Publication> _publications;
  late List<Customer> _customers;
  late List<NewspaperEvent> _newspaperEvents;
  late List<String> _customBlocks;

  late List<AppUser> _users;
  AppUser? _currentUser;
  late List<ApprovalRequest> _approvalRequests;

  String _supabaseUrl = '';
  String _supabaseAnonKey = '';
  bool _autoSync = true;
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  String? _lastSyncMessage;
  bool _lastSyncSuccess = true;
  bool _pendingAutoSync = false;

  DistributionFilter _filter = DistributionFilter.all;
  String? _selectedArea; // Society / Colony filter
  String? _selectedBlock; // Block / Wing / Tower filter
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();

  DeliveryProvider(this._storage, {CloudSyncService? cloudService})
      : _cloudService = cloudService ?? CloudSyncService() {
    _language = _storage.loadLanguage();
    _publications = _storage.loadPublications();
    _customers = _storage.loadCustomers();
    _newspaperEvents = _storage.loadNewspaperEvents();
    _customBlocks = _storage.loadCustomBlocks();
    _supabaseUrl = _storage.loadSupabaseUrl();
    if (_supabaseUrl.isEmpty) {
      _supabaseUrl = LocalStorageService.defaultSupabaseUrl;
    }
    _supabaseAnonKey = _storage.loadSupabaseAnonKey();
    if (_supabaseAnonKey.isEmpty) {
      _supabaseAnonKey = LocalStorageService.defaultSupabaseAnonKey;
    }
    _autoSync = _storage.loadAutoSync();
    _lastSyncTime = _storage.loadLastSyncTime();
    _users = List<AppUser>.from(_storage.loadUsers());
    _currentUser = _storage.loadCurrentUser();
    if (_currentUser != null) {
      _adjustLocationFiltersForUser(_currentUser!);
    }
    _approvalRequests = _storage.loadApprovalRequests();

    // Automatically connect and sync with Supabase cloud DB on launch
    if (isCloudConfigured && _autoSync) {
      Future.delayed(const Duration(milliseconds: 300), () {
        syncWithCloud().catchError(
          (_) => CloudSyncResult(
            success: false,
            message: 'Startup sync skipped',
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  AppLanguage get language => _language;
  AppStrings get strings => AppStrings(_language);
  List<Publication> get publications => List.unmodifiable(_publications);

  /// For Delivery Boy: Returns ONLY customers in their assigned block(s).
  /// For Admin / Owner: Returns all customers.
  List<Customer> get allCustomers {
    if (isDeliveryBoy) {
      return List.unmodifiable(
        _customers.where((c) => canCurrentUserAccessCustomer(c)).toList(),
      );
    }
    return List.unmodifiable(_customers);
  }

  /// Unrestricted customers list for admin and internal syncing
  List<Customer> get adminAllCustomers => List.unmodifiable(_customers);

  List<NewspaperEvent> get newspaperEvents =>
      List.unmodifiable(_newspaperEvents);
  DistributionFilter get filter => _filter;
  String? get selectedArea => _selectedArea;
  String? get selectedBlock => _selectedBlock;
  String get searchQuery => _searchQuery;
  DateTime get selectedDate => _selectedDate;

  // Role Authentication Getters
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isOwner => _currentUser?.isOwner ?? false;
  bool get isDeliveryBoy => _currentUser?.isDeliveryBoy ?? false;
  List<AppUser> get allUsers => List.unmodifiable(_users);

  /// Whether current user has access to view/modify the specified customer.
  /// Admin has full access. Delivery boy can only access customers in assigned blocks.
  bool canCurrentUserAccessCustomer(Customer customer) {
    if (_currentUser == null || _currentUser!.isOwner) return true;
    final block = customer.block.trim().isNotEmpty
        ? customer.block.trim()
        : Customer.inferBlockFromHouseNumber(customer.houseNumber);
    return _currentUser!.canAccessBlock(block);
  }

  /// Whether current user has access to view/modify the specified block.
  bool canCurrentUserAccessBlock(String block) {
    if (_currentUser == null || _currentUser!.isOwner) return true;
    return _currentUser!.canAccessBlock(block);
  }

  // Approval Request Getters
  List<ApprovalRequest> get approvalRequests =>
      List.unmodifiable(_approvalRequests);
  List<ApprovalRequest> get pendingApprovals =>
      _approvalRequests.where((r) => r.isPending).toList();
  int get pendingApprovalsCount => pendingApprovals.length;

  String get supabaseUrl => _supabaseUrl;
  String get supabaseAnonKey => _supabaseAnonKey;
  bool get autoSync => _autoSync;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isSyncing => _isSyncing;
  String? get lastSyncMessage => _lastSyncMessage;
  bool get lastSyncSuccess => _lastSyncSuccess;
  bool get isCloudConfigured =>
      _supabaseUrl.trim().isNotEmpty && _supabaseAnonKey.trim().isNotEmpty;

  bool get hasLocationFilter =>
      (_selectedArea != null && _selectedArea!.isNotEmpty) ||
      (_selectedBlock != null && _selectedBlock!.isNotEmpty);

  Publication? getPublicationById(String id) {
    for (final p in _publications) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// All unique Societies / Colonies (scoped to assigned blocks for delivery boy)
  List<String> get availableAreas {
    final set = <String>{};
    for (final c in _customers) {
      if (isDeliveryBoy && !canCurrentUserAccessCustomer(c)) {
        continue;
      }
      if (c.area.trim().isNotEmpty) {
        set.add(c.area.trim());
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  /// All unique Blocks across customers and custom blocks (scoped for delivery boy)
  List<String> get allUniqueBlocks {
    if (isDeliveryBoy) {
      return List.unmodifiable(_currentUser?.assignedBlocks ?? []);
    }
    final set = <String>{};
    for (final c in _customers) {
      if (c.block.trim().isNotEmpty) {
        set.add(c.block.trim());
      }
    }
    for (final b in _customBlocks) {
      if (b.trim().isNotEmpty) {
        set.add(b.trim());
      }
    }
    for (final u in _users) {
      for (final b in u.assignedBlocks) {
        if (b.trim().isNotEmpty) {
          set.add(b.trim());
        }
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Blocks available for the currently selected Society (strictly scoped for delivery boy)
  List<String> get availableBlocks {
    if (isDeliveryBoy) {
      final assigned = _currentUser?.assignedBlocks ?? [];
      if (_selectedArea != null && _selectedArea!.isNotEmpty) {
        final set = <String>{};
        for (final c in _customers) {
          if (c.area.trim().toLowerCase() == _selectedArea!.toLowerCase() &&
              canCurrentUserAccessBlock(c.block) &&
              c.block.trim().isNotEmpty) {
            set.add(c.block.trim());
          }
        }
        final list = set.toList()..sort();
        return list;
      }
      return List.unmodifiable(assigned);
    }

    final set = <String>{};
    for (final c in _customers) {
      if (_selectedArea != null &&
          _selectedArea!.isNotEmpty &&
          c.area.trim().toLowerCase() != _selectedArea!.toLowerCase()) {
        continue;
      }
      if (c.block.trim().isNotEmpty) {
        set.add(c.block.trim());
      }
    }
    if (_selectedArea == null || _selectedArea!.isEmpty) {
      for (final b in _customBlocks) {
        if (b.trim().isNotEmpty) set.add(b.trim());
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  int countForSociety(String society) {
    return _customers.where((c) {
      if (isDeliveryBoy && !canCurrentUserAccessCustomer(c)) return false;
      return c.area.trim().toLowerCase() == society.toLowerCase();
    }).length;
  }

  int countForBlock(String block) {
    if (isDeliveryBoy && !canCurrentUserAccessBlock(block)) return 0;
    return _customers.where((c) {
      if (isDeliveryBoy && !canCurrentUserAccessCustomer(c)) return false;
      if (_selectedArea != null &&
          _selectedArea!.isNotEmpty &&
          c.area.trim().toLowerCase() != _selectedArea!.toLowerCase()) {
        return false;
      }
      return c.block.trim().toLowerCase() == block.toLowerCase();
    }).length;
  }

  /// Customers matching the active Society and Block filters (restricted to delivery boy's block)
  List<Customer> get _locationFilteredCustomers {
    return _customers.where((c) {
      if (isDeliveryBoy && !canCurrentUserAccessCustomer(c)) {
        return false;
      }
      if (_selectedArea != null && _selectedArea!.isNotEmpty) {
        if (c.area.trim().toLowerCase() != _selectedArea!.toLowerCase()) {
          return false;
        }
      }
      if (_selectedBlock != null && _selectedBlock!.isNotEmpty) {
        if (c.block.trim().toLowerCase() != _selectedBlock!.toLowerCase()) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Filtered distribution list according to Society, Block, Started/Paused tab, and Search query
  List<Customer> get filteredCustomers {
    final q = _searchQuery.trim().toLowerCase();
    return _locationFilteredCustomers.where((c) {
      final isStarted = c.isStartedOnDate(_selectedDate);
      switch (_filter) {
        case DistributionFilter.all:
          break;
        case DistributionFilter.started:
          if (!isStarted) return false;
          break;
        case DistributionFilter.paused:
          if (isStarted) return false;
          break;
        case DistributionFilter.pendingToday:
          if (!isStarted) return false;
          if (c.totalCopiesOnDate(_selectedDate) == 0) return false;
          if (c.isDeliveredOnDate(_selectedDate)) return false;
          break;
      }

      if (q.isNotEmpty) {
        final matchName = c.name.toLowerCase().contains(q);
        final matchHouse = c.houseNumber.toLowerCase().contains(q);
        final matchBlock = c.block.toLowerCase().contains(q);
        final matchArea = c.area.toLowerCase().contains(q);
        final matchPhone = c.phone.toLowerCase().contains(q);
        final matchPub = c.subscriptions.any((sub) {
          final pub = getPublicationById(sub.publicationId);
          if (pub == null) return false;
          return pub.nameEn.toLowerCase().contains(q) ||
              pub.nameHi.toLowerCase().contains(q);
        });
        if (!matchName &&
            !matchHouse &&
            !matchBlock &&
            !matchArea &&
            !matchPhone &&
            !matchPub) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // Summary metrics for the selected date (scoped to active Block/Society filter)
  int get totalCustomersCount => _locationFilteredCustomers.length;

  int get startedCustomersCount => _locationFilteredCustomers
      .where((c) => c.isStartedOnDate(_selectedDate))
      .length;

  int get pausedCustomersCount => _locationFilteredCustomers
      .where((c) => !c.isStartedOnDate(_selectedDate))
      .length;

  int get totalDeliverableCopiesForDate => _locationFilteredCustomers.fold<int>(
        0,
        (sum, c) => sum + c.totalCopiesOnDate(_selectedDate),
      );

  int get deliveredCustomersCountForDate => _locationFilteredCustomers
      .where((c) =>
          c.isStartedOnDate(_selectedDate) &&
          c.isDeliveredOnDate(_selectedDate))
      .length;

  /// Returns a map of Publication -> Total copies required on [_selectedDate]
  /// across all STARTED customers in the active Block/Society filter.
  Map<Publication, int> get bundleCountByPublication {
    final counts = <String, int>{};
    for (final customer in _locationFilteredCustomers) {
      final deliverableSubs =
          customer.deliverableSubscriptionsOnDate(_selectedDate);
      for (final sub in deliverableSubs) {
        counts[sub.publicationId] =
            (counts[sub.publicationId] ?? 0) + sub.quantity;
      }
    }

    final result = <Publication, int>{};
    for (final pub in _publications) {
      final count = counts[pub.id] ?? 0;
      if (count > 0) {
        result[pub] = count;
      }
    }
    return result;
  }

  // UI state setters
  Future<void> toggleLanguage() async {
    _language =
        _language == AppLanguage.en ? AppLanguage.hi : AppLanguage.en;
    await _storage.saveLanguage(_language);
    notifyListeners();
  }

  void setFilter(DistributionFilter newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  void setSelectedArea(String? area) {
    _selectedArea = area;
    // If the currently selected block does not exist in the newly selected society, reset block filter
    if (_selectedBlock != null &&
        !availableBlocks.any(
          (b) => b.toLowerCase() == _selectedBlock!.toLowerCase(),
        )) {
      _selectedBlock = null;
    }
    notifyListeners();
  }

  void setSelectedBlock(String? block) {
    _selectedBlock = block;
    notifyListeners();
  }

  void clearLocationFilters() {
    _selectedArea = null;
    _selectedBlock = null;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  // Customer status actions (Pause / Start) saved immediately to local storage
  Future<void> startCustomerPaper(String customerId, {String note = ''}) async {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index == -1) return;

    final current = _customers[index];
    // Delivery Boy cannot start paper for other blocks
    if (isDeliveryBoy && !canCurrentUserAccessBlock(current.block)) {
      return;
    }

    final log = StatusLog(
      status: DeliveryStatus.started,
      timestamp: DateTime.now(),
      note: note.isEmpty ? 'Paper Started (Resumed)' : note,
    );

    _customers[index] = current.copyWith(
      status: DeliveryStatus.started,
      clearPauseStartDate: true,
      clearPauseEndDate: true,
      pauseReason: '',
      statusHistory: [log, ...current.statusHistory],
    );

    await _storage.saveCustomers(_customers);

    // Record Started event for each subscription
    for (final sub in current.subscriptions) {
      final pub = getPublicationById(sub.publicationId);
      final pubName = pub?.nameEn ?? sub.publicationId;
      await recordNewspaperEvent(
        eventType: NewspaperEventType.started,
        customerId: current.id,
        customerName: current.name,
        houseNumber: current.houseNumber,
        block: current.block,
        area: current.area,
        deliveryBoyId: current.deliveryBoyId,
        deliveryBoyName: current.deliveryBoyName ??
            getAssignedDeliveryBoyNameForCustomer(current),
        newspaperName: pubName,
        publicationId: sub.publicationId,
        quantity: sub.quantity,
        note: note.isNotEmpty ? note : 'Paper resumed',
        skipSync: true,
      );
    }

    notifyListeners();
    _triggerAutoSync();
    _recordDeliveryBoyAction(
      actionType: ApprovalActionType.startPaper,
      title: 'Paper Resumed: ${current.name} (${current.houseNumber})',
      description: 'Resumed paper delivery${note.isNotEmpty ? " ($note)" : ""}',
      targetId: customerId,
    );
  }

  Future<void> pauseCustomerPaper(
    String customerId, {
    DateTime? pauseStartDate,
    DateTime? pauseEndDate,
    String reason = '',
  }) async {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index == -1) return;

    final current = _customers[index];
    // Delivery Boy cannot pause paper for other blocks
    if (isDeliveryBoy && !canCurrentUserAccessBlock(current.block)) {
      return;
    }

    final log = StatusLog(
      status: DeliveryStatus.paused,
      timestamp: DateTime.now(),
      note: reason.isEmpty ? 'Paper Paused' : reason,
    );

    _customers[index] = current.copyWith(
      status: DeliveryStatus.paused,
      pauseStartDate: pauseStartDate,
      clearPauseStartDate: pauseStartDate == null,
      pauseEndDate: pauseEndDate,
      clearPauseEndDate: pauseEndDate == null,
      pauseReason: reason,
      statusHistory: [log, ...current.statusHistory],
    );

    await _storage.saveCustomers(_customers);

    // Record Paused event for each subscription
    for (final sub in current.subscriptions) {
      final pub = getPublicationById(sub.publicationId);
      final pubName = pub?.nameEn ?? sub.publicationId;
      await recordNewspaperEvent(
        eventType: NewspaperEventType.paused,
        customerId: current.id,
        customerName: current.name,
        houseNumber: current.houseNumber,
        block: current.block,
        area: current.area,
        deliveryBoyId: current.deliveryBoyId,
        deliveryBoyName: current.deliveryBoyName ??
            getAssignedDeliveryBoyNameForCustomer(current),
        newspaperName: pubName,
        publicationId: sub.publicationId,
        quantity: sub.quantity,
        pauseStartDate: pauseStartDate,
        pauseEndDate: pauseEndDate,
        note: reason.isNotEmpty ? reason : 'Paper paused',
        skipSync: true,
      );
    }

    notifyListeners();
    _triggerAutoSync();
    _recordDeliveryBoyAction(
      actionType: ApprovalActionType.pausePaper,
      title: 'Paper Paused: ${current.name} (${current.houseNumber})',
      description:
          'Paused paper delivery${reason.isNotEmpty ? " ($reason)" : ""}',
      targetId: customerId,
      payload: {'pauseReason': reason},
    );
  }

  /// Toggle individual newspaper/magazine pause status for a customer
  Future<void> toggleSubscriptionItemPause(
    String customerId,
    String publicationId,
  ) async {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index == -1) return;

    final current = _customers[index];
    // Delivery Boy cannot toggle item pause for other blocks
    if (isDeliveryBoy && !canCurrentUserAccessBlock(current.block)) {
      return;
    }

    final pub = getPublicationById(publicationId);
    final pubName = pub?.nameEn ?? publicationId;
    bool? newPausedState;

    final updatedSubs = current.subscriptions.map((sub) {
      if (sub.publicationId == publicationId) {
        newPausedState = !sub.isPaused;
        return sub.copyWith(isPaused: !sub.isPaused);
      }
      return sub;
    }).toList();

    final updatedHistory = [...current.statusHistory];
    if (newPausedState != null) {
      updatedHistory.insert(
        0,
        StatusLog(
          status:
              newPausedState! ? DeliveryStatus.paused : DeliveryStatus.started,
          timestamp: DateTime.now(),
          note: newPausedState!
              ? 'Paused Paper: $pubName'
              : 'Resumed Paper: $pubName',
        ),
      );

      final matchingSub = current.subscriptions.firstWhere(
        (s) => s.publicationId == publicationId,
        orElse: () =>
            SubscriptionItem(publicationId: publicationId, quantity: 1),
      );

      await recordNewspaperEvent(
        eventType: newPausedState!
            ? NewspaperEventType.paused
            : NewspaperEventType.started,
        customerId: current.id,
        customerName: current.name,
        houseNumber: current.houseNumber,
        block: current.block,
        area: current.area,
        deliveryBoyId: current.deliveryBoyId,
        deliveryBoyName: current.deliveryBoyName ??
            getAssignedDeliveryBoyNameForCustomer(current),
        newspaperName: pubName,
        publicationId: publicationId,
        quantity: matchingSub.quantity,
        note: newPausedState!
            ? 'Item Paused: $pubName'
            : 'Item Resumed: $pubName',
        skipSync: true,
      );
    }

    _customers[index] = current.copyWith(
      subscriptions: updatedSubs,
      statusHistory: updatedHistory,
    );
    await _storage.saveCustomers(_customers);
    notifyListeners();
    _triggerAutoSync();
  }

  /// Toggle daily delivery checkmark for [_selectedDate]
  Future<void> toggleDeliveredForSelectedDate(String customerId) async {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index == -1) return;

    final current = _customers[index];
    // Delivery Boy cannot deliver for other blocks
    if (isDeliveryBoy && !canCurrentUserAccessBlock(current.block)) {
      return;
    }
    final key = Customer.dateKey(_selectedDate);
    final updatedDates = [...current.deliveredDates];
    if (updatedDates.contains(key)) {
      updatedDates.remove(key);
    } else {
      updatedDates.add(key);
    }

    _customers[index] = current.copyWith(deliveredDates: updatedDates);
    await _storage.saveCustomers(_customers);
    notifyListeners();
    _triggerAutoSync();
  }

  Future<bool> saveCustomer(Customer customer) async {
    // Delivery Boy cannot add or edit customer in an unauthorized block
    if (isDeliveryBoy && !canCurrentUserAccessBlock(customer.block)) {
      return false;
    }

    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index >= 0 &&
        isDeliveryBoy &&
        !canCurrentUserAccessBlock(_customers[index].block)) {
      return false;
    }

    final isNew = index < 0;
    if (index >= 0) {
      _customers[index] = customer;
    } else {
      _customers.add(customer);
    }
    _customers.sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));
    await _storage.saveCustomers(_customers);

    if (isNew) {
      for (final sub in customer.subscriptions) {
        final pub = getPublicationById(sub.publicationId);
        final pubName = pub?.nameEn ?? sub.publicationId;
        await recordNewspaperEvent(
          eventType: NewspaperEventType.newStart,
          customerId: customer.id,
          customerName: customer.name,
          houseNumber: customer.houseNumber,
          block: customer.block,
          area: customer.area,
          deliveryBoyId: customer.deliveryBoyId,
          deliveryBoyName: customer.deliveryBoyName ??
              getAssignedDeliveryBoyNameForCustomer(customer),
          newspaperName: pubName,
          publicationId: sub.publicationId,
          quantity: sub.quantity,
          note: 'New Customer Started',
          skipSync: true,
        );
      }
    }

    notifyListeners();
    _triggerAutoSync();
    _recordDeliveryBoyAction(
      actionType: index >= 0
          ? ApprovalActionType.editCustomer
          : ApprovalActionType.addCustomer,
      title: index >= 0
          ? 'Customer Updated: ${customer.name}'
          : 'New Customer Added: ${customer.name}',
      description:
          'House No: ${customer.houseNumber}, Block: ${customer.block}, Area: ${customer.area}',
      targetId: customer.id,
      payload: customer.toJson(),
    );
    return true;
  }

  Future<bool> deleteCustomer(String customerId) async {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index < 0) return false;

    // Delivery Boy cannot delete customer outside their assigned block
    if (isDeliveryBoy && !canCurrentUserAccessBlock(_customers[index].block)) {
      return false;
    }

    final deletedCust = _customers[index];
    final custName = '${deletedCust.name} (${deletedCust.houseNumber})';
    _customers.removeWhere((c) => c.id == customerId);
    await _storage.saveCustomers(_customers);

    for (final sub in deletedCust.subscriptions) {
      final pub = getPublicationById(sub.publicationId);
      final pubName = pub?.nameEn ?? sub.publicationId;
      await recordNewspaperEvent(
        eventType: NewspaperEventType.deleted,
        customerId: deletedCust.id,
        customerName: deletedCust.name,
        houseNumber: deletedCust.houseNumber,
        block: deletedCust.block,
        area: deletedCust.area,
        deliveryBoyId: deletedCust.deliveryBoyId,
        deliveryBoyName: deletedCust.deliveryBoyName ??
            getAssignedDeliveryBoyNameForCustomer(deletedCust),
        newspaperName: pubName,
        publicationId: sub.publicationId,
        quantity: sub.quantity,
        note: 'Customer Removed',
        skipSync: true,
      );
    }

    notifyListeners();
    _triggerAutoSync();
    _cloudService.deleteCustomerFromCloud(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      customerId: customerId,
    ).catchError((_) => false);
    _recordDeliveryBoyAction(
      actionType: ApprovalActionType.deleteCustomer,
      title: 'Customer Deleted: $custName',
      description: 'Removed customer from delivery route',
      targetId: customerId,
      payload: deletedCust.toJson(),
    );
    return true;
  }

  Future<void> savePublication(Publication publication) async {
    final index = _publications.indexWhere((p) => p.id == publication.id);
    if (index >= 0) {
      _publications[index] = publication;
    } else {
      _publications.add(publication);
    }
    await _storage.savePublications(_publications);
    notifyListeners();
    _triggerAutoSync();
    _recordDeliveryBoyAction(
      actionType: ApprovalActionType.addPublication,
      title: 'Paper Added/Updated: ${publication.nameEn}',
      description:
          'Weekday Price: ₹${publication.weekdayPrice}, Weekend: ₹${publication.weekendPrice}',
      targetId: publication.id,
      payload: publication.toJson(),
    );
  }

  Future<void> deletePublication(String publicationId) async {
    final pub = getPublicationById(publicationId);
    final pubName = pub?.nameEn ?? publicationId;
    _publications.removeWhere((p) => p.id == publicationId);
    await _storage.savePublications(_publications);
    notifyListeners();
    _triggerAutoSync();
    _cloudService.deletePublicationFromCloud(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      publicationId: publicationId,
    ).catchError((_) => false);
    _recordDeliveryBoyAction(
      actionType: ApprovalActionType.deletePublication,
      title: 'Paper Deleted: $pubName',
      description: 'Removed newspaper from catalog',
      targetId: publicationId,
      payload: pub?.toJson(),
    );
  }

  Future<void> resetDemoData() async {
    await _storage.resetToDemoData();
    _publications = _storage.loadPublications();
    _customers = _storage.loadCustomers();
    notifyListeners();
    _triggerAutoSync();
  }

  // --- Cloud Sync (Supabase Free Cloud DB) ---

  Future<CloudSyncResult> testCloudConnection(String url, String anonKey) async {
    return _cloudService.testConnection(url: url, anonKey: anonKey);
  }

  Future<void> saveCloudConfig({
    required String url,
    required String anonKey,
    required bool autoSync,
  }) async {
    _supabaseUrl = CloudSyncService.sanitizeUrl(url);
    _supabaseAnonKey = anonKey.trim();
    _autoSync = autoSync;
    await _storage.saveSupabaseUrl(_supabaseUrl);
    await _storage.saveSupabaseAnonKey(_supabaseAnonKey);
    await _storage.saveAutoSync(_autoSync);
    notifyListeners();
  }

  Future<CloudSyncResult> syncWithCloud({
    bool forceUpload = false,
    bool forceDownload = false,
  }) async {
    if (!isCloudConfigured) {
      final res = CloudSyncResult(
        success: false,
        message:
            'Cloud database is not configured. Please enter your Supabase URL & Key.',
        timestamp: DateTime.now(),
      );
      _lastSyncMessage = res.message;
      _lastSyncSuccess = false;
      notifyListeners();
      return res;
    }

    _isSyncing = true;
    _lastSyncMessage = null;
    notifyListeners();

    CloudSyncResult result;

    if (forceUpload) {
      result = await _cloudService.uploadAll(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
        customers: _customers,
        publications: _publications,
        users: _users,
        events: _newspaperEvents,
      );
    } else if (forceDownload) {
      final download = await _cloudService.downloadAll(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
      );
      result = download.result;
      if (download.result.success &&
          download.customers != null &&
          download.publications != null) {
        _customers = download.customers!;
        _publications = download.publications!;
        if (download.deliveryBoys != null && download.deliveryBoys!.isNotEmpty) {
          _users = download.deliveryBoys!;
          await _storage.saveUsers(_users);
        }
        if (download.events != null && download.events!.isNotEmpty) {
          _newspaperEvents = download.events!;
          await _storage.saveNewspaperEvents(_newspaperEvents);
        }
        await _storage.saveCustomers(_customers);
        await _storage.savePublications(_publications);
      }
    } else {
      final syncRes = await _cloudService.syncTwoWay(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
        localCustomers: _customers,
        localPublications: _publications,
        localUsers: _users,
        localEvents: _newspaperEvents,
      );
      result = syncRes.result;
      if (syncRes.result.success) {
        _customers = syncRes.customers;
        _publications = syncRes.publications;
        _users = syncRes.deliveryBoys;
        _newspaperEvents = syncRes.events;
        await _storage.saveCustomers(_customers);
        await _storage.savePublications(_publications);
        await _storage.saveUsers(_users);
        await _storage.saveNewspaperEvents(_newspaperEvents);
      }
    }

    _isSyncing = false;
    _lastSyncSuccess = result.success;
    _lastSyncMessage = result.message;
    if (result.success) {
      _lastSyncTime = DateTime.now();
      await _storage.saveLastSyncTime(_lastSyncTime!);
    }
    notifyListeners();

    if (_pendingAutoSync) {
      _executeAutoSync();
    }

    return result;
  }

  void _triggerAutoSync() {
    if (!_autoSync || !isCloudConfigured) return;
    if (_isSyncing) {
      _pendingAutoSync = true;
      return;
    }
    _executeAutoSync();
  }

  Future<void> _executeAutoSync() async {
    _pendingAutoSync = false;
    try {
      await syncWithCloud(forceUpload: true);
    } catch (_) {}
    if (_pendingAutoSync) {
      _executeAutoSync();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ==========================================
  // Role Authentication & Approvals Management
  // ==========================================

  List<AppUser> get deliveryBoys =>
      _users.where((u) => u.isDeliveryBoy).toList();

  void _adjustLocationFiltersForUser(AppUser user) {
    if (user.isDeliveryBoy) {
      if (user.assignedBlocks.isNotEmpty) {
        if (_selectedBlock == null || !user.canAccessBlock(_selectedBlock!)) {
          _selectedBlock = user.assignedBlocks.first;
        }
      } else {
        _selectedBlock = null;
      }
      if (_selectedArea != null && !availableAreas.contains(_selectedArea)) {
        _selectedArea = null;
      }
    }
  }

  Future<bool> login(String userId, String pin) async {
    final user = _users.firstWhere(
      (u) => u.id == userId,
      orElse: () => const AppUser(id: '', name: '', role: UserRole.deliveryBoy, pin: ''),
    );
    if (user.id.isNotEmpty && user.pin == pin) {
      if (!user.isActive && !user.isOwner) {
        return false;
      }
      _currentUser = user;
      _adjustLocationFiltersForUser(user);
      await _storage.saveCurrentUser(_currentUser);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _storage.saveCurrentUser(null);
    notifyListeners();
  }

  AppUser get ownerUser => _users.firstWhere(
        (u) => u.isOwner,
        orElse: () => AppUser.defaultUsers().first,
      );

  Future<void> updateOwnerProfile({
    String? name,
    String? phone,
    required String newPin,
  }) async {
    final index = _users.indexWhere((u) => u.isOwner);
    if (index != -1) {
      final current = _users[index];
      final updated = current.copyWith(
        name: name?.trim().isNotEmpty == true ? name!.trim() : current.name,
        phone: phone != null ? phone.trim() : current.phone,
        pin: newPin.trim(),
      );
      _users[index] = updated;
      if (_currentUser?.isOwner == true) {
        _currentUser = updated;
        await _storage.saveCurrentUser(_currentUser);
      }
      await _storage.saveUsers(_users);
      notifyListeners();
      _triggerAutoSync();
    }
  }

  Future<void> switchUser(AppUser user) async {
    _currentUser = user;
    _adjustLocationFiltersForUser(user);
    await _storage.saveCurrentUser(user);
    notifyListeners();
  }

  // ==========================================
  // Block & Hawker Assignment Management
  // ==========================================

  List<String> get customBlocks => List.unmodifiable(_customBlocks);

  /// All unique blocks across customers, custom blocks, and delivery boys
  List<String> get allManagedBlocks {
    final set = <String>{};
    for (final c in _customers) {
      if (c.block.trim().isNotEmpty) set.add(c.block.trim());
    }
    for (final b in _customBlocks) {
      if (b.trim().isNotEmpty) set.add(b.trim());
    }
    for (final u in _users) {
      for (final b in u.assignedBlocks) {
        if (b.trim().isNotEmpty) set.add(b.trim());
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Finds the delivery boy assigned to a block
  AppUser? getDeliveryBoyForBlock(String block) {
    final target = block.trim().toLowerCase();
    for (final boy in deliveryBoys) {
      if (boy.assignedBlocks.any((b) => b.trim().toLowerCase() == target)) {
        return boy;
      }
    }
    return null;
  }

  /// Adds a new custom block, optionally assigning it immediately to a delivery boy
  Future<void> addCustomBlock(String block, {String? assignToBoyId}) async {
    final trimmed = block.trim();
    if (trimmed.isEmpty) return;

    if (!_customBlocks.any((b) => b.toLowerCase() == trimmed.toLowerCase())) {
      _customBlocks.add(trimmed);
      _customBlocks.sort();
      await _storage.saveCustomBlocks(_customBlocks);
    }

    if (assignToBoyId != null && assignToBoyId.isNotEmpty) {
      await assignBlockToDeliveryBoy(trimmed, assignToBoyId);
    } else {
      notifyListeners();
      _triggerAutoSync();
    }
  }

  /// Assigns a block to a specific delivery boy (or unassigns if boyId is null/empty)
  Future<void> assignBlockToDeliveryBoy(String block, String? boyId) async {
    final targetBlock = block.trim();
    if (targetBlock.isEmpty) return;
    final lower = targetBlock.toLowerCase();

    bool usersModified = false;

    for (int i = 0; i < _users.length; i++) {
      final user = _users[i];
      if (!user.isDeliveryBoy) continue;

      if (boyId != null && boyId.isNotEmpty && user.id == boyId) {
        // Add to this delivery boy if not already present
        if (!user.assignedBlocks.any((b) => b.trim().toLowerCase() == lower)) {
          final updatedBlocks = [...user.assignedBlocks, targetBlock]..sort();
          String updatedArea = user.assignedArea;
          if (updatedArea.trim().isEmpty) {
            updatedArea = targetBlock;
          } else if (!updatedArea.toLowerCase().contains(lower)) {
            updatedArea = '$targetBlock, $updatedArea';
          }
          _users[i] = user.copyWith(
            assignedBlocks: updatedBlocks,
            assignedArea: updatedArea,
          );
          usersModified = true;
        }
      } else {
        // Remove from other delivery boys
        if (user.assignedBlocks.any((b) => b.trim().toLowerCase() == lower)) {
          final updatedBlocks = user.assignedBlocks
              .where((b) => b.trim().toLowerCase() != lower)
              .toList();
          final parts = user.assignedArea
              .split(',')
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty && p.toLowerCase() != lower)
              .toList();
          _users[i] = user.copyWith(
            assignedBlocks: updatedBlocks,
            assignedArea: parts.join(', '),
          );
          usersModified = true;
        }
      }
    }

    if (usersModified) {
      if (_currentUser != null) {
        final currentIdx = _users.indexWhere((u) => u.id == _currentUser!.id);
        if (currentIdx != -1) {
          _currentUser = _users[currentIdx];
          await _storage.saveCurrentUser(_currentUser);
        }
      }
      await _storage.saveUsers(_users);
    }

    // Also update deliveryBoyId and deliveryBoyName for all customers in this block
    final assignedBoy = (boyId != null && boyId.isNotEmpty)
        ? _users.firstWhere(
            (u) => u.id == boyId,
            orElse: () => const AppUser(
              id: '',
              name: '',
              role: UserRole.deliveryBoy,
              pin: '',
            ),
          )
        : null;

    bool custsModified = false;
    for (int i = 0; i < _customers.length; i++) {
      if (_customers[i].block.trim().toLowerCase() == lower) {
        _customers[i] = _customers[i].copyWith(
          deliveryBoyId: assignedBoy?.id ?? '',
          deliveryBoyName: assignedBoy?.name ?? '',
        );
        custsModified = true;
      }
    }

    if (custsModified) {
      await _storage.saveCustomers(_customers);
    }

    notifyListeners();
    _triggerAutoSync();
  }

  /// Unassigns a block from all delivery boys
  Future<void> unassignBlock(String block) async {
    await assignBlockToDeliveryBoy(block, null);
  }

  /// Removes a custom block
  Future<void> removeCustomBlock(String block) async {
    final lower = block.trim().toLowerCase();
    _customBlocks.removeWhere((b) => b.trim().toLowerCase() == lower);
    await _storage.saveCustomBlocks(_customBlocks);
    await unassignBlock(block);
    notifyListeners();
  }

  Future<void> saveDeliveryBoy(AppUser boy) async {
    final index = _users.indexWhere((u) => u.id == boy.id);
    if (index >= 0) {
      _users[index] = boy;
      if (_currentUser?.id == boy.id) {
        _currentUser = boy;
        await _storage.saveCurrentUser(_currentUser);
      }
    } else {
      _users.add(boy);
    }

    // Ensure customers in boy's assigned blocks reflect this delivery boy
    bool custModified = false;
    for (int i = 0; i < _customers.length; i++) {
      if (boy.canAccessBlock(_customers[i].block)) {
        if (_customers[i].deliveryBoyId.isEmpty || _customers[i].deliveryBoyId == boy.id) {
          _customers[i] = _customers[i].copyWith(
            deliveryBoyId: boy.id,
            deliveryBoyName: boy.name,
          );
          custModified = true;
        }
      }
    }
    if (custModified) {
      await _storage.saveCustomers(_customers);
    }

    await _storage.saveUsers(_users);
    notifyListeners();
    _triggerAutoSync();
  }

  Future<bool> deleteDeliveryBoy(String boyId) async {
    final index = _users.indexWhere((u) => u.id == boyId);
    if (index == -1) return false;
    if (_users[index].isOwner) return false;

    _users.removeAt(index);
    await _storage.saveUsers(_users);

    if (_currentUser?.id == boyId) {
      _currentUser = _users.firstWhere((u) => u.isOwner, orElse: () => _users.first);
      await _storage.saveCurrentUser(_currentUser);
    }

    notifyListeners();
    _triggerAutoSync();
    _cloudService.deleteDeliveryBoyFromCloud(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      boyId: boyId,
    ).catchError((_) => false);
    return true;
  }

  Future<void> toggleDeliveryBoyActive(String boyId) async {
    final index = _users.indexWhere((u) => u.id == boyId);
    if (index == -1) return;
    final current = _users[index];
    _users[index] = current.copyWith(isActive: !current.isActive);
    if (_currentUser?.id == boyId) {
      _currentUser = _users[index];
      await _storage.saveCurrentUser(_currentUser);
    }
    await _storage.saveUsers(_users);
    notifyListeners();
    _triggerAutoSync();
  }

  Future<void> _recordDeliveryBoyAction({
    required ApprovalActionType actionType,
    required String title,
    required String description,
    required String targetId,
    Map<String, dynamic>? payload,
  }) async {
    // Only delivery boy actions require review & approval by owner
    if (_currentUser?.role != UserRole.deliveryBoy) return;

    final request = ApprovalRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}_${_approvalRequests.length}',
      actionType: actionType,
      title: title,
      description: description,
      targetId: targetId,
      requestedBy: _currentUser?.name ?? 'Delivery Boy',
      requestedAt: DateTime.now(),
      status: ApprovalStatus.pending,
      payload: payload ?? const {},
    );

    _approvalRequests = [request, ..._approvalRequests];
    await _storage.saveApprovalRequests(_approvalRequests);
    notifyListeners();
  }

  Future<void> approveRequest(String requestId) async {
    final index = _approvalRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final current = _approvalRequests[index];
    final updated = current.copyWith(
      status: ApprovalStatus.approved,
      reviewedBy: _currentUser?.name ?? 'Owner',
      reviewedAt: DateTime.now(),
    );

    _approvalRequests[index] = updated;
    await _storage.saveApprovalRequests(_approvalRequests);
    notifyListeners();
    _triggerAutoSync();
  }

  Future<void> rejectRequest(String requestId, {String? reason}) async {
    final index = _approvalRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final req = _approvalRequests[index];
    final updated = req.copyWith(
      status: ApprovalStatus.rejected,
      reviewedBy: _currentUser?.name ?? 'Owner',
      reviewedAt: DateTime.now(),
      reviewNote: reason ?? 'Action reverted by Owner',
    );
    _approvalRequests[index] = updated;

    // Rollback / Revert the action made by the delivery boy
    switch (req.actionType) {
      case ApprovalActionType.pausePaper:
        // Revert pause -> Resume paper
        final custIdx = _customers.indexWhere((c) => c.id == req.targetId);
        if (custIdx != -1) {
          final cust = _customers[custIdx];
          _customers[custIdx] = cust.copyWith(
            status: DeliveryStatus.started,
            pauseReason: '',
            statusHistory: [
              StatusLog(
                status: DeliveryStatus.started,
                timestamp: DateTime.now(),
                note: 'Pause rejected by Owner - paper resumed',
              ),
              ...cust.statusHistory,
            ],
          );
          await _storage.saveCustomers(_customers);
        }
        break;

      case ApprovalActionType.startPaper:
        // Revert start -> Pause paper
        final custIdx = _customers.indexWhere((c) => c.id == req.targetId);
        if (custIdx != -1) {
          final cust = _customers[custIdx];
          _customers[custIdx] = cust.copyWith(
            status: DeliveryStatus.paused,
            pauseReason: 'Start rejected by Owner',
            statusHistory: [
              StatusLog(
                status: DeliveryStatus.paused,
                timestamp: DateTime.now(),
                note: 'Start rejected by Owner - paper paused',
              ),
              ...cust.statusHistory,
            ],
          );
          await _storage.saveCustomers(_customers);
        }
        break;

      case ApprovalActionType.deleteCustomer:
        // Restore deleted customer from payload
        if (req.payload.isNotEmpty) {
          try {
            final restoredCustomer = Customer.fromJson(req.payload);
            if (!_customers.any((c) => c.id == restoredCustomer.id)) {
              _customers.add(restoredCustomer);
              _customers.sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));
              await _storage.saveCustomers(_customers);
            }
          } catch (_) {}
        }
        break;

      case ApprovalActionType.addCustomer:
        // Revert adding customer -> remove the added customer
        _customers.removeWhere((c) => c.id == req.targetId);
        await _storage.saveCustomers(_customers);
        break;

      case ApprovalActionType.deletePublication:
        // Restore deleted publication
        if (req.payload.isNotEmpty) {
          try {
            final restoredPub = Publication.fromJson(req.payload);
            if (!_publications.any((p) => p.id == restoredPub.id)) {
              _publications.add(restoredPub);
              await _storage.savePublications(_publications);
            }
          } catch (_) {}
        }
        break;

      case ApprovalActionType.addPublication:
        // Revert added publication
        _publications.removeWhere((p) => p.id == req.targetId);
        await _storage.savePublications(_publications);
        break;

      case ApprovalActionType.editCustomer:
        break;
    }

    await _storage.saveApprovalRequests(_approvalRequests);
    notifyListeners();
    _triggerAutoSync();
  }

  Future<void> approveAllPending() async {
    bool hasChanges = false;
    final now = DateTime.now();
    final reviewer = _currentUser?.name ?? 'Owner';

    for (int i = 0; i < _approvalRequests.length; i++) {
      if (_approvalRequests[i].isPending) {
        _approvalRequests[i] = _approvalRequests[i].copyWith(
          status: ApprovalStatus.approved,
          reviewedBy: reviewer,
          reviewedAt: now,
        );
        hasChanges = true;
      }
    }

    if (hasChanges) {
      await _storage.saveApprovalRequests(_approvalRequests);
      notifyListeners();
      _triggerAutoSync();
    }
  }

  Future<void> clearApprovalHistory() async {
    _approvalRequests.removeWhere((r) => !r.isPending);
    await _storage.saveApprovalRequests(_approvalRequests);
    notifyListeners();
  }

  // ==========================================
  // Newspaper Events & Breakdown Analytics
  // ==========================================

  Future<void> recordNewspaperEvent({
    required NewspaperEventType eventType,
    required String customerName,
    String customerId = '',
    String houseNumber = '',
    String block = '',
    required String area,
    String? deliveryBoyId,
    String? deliveryBoyName,
    required String newspaperName,
    String publicationId = '',
    int quantity = 1,
    DateTime? pauseStartDate,
    DateTime? pauseEndDate,
    String note = '',
    bool skipSync = false,
  }) async {
    final boyId = (deliveryBoyId != null && deliveryBoyId.isNotEmpty)
        ? deliveryBoyId
        : (_currentUser?.id ?? '');
    final boyName = (deliveryBoyName != null && deliveryBoyName.isNotEmpty)
        ? deliveryBoyName
        : (_currentUser?.name ?? '');

    final event = NewspaperEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}_${_newspaperEvents.length + 1}',
      eventType: eventType,
      customerId: customerId,
      customerName: customerName,
      houseNumber: houseNumber,
      block: block,
      area: area,
      deliveryBoyId: boyId,
      deliveryBoyName: boyName,
      newspaperName: newspaperName,
      publicationId: publicationId,
      quantity: quantity,
      timestamp: DateTime.now(),
      pauseStartDate: pauseStartDate,
      pauseEndDate: pauseEndDate,
      note: note,
    );

    _newspaperEvents = [event, ..._newspaperEvents];
    await _storage.saveNewspaperEvents(_newspaperEvents);
    if (!skipSync) {
      notifyListeners();
      _triggerAutoSync();
    }
  }

  String getAssignedDeliveryBoyNameForCustomer(Customer customer) {
    if (customer.deliveryBoyName != null &&
        customer.deliveryBoyName!.trim().isNotEmpty) {
      return customer.deliveryBoyName!.trim();
    }
    if (customer.deliveryBoyId != null &&
        customer.deliveryBoyId!.trim().isNotEmpty) {
      final boy = _users.firstWhere(
        (u) => u.id == customer.deliveryBoyId,
        orElse: () => const AppUser(
          id: '',
          name: '',
          role: UserRole.deliveryBoy,
          pin: '',
        ),
      );
      if (boy.name.isNotEmpty) return boy.name;
    }
    // Match by block assignment
    final blockMatch = _users.firstWhere(
      (u) => u.isDeliveryBoy && u.canAccessBlock(customer.block),
      orElse: () => const AppUser(
        id: '',
        name: '',
        role: UserRole.deliveryBoy,
        pin: '',
      ),
    );
    if (blockMatch.name.isNotEmpty) return blockMatch.name;

    // Match by area
    final match = _users.firstWhere(
      (u) =>
          u.isDeliveryBoy &&
          u.assignedArea.trim().isNotEmpty &&
          u.assignedArea.toLowerCase() == customer.area.toLowerCase(),
      orElse: () => const AppUser(
        id: '',
        name: '',
        role: UserRole.deliveryBoy,
        pin: '',
      ),
    );
    if (match.name.isNotEmpty) return match.name;
    return 'Not Assigned';
  }

  /// Returns customers belonging to a delivery boy (by ID, assigned block, or area)
  List<Customer> getCustomersForDeliveryBoy(String boyId) {
    final boy = _users.firstWhere(
      (u) => u.id == boyId,
      orElse: () => const AppUser(
        id: '',
        name: '',
        role: UserRole.deliveryBoy,
        pin: '',
      ),
    );
    return _customers.where((c) {
      if (c.deliveryBoyId != null && c.deliveryBoyId!.isNotEmpty) {
        return c.deliveryBoyId == boyId;
      }
      if (boy.canAccessBlock(c.block)) {
        return true;
      }
      if (boy.assignedArea.isNotEmpty) {
        return c.area.toLowerCase() == boy.assignedArea.toLowerCase();
      }
      return false;
    }).toList();
  }

  /// Delivery Boy-wise Breakdown Summary
  Map<String, dynamic> getDeliveryBoyBreakdown(String? boyId) {
    final List<Customer> matchedCusts;
    final List<NewspaperEvent> matchedEvents;

    if (boyId == null || boyId.isEmpty) {
      matchedCusts = _customers;
      matchedEvents = _newspaperEvents;
    } else {
      matchedCusts = getCustomersForDeliveryBoy(boyId);
      final boy = _users.firstWhere(
        (u) => u.id == boyId,
        orElse: () => const AppUser(
          id: '',
          name: '',
          role: UserRole.deliveryBoy,
          pin: '',
        ),
      );
      matchedEvents = _newspaperEvents.where((e) {
        if (e.deliveryBoyId.isNotEmpty && e.deliveryBoyId == boyId) return true;
        if (boy.assignedArea.isNotEmpty &&
            e.area.toLowerCase() == boy.assignedArea.toLowerCase()) {
          return true;
        }
        return false;
      }).toList();
    }

    int activeCopies = 0;
    int pausedCopies = 0;
    final pubCopies = <String, int>{};

    for (final c in matchedCusts) {
      final isStarted = c.isStartedOnDate(_selectedDate);
      for (final s in c.subscriptions) {
        final pub = getPublicationById(s.publicationId);
        final pubName = pub?.nameEn ?? s.publicationId;
        if (isStarted && !s.isPaused) {
          activeCopies += s.quantity;
          pubCopies[pubName] = (pubCopies[pubName] ?? 0) + s.quantity;
        } else {
          pausedCopies += s.quantity;
        }
      }
    }

    final newStartCount = matchedEvents
        .where((e) => e.eventType == NewspaperEventType.newStart)
        .length;
    final startedCount = matchedEvents
        .where((e) => e.eventType == NewspaperEventType.started)
        .length;
    final pausedCount = matchedEvents
        .where((e) => e.eventType == NewspaperEventType.paused)
        .length;
    final deletedCount = matchedEvents
        .where((e) => e.eventType == NewspaperEventType.deleted)
        .length;

    return {
      'totalCustomers': matchedCusts.length,
      'activeCopies': activeCopies,
      'pausedCopies': pausedCopies,
      'pubCopies': pubCopies,
      'newStartCount': newStartCount,
      'startedCount': startedCount,
      'pausedCount': pausedCount,
      'deletedCount': deletedCount,
      'events': matchedEvents,
    };
  }

  /// Area-wise Breakdown Summary
  Map<String, dynamic> getAreaBreakdown(String? area, [String? block]) {
    final List<Customer> matchedCusts;
    final List<NewspaperEvent> matchedEvents;

    if (area == null || area.isEmpty) {
      matchedCusts = _customers;
      matchedEvents = _newspaperEvents;
    } else {
      matchedCusts = _customers.where((c) {
        if (c.area.toLowerCase() != area.toLowerCase()) return false;
        if (block != null &&
            block.isNotEmpty &&
            c.block.toLowerCase() != block.toLowerCase()) {
          return false;
        }
        return true;
      }).toList();

      matchedEvents = _newspaperEvents.where((e) {
        if (e.area.toLowerCase() != area.toLowerCase()) return false;
        if (block != null &&
            block.isNotEmpty &&
            e.block.toLowerCase() != block.toLowerCase()) {
          return false;
        }
        return true;
      }).toList();
    }

    int activeCopies = 0;
    int pausedCopies = 0;
    final pubCopies = <String, int>{};

    for (final c in matchedCusts) {
      final isStarted = c.isStartedOnDate(_selectedDate);
      for (final s in c.subscriptions) {
        final pub = getPublicationById(s.publicationId);
        final pubName = pub?.nameEn ?? s.publicationId;
        if (isStarted && !s.isPaused) {
          activeCopies += s.quantity;
          pubCopies[pubName] = (pubCopies[pubName] ?? 0) + s.quantity;
        } else {
          pausedCopies += s.quantity;
        }
      }
    }

    final newStartCount = matchedEvents
        .where((e) => e.eventType == NewspaperEventType.newStart)
        .length;
    final startedCount = matchedEvents
        .where((e) => e.eventType == NewspaperEventType.started)
        .length;
    final pausedCount = matchedEvents
        .where((e) => e.eventType == NewspaperEventType.paused)
        .length;
    final deletedCount = matchedEvents
        .where((e) => e.eventType == NewspaperEventType.deleted)
        .length;

    return {
      'totalCustomers': matchedCusts.length,
      'activeCopies': activeCopies,
      'pausedCopies': pausedCopies,
      'pubCopies': pubCopies,
      'newStartCount': newStartCount,
      'startedCount': startedCount,
      'pausedCount': pausedCount,
      'deletedCount': deletedCount,
      'events': matchedEvents,
    };
  }

  Future<void> clearNewspaperEvents() async {
    _newspaperEvents.clear();
    await _storage.saveNewspaperEvents(_newspaperEvents);
    notifyListeners();
  }
}
