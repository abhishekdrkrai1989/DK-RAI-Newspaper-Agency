import 'package:flutter/foundation.dart';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import '../models/approval_request.dart';
import '../models/customer.dart';
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
  List<Customer> get allCustomers => List.unmodifiable(_customers);
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

  /// All unique Societies / Colonies
  List<String> get availableAreas {
    final set = <String>{};
    for (final c in _customers) {
      if (c.area.trim().isNotEmpty) {
        set.add(c.area.trim());
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  /// All unique Blocks across the entire customer list (used for form suggestions)
  List<String> get allUniqueBlocks {
    final set = <String>{};
    for (final c in _customers) {
      if (c.block.trim().isNotEmpty) {
        set.add(c.block.trim());
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Blocks available for the currently selected Society (or all blocks if no Society is selected)
  List<String> get availableBlocks {
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
    final list = set.toList()..sort();
    return list;
  }

  int countForSociety(String society) {
    return _customers
        .where((c) => c.area.trim().toLowerCase() == society.toLowerCase())
        .length;
  }

  int countForBlock(String block) {
    return _customers.where((c) {
      if (_selectedArea != null &&
          _selectedArea!.isNotEmpty &&
          c.area.trim().toLowerCase() != _selectedArea!.toLowerCase()) {
        return false;
      }
      return c.block.trim().toLowerCase() == block.toLowerCase();
    }).length;
  }

  /// Customers matching the active Society and Block filters
  List<Customer> get _locationFilteredCustomers {
    return _customers.where((c) {
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
    notifyListeners();
    _triggerAutoSync();
    _recordDeliveryBoyAction(
      actionType: ApprovalActionType.pausePaper,
      title: 'Paper Paused: ${current.name} (${current.houseNumber})',
      description: 'Paused paper delivery${reason.isNotEmpty ? " ($reason)" : ""}',
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

  Future<void> saveCustomer(Customer customer) async {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index >= 0) {
      _customers[index] = customer;
    } else {
      _customers.add(customer);
    }
    _customers.sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));
    await _storage.saveCustomers(_customers);
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
  }

  Future<void> deleteCustomer(String customerId) async {
    final index = _customers.indexWhere((c) => c.id == customerId);
    Customer? deletedCust;
    String custName = 'Customer';
    if (index >= 0) {
      deletedCust = _customers[index];
      custName = '${deletedCust.name} (${deletedCust.houseNumber})';
    }
    _customers.removeWhere((c) => c.id == customerId);
    await _storage.saveCustomers(_customers);
    notifyListeners();
    _triggerAutoSync();
    _recordDeliveryBoyAction(
      actionType: ApprovalActionType.deleteCustomer,
      title: 'Customer Deleted: $custName',
      description: 'Removed customer from delivery route',
      targetId: customerId,
      payload: deletedCust?.toJson(),
    );
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
      );
      result = syncRes.result;
      if (syncRes.result.success) {
        _customers = syncRes.customers;
        _publications = syncRes.publications;
        _users = syncRes.deliveryBoys;
        await _storage.saveCustomers(_customers);
        await _storage.savePublications(_publications);
        await _storage.saveUsers(_users);
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
    return result;
  }

  void _triggerAutoSync() {
    if (_autoSync && isCloudConfigured && !_isSyncing) {
      syncWithCloud(forceUpload: true).catchError(
        (_) => CloudSyncResult(
          success: false,
          message: 'Auto-sync failed',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  // ==========================================
  // Role Authentication & Approvals Management
  // ==========================================

  List<AppUser> get deliveryBoys =>
      _users.where((u) => u.isDeliveryBoy).toList();

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
    await _storage.saveCurrentUser(user);
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
    }
  }

  Future<void> clearApprovalHistory() async {
    _approvalRequests.removeWhere((r) => !r.isPending);
    await _storage.saveApprovalRequests(_approvalRequests);
    notifyListeners();
  }
}
