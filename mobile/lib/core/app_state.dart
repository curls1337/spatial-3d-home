import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/seed_data.dart';
import '../models/app_models.dart';

class AppConfigFlags {
  static const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'demo');
  static const bool enableDemoRoleSwitcher = bool.fromEnvironment(
    'ENABLE_DEMO_ROLE_SWITCHER',
    defaultValue: true,
  );
  static const bool lidarFallbackSimulation = bool.fromEnvironment(
    'LIDAR_FALLBACK_SIMULATION',
    defaultValue: true,
  );
}

class AppState extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isDarkMode = true;
  UserRole _currentRole = UserRole.owner;
  int _selectedTabIndex = 0;

  String _selectedRoomId = 'room-living';
  String? _inventoryRoomFilterId;
  String _searchQuery = '';
  AssetCategory? _categoryFilter;
  VerificationStatus? _statusFilter;

  bool _biometricLockEnabled = true;
  bool _autoBlurPii = true;
  bool _offlineOnly = true;
  bool _syncWifiOnly = true;
  String _serverUrl = 'https://sync.spatialhome.example/api/v1';
  int _pendingSyncCount = 0;

  late List<Room3D> _rooms;
  late List<AssetItem> _assets;
  late List<ActivityEvent> _activities;
  late List<ShareLinkItem> _shareLinks;

  AppState() {
    _loadSeeds();
  }

  void _loadSeeds() {
    _rooms = SeedData.initialRooms();
    _assets = SeedData.initialAssets();
    _activities = SeedData.initialActivities();
    _shareLinks = SeedData.initialShareLinks();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isDarkMode => _isDarkMode;
  UserRole get currentRole => _currentRole;
  int get selectedTabIndex => _selectedTabIndex;
  String get selectedRoomId => _selectedRoomId;
  String? get inventoryRoomFilterId => _inventoryRoomFilterId;
  String get searchQuery => _searchQuery;
  AssetCategory? get categoryFilter => _categoryFilter;
  VerificationStatus? get statusFilter => _statusFilter;
  bool get biometricLockEnabled => _biometricLockEnabled;
  bool get autoBlurPii => _autoBlurPii;
  bool get offlineOnly => _offlineOnly;
  bool get syncWifiOnly => _syncWifiOnly;
  String get serverUrl => _serverUrl;
  int get pendingSyncCount => _pendingSyncCount;

  List<Room3D> get rooms => List.unmodifiable(_rooms);
  List<ActivityEvent> get activities => List.unmodifiable(_activities);
  List<ShareLinkItem> get shareLinks => List.unmodifiable(_shareLinks);

  List<AssetItem> get visibleAssets =>
      _assets.where((a) => a.isVisibleTo(_currentRole)).toList();

  List<AssetItem> get filteredAssets {
    return visibleAssets.where((asset) {
      if (_inventoryRoomFilterId != null && asset.roomId != _inventoryRoomFilterId) {
        return false;
      }
      if (_categoryFilter != null && asset.category != _categoryFilter) {
        return false;
      }
      if (_statusFilter != null && asset.verificationStatus != _statusFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final roomName = roomById(asset.roomId)?.name.toLowerCase() ?? '';
        if (!asset.name.toLowerCase().contains(q) &&
            !asset.serialNumber.toLowerCase().contains(q) &&
            !roomName.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Room3D? roomById(String id) {
    for (final r in _rooms) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<AssetItem> assetsInRoom(String roomId) =>
      visibleAssets.where((a) => a.roomId == roomId).toList();

  double get totalAreaSqm =>
      _rooms.fold<double>(0, (sum, r) => sum + r.areaSqm);

  int get verifiedRoomsCount => _rooms.where((r) => r.scanVerified).length;

  double get totalPurchaseValue {
    if (!_currentRole.canViewFinancials) return 0;
    return visibleAssets.fold<double>(0, (sum, a) => sum + a.purchasePrice);
  }

  double get totalCurrentValuation {
    if (!_currentRole.canViewFinancials) return 0;
    return visibleAssets.fold<double>(0, (sum, a) => sum + a.effectiveValuation);
  }

  double get verifiedAssetsPct {
    final list = visibleAssets;
    if (list.isEmpty) return 0;
    final verified =
        list.where((a) => a.verificationStatus == VerificationStatus.verified).length;
    return (verified / list.length) * 100.0;
  }

  int get flaggedAssetsCount => visibleAssets
      .where((a) => a.verificationStatus == VerificationStatus.flagged)
      .length;

  static String formatIdr(double value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value.round());
  }

  static String formatCompactIdr(double value) {
    if (value >= 1000000000) {
      return 'Rp ${(value / 1000000000).toStringAsFixed(2)}M';
    }
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
    }
    return formatIdr(value);
  }

  void loginWithRole(UserRole role) {
    _currentRole = role;
    _isAuthenticated = true;
    _selectedTabIndex = 0;
    notifyListeners();
  }

  void switchRole(UserRole role) {
    _currentRole = role;
    _inventoryRoomFilterId = null;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _selectedTabIndex = 0;
    notifyListeners();
  }

  void setTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void selectRoom(String roomId) {
    _selectedRoomId = roomId;
    notifyListeners();
  }

  void openInventoryForRoom(String roomId) {
    _inventoryRoomFilterId = roomId;
    _selectedTabIndex = 1;
    notifyListeners();
  }

  void setInventoryRoomFilter(String? roomId) {
    _inventoryRoomFilterId = roomId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(AssetCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setStatusFilter(VerificationStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void resetInventoryFilters() {
    _inventoryRoomFilterId = null;
    _searchQuery = '';
    _categoryFilter = null;
    _statusFilter = null;
    notifyListeners();
  }

  void completeLidarScan({bool addNewRoom = false}) {
    if (!_currentRole.canScanLidar) return;
    if (addNewRoom && !_rooms.any((r) => r.id == 'room-guest')) {
      _rooms = [
        ..._rooms,
        const Room3D(
          id: 'room-guest',
          name: 'Guest Bedroom',
          floorLevel: 2,
          areaSqm: 16.5,
          widthM: 4.1,
          depthM: 4.02,
          heightM: 3.0,
          offsetX: 3.4,
          offsetY: 3.3,
          offsetZ: 2.2,
          scanVerified: true,
          scanSource: 'Apple RoomPlan LiDAR',
          accentColor: Color(0xFF10B981),
        ),
      ];
      _selectedRoomId = 'room-guest';
      _prependActivity(
        'Scan LiDAR Guest Bedroom selesai (16.5 m²)',
        '14,820 vertices • Akurasi ±1.2 cm • On-Device',
        VerificationStatus.verified,
      );
    } else {
      _rooms = _rooms.map((r) {
        if (r.id == 'room-kitchen' || r.id == _selectedRoomId) {
          return r.copyWith(
            scanVerified: true,
            scanSource: 'Apple RoomPlan LiDAR',
          );
        }
        return r;
      }).toList();
      _prependActivity(
        'Pembaruan Scan 3D LiDAR terverifikasi',
        'Mesh ruangan diperbarui 100% on-device tanpa upload video',
        VerificationStatus.verified,
      );
    }
    _pendingSyncCount += 1;
    notifyListeners();
  }

  void addAsset(AssetItem asset) {
    if (!_currentRole.canCreateOrDeleteAsset) return;
    _assets = [asset, ..._assets];
    _pendingSyncCount += 1;
    _prependActivity(
      'Aset baru ditambahkan: ${asset.name}',
      'Terikat pada koordinat (${asset.pinX.toStringAsFixed(1)}, ${asset.pinY.toStringAsFixed(1)}, ${asset.pinZ.toStringAsFixed(1)})',
      asset.verificationStatus,
    );
    notifyListeners();
  }

  void updateAsset(AssetItem updated) {
    if (!_currentRole.canEditOwnerFields) return;
    _assets = _assets.map((a) => a.id == updated.id ? updated : a).toList();
    _pendingSyncCount += 1;
    _prependActivity(
      'Detail aset diperbarui: ${updated.name}',
      'Perubahan disimpan di brankas AES-256 lokal',
      updated.verificationStatus,
    );
    notifyListeners();
  }

  void verifyAppraisal({
    required String assetId,
    required double appraisedValue,
    required VerificationStatus status,
    required String note,
  }) {
    if (!_currentRole.canAppraiseAsset) return;
    _assets = _assets.map((a) {
      if (a.id != assetId) return a;
      return a.copyWith(
        appraisedValue: appraisedValue,
        verificationStatus: status,
        appraisalNote: note,
      );
    }).toList();
    _pendingSyncCount += 1;
    final target = _assets.firstWhere((a) => a.id == assetId);
    _prependActivity(
      'Audit Appraiser: ${target.name} (${status.label})',
      'Taksiran diperbarui tanpa menimpa harga beli asli',
      status,
    );
    notifyListeners();
  }

  void addTenantConditionNote({
    required String assetId,
    required String note,
  }) {
    _assets = _assets.map((a) {
      if (a.id != assetId) return a;
      return a.copyWith(
        tenantConditionNote: note,
        verificationStatus: VerificationStatus.flagged,
      );
    }).toList();
    _pendingSyncCount += 1;
    final target = _assets.firstWhere((a) => a.id == assetId);
    _prependActivity(
      'Catatan Tenant: ${target.name}',
      note,
      VerificationStatus.flagged,
    );
    notifyListeners();
  }

  void deleteOrArchiveAsset(String assetId) {
    if (!_currentRole.canCreateOrDeleteAsset) return;
    _assets = _assets.where((a) => a.id != assetId).toList();
    _pendingSyncCount += 1;
    _prependActivity(
      'Aset dihapus dari inventaris lokal',
      'Outbox sync mengantrekan delta penghapusan',
      VerificationStatus.pending,
    );
    notifyListeners();
  }

  void updateSettings({
    bool? biometricLock,
    bool? autoBlurPii,
    bool? offlineOnly,
    bool? syncWifiOnly,
    String? serverUrl,
  }) {
    if (biometricLock != null) _biometricLockEnabled = biometricLock;
    if (autoBlurPii != null) _autoBlurPii = autoBlurPii;
    if (_currentRole.canManageServerConfig) {
      if (offlineOnly != null) _offlineOnly = offlineOnly;
      if (syncWifiOnly != null) _syncWifiOnly = syncWifiOnly;
      if (serverUrl != null && serverUrl.trim().isNotEmpty) {
        _serverUrl = serverUrl.trim();
      }
    }
    notifyListeners();
  }

  void syncNow() {
    _pendingSyncCount = 0;
    _prependActivity(
      'Sinkronisasi delta terenkripsi selesai',
      'Field-level merge terverifikasi dengan $_serverUrl',
      VerificationStatus.verified,
    );
    notifyListeners();
  }

  void createShareLink({
    required UserRole targetRole,
    required String label,
    required int ttlHours,
    required bool hasPin,
  }) {
    if (!_currentRole.canManageShareLinks) return;
    _shareLinks = [
      ShareLinkItem(
        id: 'shr-${DateTime.now().millisecondsSinceEpoch}',
        targetRole: targetRole,
        label: label,
        ttlHours: ttlHours,
        hasPin: hasPin,
        createdAt: DateTime.now(),
      ),
      ..._shareLinks,
    ];
    notifyListeners();
  }

  void revokeShareLink(String id) {
    if (!_currentRole.canManageShareLinks) return;
    _shareLinks = _shareLinks
        .map((s) => s.id == id ? s.copyWith(revoked: true) : s)
        .toList();
    notifyListeners();
  }

  void resetDemoData() {
    _loadSeeds();
    _selectedRoomId = 'room-living';
    _inventoryRoomFilterId = null;
    _searchQuery = '';
    _categoryFilter = null;
    _statusFilter = null;
    _pendingSyncCount = 0;
    notifyListeners();
  }

  void _prependActivity(String title, String subtitle, VerificationStatus status) {
    _activities = [
      ActivityEvent(
        id: 'act-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        subtitle: subtitle,
        timestampLabel: 'Baru saja',
        status: status,
      ),
      ..._activities.take(12),
    ];
  }
}
