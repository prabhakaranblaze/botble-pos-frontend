import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  // Auth
  String get appTitle;
  String get login;
  String get logout;
  String get email;
  String get password;
  String get username;
  String get loginButton;
  String get loggingIn;
  String get loginFailed;
  String get invalidCredentials;
  String get deviceName;
  String get deviceNameHint;
  String get enterPassword;
  String get unlockScreen;
  String get locked;
  String get logoutConfirm;

  // Navigation
  String get sales;
  String get products;
  String get categories;
  String get customers;
  String get orders;
  String get reports;
  String get settings;

  // Cart
  String get cart;
  String get emptyCart;
  String get addToCart;
  String get removeFromCart;
  String get clearCart;
  String get clearCartConfirm;
  String get clearCartMessage;
  String get saveCart;
  String get savedCarts;
  String get loadCart;
  String get deleteCart;
  String get cartName;
  String get enterCartName;
  String get cartHeldSuccess;
  String get cartLoadedSuccess;
  String get userNotLoggedIn;
  String get clear;

  // Checkout/Payment
  String get checkout;
  String get payment;
  String get cash;
  String get card;
  String get cashReceived;
  String get change;
  String get cardLastDigits;
  String get cardLastDigitsHint;
  String get completePayment;
  String get insufficientCash;
  String get enterCardDigits;
  String get payNow;
  String get processing;

  // Amounts
  String get subtotal;
  String get tax;
  String get discount;
  String get total;
  String get quantity;
  String get price;
  String get amount;
  String get shipping;
  String get shippingAmount;
  String get enterShippingAmount;
  String get shippingUpdated;

  // Coupon
  String get coupon;
  String get couponCode;
  String get enterCouponCode;
  String get applyCoupon;
  String get removeCoupon;
  String get couponApplied;
  String get apply;
  String get applying;

  // Discount
  String get discountDescription;
  String get discountDescriptionHint;
  String get discountApplied;

  // Order
  String get orderComplete;
  String get orderCode;
  String get orderNumber;
  String get orderDate;
  String get dateTime;
  String get paymentMethod;
  String get printReceipt;
  String get newSale;
  String get orderCompleted;
  String get printing;
  String get receiptPrinted;
  String get items;
  String get status;
  String get mode;

  // Session
  String get session;
  String get openRegister;
  String get closeRegister;
  String get openingCash;
  String get openingCashAmount;
  String get closingCash;
  String get closingCashAmount;
  String get expectedCash;
  String get actualCash;
  String get difference;
  String get cashSales;
  String get cardSales;
  String get totalSales;
  String get sessionNotes;
  String get notesOptional;
  String get addNotes;
  String get closeSession;
  String get closingSession;
  String get sessionClosed;
  String get noActiveSession;
  String get noSession;
  String get viewActiveSession;
  String get openSessionFirst;
  String get closeSessionFirst;
  String get closeSessionFirstMessage;
  String get viewSession;
  String get continueSession;
  String get startFresh;
  String get existingSession;
  String get sessionOpen;
  String get openedAt;
  String get openedBy;
  String get duration;
  String get countDenominations;
  String get checkingSession;

  // Search & General
  String get search;
  String get searchProducts;
  String get scanBarcode;
  String get searchCustomers;
  String get searchCustomer;
  String get searchByOrderCode;
  String get noResults;
  String get loading;
  String get error;
  String get retry;
  String get cancel;
  String get confirm;
  String get save;
  String get delete;
  String get edit;
  String get close;
  String get back;
  String get next;
  String get done;
  String get yes;
  String get no;
  String get ok;
  String get update;
  String get refresh;
  String get all;
  String get filter;
  String get sortBy;
  String get current;
  String get useArrowKeys;

  // Customer
  String get customer;
  String get walkIn;
  String get walkInCustomer;
  String get selectCustomer;
  String get noCustomer;
  String get addCustomer;
  String get customerName;
  String get enterName;
  String get enterEmail;
  String get enterEmailOptional;
  String get enterPhone;
  String get deliver;
  String get deliveryAddress;
  String get addAddress;
  String get streetAddress;
  String get enterStreetAddress;
  String get city;
  String get enterCity;
  String get zipCode;
  String get enterZipCode;
  String get phone;
  String get name;

  // Product
  String get productNotFound;
  String get outOfStock;
  String get inStock;
  String get lowStock;
  String get sku;
  String get variation;
  String get qtySold;
  String get revenue;
  String get product;

  // Language
  String get language;
  String get english;
  String get french;
  String get currency;

  // Receipt
  String get receipt;
  String get posReceipt;
  String get thankYou;
  String get pleaseReturn;

  // Denominations
  String get enterDenominations;
  String get quickCash;

  // Dashboard
  String get recentBills;
  String get calculator;
  String get fullScreen;
  String get exitFullScreen;

  // Connectivity
  String get workingOffline;
  String get online;
  String get offline;

  // Export
  String get exportCsv;
  String get exportSuccess;
  String get exportFailed;
  String get noOrdersToExport;
  String get noProductsToExport;

  // Resync
  String get resync;
  String get resyncProducts;
  String get clearAndResyncProducts;
  String get resyncNow;
  String get resyncing;
  String get resyncSuccess;
  String get resyncFailed;

  // Clear Data
  String get clearAllData;
  String get clearAll;
  String get clearingData;
  String get dataCleared;
  String get clearFailed;

  // Printer
  String get printerSettings;
  String get selectPrinter;
  String get defaultPrinter;
  String get defaultPrinterSet;
  String get defaultPrinterCleared;
  String get selectPrinterFirst;
  String get testPrint;
  String get testPrintSuccess;
  String get printFailed;
  String get autoPrintOnPayment;
  String get autoPrintDescription;
  String get usb;
  String get bluetooth;
  String get wifi;
  String get demoPayment;

  // Updates
  String get checkForUpdates;
  String get installUpdate;
  String get updateNow;
  String get updateAvailable;
  String get noUpdatesAvailable;
  String get check;

  // Additional Auth
  String get signInToContinue;
  String get pleaseEnterUsername;
  String get usernameTooShort;
  String get pleaseEnterPassword;
  String get passwordTooShort;
  String get pleaseEnterDeviceName;

  // Lock Screen
  String get sessionLocked;
  String get lockedDueToInactivity;
  String get enterPasswordToUnlock;
  String get unlock;
  String get logoutQuestion;
  String get logoutConfirmWithSession;
  String get logoutInstead;
  String get invalidPassword;

  // Additional UI
  String get changeLanguage;
  String get notes;
  String get exact;
  String get payWithCash;
  String get totalAmount;
  String get createNewCustomer;
  String get add;
  String get emailOptional;
  String get addNewAddress;
  String get pleaseEnterCouponCode;
  String get invalidCouponCode;
  String get applyDiscount;
  String get discountType;
  String get percentage;
  String get fixed;
  String get discountAmount;
  String get updateShipping;
  String get selectVariant;
  String get options;
  String get item;
  String get itemPlural;
  String get unit;
  String get unitPlural;
  String get scanProductsToAdd;
  String get useBarcodeScanner;
  String get noProductsFound;
  String orderCompletedPrinting(String orderCode);
  String get areYouSureRemoveAllItems;
  String get sessionFound;
  String get existingSessionMessage;
  String get couldNotRecoverSession;
  String get enterValidOpeningCash;
  String get dataManagement;
  String get about;
  String get receiptPreview;
  String get version;

  // Dashboard Session
  String get closeSessionFirst;
  String get closeSessionFirstMessage;
  String get viewSession;
  String get viewActiveSession;
  String get noSession;
  String get sessionOpen;
  String get openedAt;
  String get openedBy;
  String get searchByOrderCode;
  String get userNotLoggedIn;
  String get cartHeldSuccess;
  String get cartLoadedSuccess;
  String get searchProductsHint;
  String get refreshProducts;
  String get currentCart;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale".');
}
