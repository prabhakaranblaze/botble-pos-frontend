import 'package:easy_localization/easy_localization.dart';

/// Coupon error codes returned from the API
class CouponErrorCodes {
  static const String loginRequired = 'LOGIN_REQUIRED';
  static const String notAvailableForCustomer = 'NOT_AVAILABLE_FOR_CUSTOMER';
  static const String alreadyUsed = 'ALREADY_USED';
  static const String minimumOrderAmountNotMet = 'MINIMUM_ORDER_AMOUNT_NOT_MET';
  static const String cannotUseWithPromotion = 'CANNOT_USE_WITH_PROMOTION';
  static const String cannotUseWithFlashSale = 'CANNOT_USE_WITH_FLASH_SALE';
  static const String invalidCoupon = 'INVALID_COUPON';
  
  /// Returns the error message from API or a translated fallback message
  /// Always prioritizes the API message to ensure consistency
  static String getErrorMessage(String? errorCode, String? apiMessage) {
    // Always use API message if available
    if (apiMessage != null && apiMessage.isNotEmpty) {
      return apiMessage;
    }
    
    // Fallback to translated messages (should rarely be used since API provides messages)
    switch (errorCode) {
      case loginRequired:
        return 'cart.coupon_login_required'.tr();
      case notAvailableForCustomer:
        return 'cart.coupon_not_available'.tr();
      case alreadyUsed:
        return 'cart.coupon_already_used'.tr();
      case minimumOrderAmountNotMet:
        return 'cart.coupon_minimum_not_met'.tr();
      case cannotUseWithPromotion:
        return 'cart.coupon_cannot_use_with_promotion'.tr();
      case cannotUseWithFlashSale:
        return 'cart.coupon_cannot_use_with_flash_sale'.tr();
      case invalidCoupon:
        return 'cart.coupon_invalid'.tr();
      default:
        return 'cart.coupon_error'.tr();
    }
  }
}