import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  String get appTitle;
  String get login;
  String get logout;
  String get email;
  String get password;
  String get loginButton;
  String get loggingIn;
  String get loginFailed;
  String get invalidCredentials;
  String get sales;
  String get products;
  String get categories;
  String get customers;
  String get orders;
  String get reports;
  String get settings;
  String get cart;
  String get emptyCart;
  String get addToCart;
  String get removeFromCart;
  String get clearCart;
  String get saveCart;
  String get savedCarts;
  String get loadCart;
  String get deleteCart;
  String get checkout;
  String get payment;
  String get cash;
  String get card;
  String get cashReceived;
  String get change;
  String get cardLastDigits;
  String get completePayment;
  String get insufficientCash;
  String get enterCardDigits;
  String get subtotal;
  String get tax;
  String get discount;
  String get total;
  String get quantity;
  String get price;
  String get amount;
  String get orderComplete;
  String get orderCode;
  String get orderDate;
  String get paymentMethod;
  String get printReceipt;
  String get newSale;
  String get session;
  String get openRegister;
  String get closeRegister;
  String get openingCash;
  String get closingCash;
  String get expectedCash;
  String get actualCash;
  String get difference;
  String get cashSales;
  String get cardSales;
  String get totalSales;
  String get sessionNotes;
  String get closeSession;
  String get sessionClosed;
  String get noActiveSession;
  String get openSessionFirst;
  String get search;
  String get searchProducts;
  String get searchCustomers;
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
  String get customer;
  String get walkInCustomer;
  String get selectCustomer;
  String get noCustomer;
  String get productNotFound;
  String get outOfStock;
  String get inStock;
  String get lowStock;
  String get language;
  String get english;
  String get french;
  String get currency;
  String get receipt;
  String get thankYou;
  String get pleaseReturn;
  String get enterDenominations;
  String get quickCash;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }
  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale".'
  );
}
