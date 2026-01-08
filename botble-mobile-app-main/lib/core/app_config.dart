import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://seypost.stampsm.art';
  static String get apiKey => dotenv.env['API_KEY'] ?? 'GcrrfWGSHhVvwZVh7Skj4GPCQT08skcZ';
  static String appName = dotenv.env['APP_NAME'] ?? 'MartFury';
  static String appEnv = dotenv.env['APP_ENV'] ?? 'development';
  static String testEmail = dotenv.env['TEST_EMAIL'] ?? 'test@example.com';
  static String testPassword = dotenv.env['TEST_PASSWORD'] ?? 'password123';

  static List<String>? adKeys = dotenv.env['AD_KEYS']?.split(',');

  static String helpCenterUrl =
      dotenv.env['HELP_CENTER_URL'] ??
      'https://seypost.stampsm.art/contact';
  static String customerSupportUrl =
      dotenv.env['CUSTOMER_SUPPORT_URL'] ??
      'https://seypost.stampsm.art/contact';
  static String blogUrl =
      dotenv.env['BLOG_URL'] ?? 'https://seypost.stampsm.art/blog';

  // Language Configuration
  static String get defaultLanguage =>
      dotenv.env['DEFAULT_LANGUAGE']?.toLowerCase() ?? 'en';
  static String get defaultLanguageDirection =>
      dotenv.env['DEFAULT_LANGUAGE_DIRECTION']?.toLowerCase() ?? 'ltr';
  
  // Theme Configuration
  static String get defaultThemeMode =>
      dotenv.env['DEFAULT_THEME_MODE']?.toLowerCase() ?? 'system';

  // RTL language mapping
  static const Map<String, bool> _rtlLanguages = {
    'ar': true,  // Arabic
    'he': true,  // Hebrew
    'fa': true,  // Persian/Farsi
    'ur': true,  // Urdu
    'ku': true,  // Kurdish
    'ps': true,  // Pashto
    'sd': true,  // Sindhi
    'yi': true,  // Yiddish
  };

  // Check if a language code is RTL
  static bool isLanguageRtl(String languageCode) {
    return _rtlLanguages[languageCode.toLowerCase()] ?? false;
  }

  // Get the effective RTL status based on language and direction settings
  static bool get isDefaultLanguageRtl {
    // First check if DEFAULT_LANGUAGE_DIRECTION is explicitly set
    if (dotenv.env['DEFAULT_LANGUAGE_DIRECTION'] != null) {
      return defaultLanguageDirection == 'rtl';
    }
    // Otherwise, determine from the language code
    return isLanguageRtl(defaultLanguage);
  }

  // Twitter
  static String? twitterConsumerKey = dotenv.env['TWITTER_CONSUMER_KEY'];
  static String? twitterConsumerSecret = dotenv.env['TWITTER_CONSUMER_SECRET'];
  static String twitterRedirectUri =
      dotenv.env['TWITTER_REDIRECT_URI'] ?? 'martfury://twitter-auth';

  // Google
  static String? googleClientId = dotenv.env['GOOGLE_CLIENT_ID'];
  static String? googleServerClientId = dotenv.env['GOOGLE_SERVER_CLIENT_ID'];

  // Facebook
  static String? facebookAppId = dotenv.env['FACEBOOK_APP_ID'];
  static String? facebookClientToken = dotenv.env['FACEBOOK_CLIENT_TOKEN'];

  // Apple
  static String? appleServiceId = dotenv.env['APPLE_SERVICE_ID'];
  static String? appleTeamId = dotenv.env['APPLE_TEAM_ID'];

  // Social Login Configuration
  static bool get enableAppleSignIn =>
      dotenv.env['ENABLE_APPLE_SIGN_IN']?.toLowerCase() == 'true' &&
      appleServiceId?.isNotEmpty == true &&
      appleTeamId?.isNotEmpty == true;

  static bool get enableGoogleSignIn =>
      dotenv.env['ENABLE_GOOGLE_SIGN_IN']?.toLowerCase() == 'true' &&
      googleClientId?.isNotEmpty == true &&
      googleServerClientId?.isNotEmpty == true;

  static bool get enableFacebookSignIn =>
      dotenv.env['ENABLE_FACEBOOK_SIGN_IN']?.toLowerCase() == 'true' &&
      facebookAppId?.isNotEmpty == true &&
      facebookClientToken?.isNotEmpty == true;

  static bool get enableTwitterSignIn =>
      dotenv.env['ENABLE_TWITTER_SIGN_IN']?.toLowerCase() == 'true' &&
      twitterConsumerKey?.isNotEmpty == true &&
      twitterConsumerSecret?.isNotEmpty == true;

  // Utility method to check if any social login is enabled
  static bool get hasAnySocialLoginEnabled =>
      enableAppleSignIn ||
      enableGoogleSignIn ||
      enableFacebookSignIn ||
      enableTwitterSignIn;

  // Order Upload Proof Configuration
  static bool get enableOrderUploadProof =>
      dotenv.env['ENABLE_ORDER_UPLOAD_PROOF']?.toLowerCase() != 'false';

  // Guest Checkout Configuration
  static bool get enableGuestCheckout =>
      dotenv.env['ENABLE_GUEST_CHECKOUT']?.toLowerCase() == 'true';

  // Product Image Configuration
  static String get productImageThumbnailSize =>
      dotenv.env['PRODUCT_IMAGE_THUMBNAIL_SIZE']?.toLowerCase() ?? 'small';

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }
}
