/// Environment Configuration
///
/// Usage:
/// Development (Local Node.js backend):
///   flutter run --dart-define=ENV=dev
///
/// UAT (Staging server):
///   flutter run --dart-define=ENV=uat
///
/// Production (Laravel backend):
///   flutter run --dart-define=ENV=prod
///
/// Build for UAT:
///   flutter build windows --dart-define=ENV=uat
///
/// Build for production:
///   flutter build windows --dart-define=ENV=prod

class EnvConfig {
  // Get environment from compile-time constant
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev', // Default to development
  );

  static bool get isDev => environment == 'dev';
  static bool get isUat => environment == 'uat';
  static bool get isProd => environment == 'prod';

  // API Configuration per environment
  static String get baseUrl {
    switch (environment) {
      case 'prod':
        return 'https://stampsmart.test/api/v1/pos';
      case 'uat':
        return 'https://seypost-posapi-uat.stampsm.art/api/v1/pos';
      case 'dev':
      default:
        return 'http://localhost:3001/api/v1/pos';
    }
  }

  // Image CDN Base URL
  static const String imageBaseUrl = String.fromEnvironment(
    'IMAGE_BASE_URL',
    defaultValue: 'https://pub-1664f164de65435e943bd597c050e247.r2.dev',
  );

  // API Key (same for both environments)
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'GcrrfWGSHhVvwZVh7Skj4GPCQT08skcZ',
  );

  // Debug logging
  static bool get enableDebugLogs => isDev || isUat;

  // Feature flags
  static bool get enableOfflineMode => true;
  static bool get enablePrinterSupport => true;

  // Display info
  static String get environmentName {
    switch (environment) {
      case 'prod':
        return 'Production';
      case 'uat':
        return 'UAT';
      case 'dev':
      default:
        return 'Development';
    }
  }

  static String get environmentBadge {
    switch (environment) {
      case 'prod':
        return '';
      case 'uat':
        return '[UAT]';
      case 'dev':
      default:
        return '[DEV]';
    }
  }

  /// Get full image URL from relative path
  /// Handles both relative paths and already-full URLs
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    // Already a full URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Remove leading slash if present
    final cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;

    return '$imageBaseUrl/$cleanPath';
  }
}
