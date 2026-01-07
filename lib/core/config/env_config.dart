/// Environment Configuration
///
/// Usage:
/// Development (Node.js backend):
///   flutter run --dart-define=ENV=dev
///
/// Production (Laravel backend):
///   flutter run --dart-define=ENV=prod
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
  static bool get isProd => environment == 'prod';

  // API Configuration per environment
  static String get baseUrl {
    switch (environment) {
      case 'prod':
        return 'https://stampsmart.test/api/v1/pos';
      case 'dev':
      default:
        return 'http://localhost:3001/api/v1/pos';
    }
  }

  // API Key (same for both environments)
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'GcrrfWGSHhVvwZVh7Skj4GPCQT08skcZ',
  );

  // Debug logging
  static bool get enableDebugLogs => isDev;

  // Feature flags
  static bool get enableOfflineMode => true;
  static bool get enablePrinterSupport => true;

  // Display info
  static String get environmentName => isDev ? 'Development' : 'Production';
  static String get environmentBadge => isDev ? '[DEV]' : '';
}
