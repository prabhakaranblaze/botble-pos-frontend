import 'package:flutter/foundation.dart';
import '../services/update_service.dart';
import '../api/api_service.dart';

/// Provider for managing app update state
class UpdateProvider with ChangeNotifier {
  final ApiService _apiService;
  late final UpdateService _updateService;

  UpdateInfo? _updateInfo;
  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _error;
  String? _downloadedInstallerPath;

  UpdateProvider(this._apiService) {
    _updateService = UpdateService(_apiService);
  }

  // Getters
  UpdateInfo? get updateInfo => _updateInfo;
  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String? get error => _error;
  bool get hasUpdate => _updateInfo?.updateAvailable ?? false;
  bool get isMandatory => _updateInfo?.mandatory ?? false;
  String? get downloadedInstallerPath => _downloadedInstallerPath;

  /// Check for available updates
  Future<void> checkForUpdate() async {
    if (_isChecking) return;

    _isChecking = true;
    _error = null;
    notifyListeners();

    try {
      _updateInfo = await _updateService.checkForUpdate();
      debugPrint('📦 UPDATE PROVIDER: Update available: ${_updateInfo?.updateAvailable}');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ UPDATE PROVIDER: Error checking for update: $e');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Download the update
  Future<bool> downloadUpdate() async {
    if (_isDownloading || _updateInfo?.downloadUrl == null) return false;

    _isDownloading = true;
    _downloadProgress = 0;
    _error = null;
    notifyListeners();

    try {
      final path = await _updateService.downloadUpdate(
        _updateInfo!.downloadUrl!,
        onProgress: (received, total) {
          _downloadProgress = received / total;
          notifyListeners();
        },
      );

      if (path != null) {
        _downloadedInstallerPath = path;
        _isDownloading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Download failed';
        _isDownloading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isDownloading = false;
      notifyListeners();
      return false;
    }
  }

  /// Install the downloaded update
  Future<void> installUpdate() async {
    if (_downloadedInstallerPath == null) {
      _error = 'No installer downloaded';
      notifyListeners();
      return;
    }

    await _updateService.installUpdate(_downloadedInstallerPath!);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get current app version
  String get currentVersion => UpdateService.appVersion;
}
