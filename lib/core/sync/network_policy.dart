import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/connectivity_service.dart';

/// Decision from the network policy about whether a transfer should proceed.
enum TransferDecision {
  /// Transfer is allowed to proceed.
  allow,

  /// Transfer should wait for WiFi (user has WiFi-only setting enabled).
  waitForWifi,

  /// Transfer blocked: mobile data cap exceeded this month.
  dataCapExceeded,

  /// No network available.
  offline,
}

enum TransferIntent { backgroundSync, userInitiatedPlayback }

/// Controls how the sync engine behaves on different network types.
///
/// User preferences (persisted in SharedPreferences):
/// - **syncOnMobileData**: Whether uploads/downloads run on cellular (default: false)
/// - **mobileDataCapMb**: Monthly mobile data budget in MB (default: 100)
/// - **downloadQuality**: 'original' or 'compressed' for mobile downloads
///
/// The policy adapts chunk sizes, concurrency, and throttling based on
/// connection type to be a good citizen on metered networks.
class NetworkPolicy {
  final SharedPreferences _prefs;

  // SharedPreferences keys
  static const _keySyncOnMobile = 'sync_on_mobile_data';
  static const _keyMobileDataCap = 'mobile_data_cap_mb';
  static const _keyDownloadQuality = 'sync_download_quality';
  static const _keyMobileUsedBytes = 'sync_mobile_used_bytes_month';
  static const _keyMobileUsedMonth = 'sync_mobile_used_month';

  NetworkPolicy(this._prefs);

  // ---------------------------------------------------------------------------
  // User preferences
  // ---------------------------------------------------------------------------

  bool get syncOnMobileData => _prefs.getBool(_keySyncOnMobile) ?? false;

  Future<void> setSyncOnMobileData(bool value) =>
      _prefs.setBool(_keySyncOnMobile, value);

  int get mobileDataCapMb => _prefs.getInt(_keyMobileDataCap) ?? 100;

  Future<void> setMobileDataCapMb(int mb) =>
      _prefs.setInt(_keyMobileDataCap, mb);

  String get downloadQuality =>
      _prefs.getString(_keyDownloadQuality) ?? 'original';

  Future<void> setDownloadQuality(String quality) =>
      _prefs.setString(_keyDownloadQuality, quality);

  // ---------------------------------------------------------------------------
  // Transfer decisions
  // ---------------------------------------------------------------------------

  /// Determine if a transfer of [sizeBytes] is allowed right now.
  TransferDecision canTransfer(
    int sizeBytes,
    ConnectionType connectionType, {
    TransferIntent intent = TransferIntent.backgroundSync,
  }) {
    switch (connectionType) {
      case ConnectionType.none:
        return TransferDecision.offline;
      case ConnectionType.wifi:
      case ConnectionType.ethernet:
        return TransferDecision.allow;
      case ConnectionType.mobile:
        final allowOnMobile = switch (intent) {
          TransferIntent.backgroundSync => syncOnMobileData,
          TransferIntent.userInitiatedPlayback => true,
        };
        if (!allowOnMobile) return TransferDecision.waitForWifi;
        final capBytes = mobileDataCapMb * 1024 * 1024;
        final used = _mobileUsedBytesThisMonth();
        if (used + sizeBytes > capBytes) {
          return TransferDecision.dataCapExceeded;
        }
        return TransferDecision.allow;
    }
  }

  /// Chunk size for uploads/downloads: 5 MB on WiFi, 1 MB on mobile.
  int chunkSizeBytes(ConnectionType connectionType) {
    return connectionType == ConnectionType.mobile
        ? 1 * 1024 * 1024
        : 5 * 1024 * 1024;
  }

  /// Throttle rate in bytes/second. Null on WiFi (unlimited), 256 KB/s mobile.
  int? throttleBytesPerSec(ConnectionType connectionType) {
    return connectionType == ConnectionType.mobile ? 256 * 1024 : null;
  }

  /// Max concurrent uploads: 2 on WiFi, 1 on mobile.
  int maxConcurrentUploads(ConnectionType connectionType) {
    return connectionType == ConnectionType.mobile ? 1 : 2;
  }

  /// Max concurrent downloads: 3 on WiFi, 1 on mobile.
  int maxConcurrentDownloads(ConnectionType connectionType) {
    return connectionType == ConnectionType.mobile ? 1 : 3;
  }

  // ---------------------------------------------------------------------------
  // Mobile data tracking
  // ---------------------------------------------------------------------------

  /// Record bytes transferred on mobile data.
  Future<void> recordMobileUsage(int bytes) async {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month}';
    final storedMonth = _prefs.getString(_keyMobileUsedMonth);

    if (storedMonth != currentMonth) {
      // New month — reset counter
      await _prefs.setString(_keyMobileUsedMonth, currentMonth);
      await _prefs.setInt(_keyMobileUsedBytes, bytes);
    } else {
      final current = _prefs.getInt(_keyMobileUsedBytes) ?? 0;
      await _prefs.setInt(_keyMobileUsedBytes, current + bytes);
    }
  }

  /// Mobile data used this month in bytes.
  int mobileUsedBytesThisMonth() => _mobileUsedBytesThisMonth();

  int _mobileUsedBytesThisMonth() {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month}';
    final storedMonth = _prefs.getString(_keyMobileUsedMonth);
    if (storedMonth != currentMonth) return 0;
    return _prefs.getInt(_keyMobileUsedBytes) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Connection type resolution
  // ---------------------------------------------------------------------------

  /// Convert connectivity_plus results to our simplified [ConnectionType].
  static ConnectionType resolveConnectionType(
    List<ConnectivityResult> results,
  ) {
    if (results.contains(ConnectivityResult.wifi)) return ConnectionType.wifi;
    if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectionType.ethernet;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectionType.mobile;
    }
    return ConnectionType.none;
  }
}
