import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters?.map((key, value) => MapEntry(key, value as Object)),
    );
  }

  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  static Future<void> logLogin({
    String? loginMethod,
  }) async {
    await _analytics.logLogin(
      loginMethod: loginMethod ?? 'unknown',
    );
  }

  static Future<void> logSignUp({
    String? signUpMethod,
  }) async {
    await _analytics.logSignUp(
      signUpMethod: signUpMethod ?? 'unknown',
    );
  }

  static Future<void> logAddToCart({
    String? currency,
    double? value,
    List<AnalyticsEventItem>? items,
  }) async {
    await _analytics.logAddToCart(
      currency: currency,
      value: value,
      items: items,
    );
  }

  static Future<void> logRemoveFromCart({
    String? currency,
    double? value,
    List<AnalyticsEventItem>? items,
  }) async {
    await _analytics.logRemoveFromCart(
      currency: currency,
      value: value,
      items: items,
    );
  }

  static Future<void> logBeginCheckout({
    String? currency,
    double? value,
    List<AnalyticsEventItem>? items,
    String? coupon,
  }) async {
    await _analytics.logBeginCheckout(
      currency: currency,
      value: value,
      items: items,
      coupon: coupon,
    );
  }

  static Future<void> logPurchase({
    String? currency,
    double? value,
    String? transactionId,
    double? tax,
    double? shipping,
    String? coupon,
    List<AnalyticsEventItem>? items,
  }) async {
    await _analytics.logPurchase(
      currency: currency,
      value: value,
      transactionId: transactionId,
      tax: tax,
      shipping: shipping,
      coupon: coupon,
      items: items,
    );
  }

  static Future<void> logViewItem({
    String? currency,
    double? value,
    List<AnalyticsEventItem>? items,
  }) async {
    await _analytics.logViewItem(
      currency: currency,
      value: value,
      items: items,
    );
  }

  static Future<void> logViewItemList({
    String? itemListId,
    String? itemListName,
    List<AnalyticsEventItem>? items,
  }) async {
    await _analytics.logViewItemList(
      itemListId: itemListId,
      itemListName: itemListName,
      items: items,
    );
  }

  static Future<void> logSearch({
    required String searchTerm,
    int? numberOfResults,
  }) async {
    await _analytics.logSearch(
      searchTerm: searchTerm,
    );
  }

  static Future<void> logShare({
    String? contentType,
    String? itemId,
    String? method,
  }) async {
    await _analytics.logShare(
      contentType: contentType ?? 'unknown',
      itemId: itemId ?? 'unknown',
      method: method ?? 'unknown',
    );
  }

  static Future<void> logSelectContent({
    String? contentType,
    String? itemId,
  }) async {
    await _analytics.logSelectContent(
      contentType: contentType ?? 'unknown',
      itemId: itemId ?? 'unknown',
    );
  }

  static Future<void> logAddToWishlist({
    String? currency,
    double? value,
    List<AnalyticsEventItem>? items,
  }) async {
    await _analytics.logAddToWishlist(
      currency: currency,
      value: value,
      items: items,
    );
  }

  static Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  static Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(
      name: name,
      value: value,
    );
  }

  static Future<void> setDefaultEventParameters(Map<String, dynamic>? parameters) async {
    await _analytics.setDefaultEventParameters(parameters);
  }

  static AnalyticsEventItem createItem({
    String? itemId,
    String? itemName,
    String? itemCategory,
    String? itemCategory2,
    String? itemCategory3,
    String? itemCategory4,
    String? itemCategory5,
    String? itemVariant,
    String? itemBrand,
    double? price,
    int? quantity,
    String? currency,
    double? discount,
    int? index,
    String? itemListId,
    String? itemListName,
  }) {
    return AnalyticsEventItem(
      itemId: itemId,
      itemName: itemName,
      itemCategory: itemCategory,
      itemCategory2: itemCategory2,
      itemCategory3: itemCategory3,
      itemCategory4: itemCategory4,
      itemCategory5: itemCategory5,
      itemVariant: itemVariant,
      itemBrand: itemBrand,
      price: price,
      quantity: quantity,
      currency: currency,
      discount: discount,
      index: index,
      itemListId: itemListId,
      itemListName: itemListName,
    );
  }
}