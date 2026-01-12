import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api/api_service.dart';

// Conditional imports for desktop-only functionality
import 'update_service_stub.dart'
    if (dart.library.io) 'update_service_io.dart' as update_io;

/// Model for update information
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool updateAvailable;
  final bool mandatory;
  final String? downloadUrl;
  final List<String> releaseNotes;
  final String? releaseDate;
  final String? fileSize;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.updateAvailable,
    required this.mandatory,
    this.downloadUrl,
    this.releaseNotes = const [],
    this.releaseDate,
    this.fileSize,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      currentVersion: json['current_version'] ?? '',
      latestVersion: json['latest_version'] ?? '',
      updateAvailable: json['update_available'] ?? false,
      mandatory: json['mandatory'] ?? false,
      downloadUrl: json['download_url'],
      releaseNotes: (json['release_notes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      releaseDate: json['release_date'],
      fileSize: json['file_size'],
    );
  }

  factory UpdateInfo.noUpdate(String currentVersion) {
    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      updateAvailable: false,
      mandatory: false,
    );
  }
}

/// Service for checking and downloading app updates
class UpdateService {
  final ApiService _apiService;
  final Dio _downloadDio;

  /// Current app version from pubspec.yaml
  static const String appVersion = '1.0.0';

  UpdateService(this._apiService) : _downloadDio = Dio();

  /// Check for available updates
  Future<UpdateInfo> checkForUpdate() async {
    debugPrint('📦 UPDATE SERVICE: Checking for updates...');
    debugPrint('📦 UPDATE SERVICE: Current version: $appVersion');

    try {
      final response = await _apiService.checkForUpdate(appVersion);

      if (response != null) {
        final updateInfo = UpdateInfo.fromJson(response);
        debugPrint(
            '📦 UPDATE SERVICE: Latest version: ${updateInfo.latestVersion}');
        debugPrint(
            '📦 UPDATE SERVICE: Update available: ${updateInfo.updateAvailable}');
        return updateInfo;
      }

      return UpdateInfo.noUpdate(appVersion);
    } catch (e) {
      debugPrint('❌ UPDATE SERVICE: Error checking for updates: $e');
      return UpdateInfo.noUpdate(appVersion);
    }
  }

  /// Download the update installer (desktop only)
  /// Returns the path to the downloaded file
  Future<String?> downloadUpdate(
    String downloadUrl, {
    Function(int received, int total)? onProgress,
  }) async {
    // Check if running on web
    if (kIsWeb) {
      debugPrint('📦 UPDATE SERVICE: Updates not supported on web');
      return null;
    }

    debugPrint('📦 UPDATE SERVICE: Downloading update from: $downloadUrl');

    try {
      final savePath = await update_io.getDownloadPath(downloadUrl);
      if (savePath == null) return null;

      debugPrint('📦 UPDATE SERVICE: Saving to: $savePath');

      await _downloadDio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            debugPrint('📦 UPDATE SERVICE: Download progress: $progress%');
            onProgress?.call(received, total);
          }
        },
      );

      debugPrint('✅ UPDATE SERVICE: Download complete: $savePath');
      return savePath;
    } catch (e) {
      debugPrint('❌ UPDATE SERVICE: Download failed: $e');
      return null;
    }
  }

  /// Launch the installer and exit the app (desktop only)
  Future<bool> installUpdate(String installerPath) async {
    // Check if running on web
    if (kIsWeb) {
      debugPrint('📦 UPDATE SERVICE: Updates not supported on web');
      return false;
    }

    debugPrint('📦 UPDATE SERVICE: Installing update from: $installerPath');
    return update_io.installUpdate(installerPath);
  }
}
