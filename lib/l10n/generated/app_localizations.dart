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
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'StampSmart POS'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get loggingIn;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidCredentials;

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceName;

  /// No description provided for @deviceNameHint.
  ///
  /// In en, this message translates to:
  /// **'POS Terminal 1'**
  String get deviceNameHint;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @unlockScreen.
  ///
  /// In en, this message translates to:
  /// **'Unlock Screen'**
  String get unlockScreen;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @emptyCart.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get emptyCart;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @removeFromCart.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeFromCart;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCart;

  /// No description provided for @clearCartConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart?'**
  String get clearCartConfirm;

  /// No description provided for @clearCartMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove all items from the cart.'**
  String get clearCartMessage;

  /// No description provided for @saveCart.
  ///
  /// In en, this message translates to:
  /// **'Save Cart'**
  String get saveCart;

  /// No description provided for @savedCarts.
  ///
  /// In en, this message translates to:
  /// **'Saved Carts'**
  String get savedCarts;

  /// No description provided for @loadCart.
  ///
  /// In en, this message translates to:
  /// **'Load Cart'**
  String get loadCart;

  /// No description provided for @deleteCart.
  ///
  /// In en, this message translates to:
  /// **'Delete Cart'**
  String get deleteCart;

  /// No description provided for @cartName.
  ///
  /// In en, this message translates to:
  /// **'Cart Name'**
  String get cartName;

  /// No description provided for @enterCartName.
  ///
  /// In en, this message translates to:
  /// **'Enter cart name...'**
  String get enterCartName;

  /// No description provided for @cartHeldSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cart held successfully!'**
  String get cartHeldSuccess;

  /// No description provided for @cartLoadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cart loaded!'**
  String get cartLoadedSuccess;

  /// No description provided for @userNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'User not logged in'**
  String get userNotLoggedIn;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @cashReceived.
  ///
  /// In en, this message translates to:
  /// **'Cash Received'**
  String get cashReceived;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @cardLastDigits.
  ///
  /// In en, this message translates to:
  /// **'Last 4 digits of card'**
  String get cardLastDigits;

  /// No description provided for @cardLastDigitsHint.
  ///
  /// In en, this message translates to:
  /// **'1234'**
  String get cardLastDigitsHint;

  /// No description provided for @completePayment.
  ///
  /// In en, this message translates to:
  /// **'Complete Payment'**
  String get completePayment;

  /// No description provided for @insufficientCash.
  ///
  /// In en, this message translates to:
  /// **'Insufficient cash received'**
  String get insufficientCash;

  /// No description provided for @enterCardDigits.
  ///
  /// In en, this message translates to:
  /// **'Please enter last 4 digits'**
  String get enterCardDigits;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @shipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shipping;

  /// No description provided for @shippingAmount.
  ///
  /// In en, this message translates to:
  /// **'Shipping Amount'**
  String get shippingAmount;

  /// No description provided for @enterShippingAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter shipping amount'**
  String get enterShippingAmount;

  /// No description provided for @shippingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Shipping updated!'**
  String get shippingUpdated;

  /// No description provided for @coupon.
  ///
  /// In en, this message translates to:
  /// **'Coupon'**
  String get coupon;

  /// No description provided for @couponCode.
  ///
  /// In en, this message translates to:
  /// **'Coupon Code'**
  String get couponCode;

  /// No description provided for @enterCouponCode.
  ///
  /// In en, this message translates to:
  /// **'Enter coupon code'**
  String get enterCouponCode;

  /// No description provided for @applyCoupon.
  ///
  /// In en, this message translates to:
  /// **'Apply Coupon'**
  String get applyCoupon;

  /// No description provided for @removeCoupon.
  ///
  /// In en, this message translates to:
  /// **'Remove Coupon'**
  String get removeCoupon;

  /// No description provided for @couponApplied.
  ///
  /// In en, this message translates to:
  /// **'Coupon applied successfully!'**
  String get couponApplied;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @applying.
  ///
  /// In en, this message translates to:
  /// **'Applying...'**
  String get applying;

  /// No description provided for @discountDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get discountDescription;

  /// No description provided for @discountDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Staff discount, Loyalty reward'**
  String get discountDescriptionHint;

  /// No description provided for @discountApplied.
  ///
  /// In en, this message translates to:
  /// **'Discount applied successfully!'**
  String get discountApplied;

  /// No description provided for @orderComplete.
  ///
  /// In en, this message translates to:
  /// **'Order Complete'**
  String get orderComplete;

  /// No description provided for @orderCode.
  ///
  /// In en, this message translates to:
  /// **'Order Code'**
  String get orderCode;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get orderNumber;

  /// No description provided for @orderDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get orderDate;

  /// No description provided for @dateTime.
  ///
  /// In en, this message translates to:
  /// **'Date/Time'**
  String get dateTime;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print Receipt'**
  String get printReceipt;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSale;

  /// No description provided for @orderCompleted.
  ///
  /// In en, this message translates to:
  /// **'Order completed!'**
  String get orderCompleted;

  /// No description provided for @printing.
  ///
  /// In en, this message translates to:
  /// **'Printing...'**
  String get printing;

  /// No description provided for @receiptPrinted.
  ///
  /// In en, this message translates to:
  /// **'Receipt printed'**
  String get receiptPrinted;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @openRegister.
  ///
  /// In en, this message translates to:
  /// **'Open Register'**
  String get openRegister;

  /// No description provided for @closeRegister.
  ///
  /// In en, this message translates to:
  /// **'Close Register'**
  String get closeRegister;

  /// No description provided for @openingCash.
  ///
  /// In en, this message translates to:
  /// **'Opening Cash'**
  String get openingCash;

  /// No description provided for @openingCashAmount.
  ///
  /// In en, this message translates to:
  /// **'Opening Cash Amount'**
  String get openingCashAmount;

  /// No description provided for @closingCash.
  ///
  /// In en, this message translates to:
  /// **'Closing Cash'**
  String get closingCash;

  /// No description provided for @closingCashAmount.
  ///
  /// In en, this message translates to:
  /// **'Closing Cash Amount'**
  String get closingCashAmount;

  /// No description provided for @expectedCash.
  ///
  /// In en, this message translates to:
  /// **'Expected Cash'**
  String get expectedCash;

  /// No description provided for @actualCash.
  ///
  /// In en, this message translates to:
  /// **'Actual Cash'**
  String get actualCash;

  /// No description provided for @difference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get difference;

  /// No description provided for @cashSales.
  ///
  /// In en, this message translates to:
  /// **'Cash Sales'**
  String get cashSales;

  /// No description provided for @cardSales.
  ///
  /// In en, this message translates to:
  /// **'Card Sales'**
  String get cardSales;

  /// No description provided for @totalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get totalSales;

  /// No description provided for @sessionNotes.
  ///
  /// In en, this message translates to:
  /// **'Session Notes'**
  String get sessionNotes;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// No description provided for @addNotes.
  ///
  /// In en, this message translates to:
  /// **'Add any notes...'**
  String get addNotes;

  /// No description provided for @closeSession.
  ///
  /// In en, this message translates to:
  /// **'Close Session'**
  String get closeSession;

  /// No description provided for @closingSession.
  ///
  /// In en, this message translates to:
  /// **'Closing Session...'**
  String get closingSession;

  /// No description provided for @sessionClosed.
  ///
  /// In en, this message translates to:
  /// **'Session Closed'**
  String get sessionClosed;

  /// No description provided for @noActiveSession.
  ///
  /// In en, this message translates to:
  /// **'No Active Session'**
  String get noActiveSession;

  /// No description provided for @noSession.
  ///
  /// In en, this message translates to:
  /// **'No Session'**
  String get noSession;

  /// No description provided for @viewActiveSession.
  ///
  /// In en, this message translates to:
  /// **'View Active Session'**
  String get viewActiveSession;

  /// No description provided for @openSessionFirst.
  ///
  /// In en, this message translates to:
  /// **'Please open a register to start selling'**
  String get openSessionFirst;

  /// No description provided for @closeSessionFirst.
  ///
  /// In en, this message translates to:
  /// **'Close Session First'**
  String get closeSessionFirst;

  /// No description provided for @closeSessionFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'You have an active session. Please close your session before logging out.'**
  String get closeSessionFirstMessage;

  /// No description provided for @viewSession.
  ///
  /// In en, this message translates to:
  /// **'View Session'**
  String get viewSession;

  /// No description provided for @continueSession.
  ///
  /// In en, this message translates to:
  /// **'Continue Session'**
  String get continueSession;

  /// No description provided for @startFresh.
  ///
  /// In en, this message translates to:
  /// **'Start Fresh'**
  String get startFresh;

  /// No description provided for @existingSession.
  ///
  /// In en, this message translates to:
  /// **'Existing Session'**
  String get existingSession;

  /// No description provided for @sessionOpen.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get sessionOpen;

  /// No description provided for @openedAt.
  ///
  /// In en, this message translates to:
  /// **'Opened At'**
  String get openedAt;

  /// No description provided for @openedBy.
  ///
  /// In en, this message translates to:
  /// **'Opened By'**
  String get openedBy;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @countDenominations.
  ///
  /// In en, this message translates to:
  /// **'Count Denominations (Optional)'**
  String get countDenominations;

  /// No description provided for @checkingSession.
  ///
  /// In en, this message translates to:
  /// **'Checking for existing session...'**
  String get checkingSession;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode, SKU, or search products...'**
  String get scanBarcode;

  /// No description provided for @searchCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search customers...'**
  String get searchCustomers;

  /// No description provided for @searchCustomer.
  ///
  /// In en, this message translates to:
  /// **'Search customer...'**
  String get searchCustomer;

  /// No description provided for @searchByOrderCode.
  ///
  /// In en, this message translates to:
  /// **'Search by order code...'**
  String get searchByOrderCode;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @useArrowKeys.
  ///
  /// In en, this message translates to:
  /// **'Use arrow keys to select product'**
  String get useArrowKeys;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @walkIn.
  ///
  /// In en, this message translates to:
  /// **'Walk in'**
  String get walkIn;

  /// No description provided for @walkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Customer'**
  String get walkInCustomer;

  /// No description provided for @selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select Customer'**
  String get selectCustomer;

  /// No description provided for @noCustomer.
  ///
  /// In en, this message translates to:
  /// **'No customer selected'**
  String get noCustomer;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get enterEmail;

  /// No description provided for @enterEmailOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter email (optional)'**
  String get enterEmailOptional;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter phone'**
  String get enterPhone;

  /// No description provided for @deliver.
  ///
  /// In en, this message translates to:
  /// **'Deliver'**
  String get deliver;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addAddress;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get streetAddress;

  /// No description provided for @enterStreetAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter street address'**
  String get enterStreetAddress;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @enterCity.
  ///
  /// In en, this message translates to:
  /// **'Enter city'**
  String get enterCity;

  /// No description provided for @zipCode.
  ///
  /// In en, this message translates to:
  /// **'Zip Code'**
  String get zipCode;

  /// No description provided for @enterZipCode.
  ///
  /// In en, this message translates to:
  /// **'Enter zip code'**
  String get enterZipCode;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// No description provided for @sku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get sku;

  /// No description provided for @variation.
  ///
  /// In en, this message translates to:
  /// **'Variation'**
  String get variation;

  /// No description provided for @qtySold.
  ///
  /// In en, this message translates to:
  /// **'Qty Sold'**
  String get qtySold;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @posReceipt.
  ///
  /// In en, this message translates to:
  /// **'POS Receipt'**
  String get posReceipt;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your purchase!'**
  String get thankYou;

  /// No description provided for @pleaseReturn.
  ///
  /// In en, this message translates to:
  /// **'Please come again'**
  String get pleaseReturn;

  /// No description provided for @enterDenominations.
  ///
  /// In en, this message translates to:
  /// **'Enter Denominations'**
  String get enterDenominations;

  /// No description provided for @quickCash.
  ///
  /// In en, this message translates to:
  /// **'Quick Cash'**
  String get quickCash;

  /// No description provided for @recentBills.
  ///
  /// In en, this message translates to:
  /// **'Recent Bills'**
  String get recentBills;

  /// No description provided for @calculator.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get calculator;

  /// No description provided for @fullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full Screen'**
  String get fullScreen;

  /// No description provided for @exitFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Exit Full Screen'**
  String get exitFullScreen;

  /// No description provided for @workingOffline.
  ///
  /// In en, this message translates to:
  /// **'Working Offline - Changes will sync when online'**
  String get workingOffline;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported successfully'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @noOrdersToExport.
  ///
  /// In en, this message translates to:
  /// **'No orders to export'**
  String get noOrdersToExport;

  /// No description provided for @noProductsToExport.
  ///
  /// In en, this message translates to:
  /// **'No products to export'**
  String get noProductsToExport;

  /// No description provided for @resync.
  ///
  /// In en, this message translates to:
  /// **'Resync'**
  String get resync;

  /// No description provided for @resyncProducts.
  ///
  /// In en, this message translates to:
  /// **'Resync Products'**
  String get resyncProducts;

  /// No description provided for @clearAndResyncProducts.
  ///
  /// In en, this message translates to:
  /// **'Clear & Resync Products'**
  String get clearAndResyncProducts;

  /// No description provided for @resyncNow.
  ///
  /// In en, this message translates to:
  /// **'Resync Now'**
  String get resyncNow;

  /// No description provided for @resyncing.
  ///
  /// In en, this message translates to:
  /// **'Resyncing products...'**
  String get resyncing;

  /// No description provided for @resyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Products resynced successfully!'**
  String get resyncSuccess;

  /// No description provided for @resyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Resync failed'**
  String get resyncFailed;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @clearingData.
  ///
  /// In en, this message translates to:
  /// **'Clearing all data...'**
  String get clearingData;

  /// No description provided for @dataCleared.
  ///
  /// In en, this message translates to:
  /// **'All local data cleared and resynced!'**
  String get dataCleared;

  /// No description provided for @clearFailed.
  ///
  /// In en, this message translates to:
  /// **'Clear failed'**
  String get clearFailed;

  /// No description provided for @printerSettings.
  ///
  /// In en, this message translates to:
  /// **'Printer Settings'**
  String get printerSettings;

  /// No description provided for @selectPrinter.
  ///
  /// In en, this message translates to:
  /// **'Select Printer'**
  String get selectPrinter;

  /// No description provided for @defaultPrinter.
  ///
  /// In en, this message translates to:
  /// **'Default Printer'**
  String get defaultPrinter;

  /// No description provided for @defaultPrinterSet.
  ///
  /// In en, this message translates to:
  /// **'Default printer set'**
  String get defaultPrinterSet;

  /// No description provided for @defaultPrinterCleared.
  ///
  /// In en, this message translates to:
  /// **'Default printer cleared'**
  String get defaultPrinterCleared;

  /// No description provided for @selectPrinterFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a printer first'**
  String get selectPrinterFirst;

  /// No description provided for @testPrint.
  ///
  /// In en, this message translates to:
  /// **'Test Print'**
  String get testPrint;

  /// No description provided for @testPrintSuccess.
  ///
  /// In en, this message translates to:
  /// **'Test print sent successfully!'**
  String get testPrintSuccess;

  /// No description provided for @printFailed.
  ///
  /// In en, this message translates to:
  /// **'Print failed'**
  String get printFailed;

  /// No description provided for @autoPrintOnPayment.
  ///
  /// In en, this message translates to:
  /// **'Auto Print on Payment'**
  String get autoPrintOnPayment;

  /// No description provided for @autoPrintDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically print receipt when order is paid'**
  String get autoPrintDescription;

  /// No description provided for @usb.
  ///
  /// In en, this message translates to:
  /// **'USB'**
  String get usb;

  /// No description provided for @bluetooth.
  ///
  /// In en, this message translates to:
  /// **'BT'**
  String get bluetooth;

  /// No description provided for @wifi.
  ///
  /// In en, this message translates to:
  /// **'WiFi'**
  String get wifi;

  /// No description provided for @demoPayment.
  ///
  /// In en, this message translates to:
  /// **'Demo Payment'**
  String get demoPayment;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkForUpdates;

  /// No description provided for @installUpdate.
  ///
  /// In en, this message translates to:
  /// **'Install Update'**
  String get installUpdate;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @noUpdatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No updates available'**
  String get noUpdatesAvailable;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @pleaseEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter your username'**
  String get pleaseEnterUsername;

  /// No description provided for @usernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get usernameTooShort;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @pleaseEnterDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Please enter device name'**
  String get pleaseEnterDeviceName;

  /// No description provided for @sessionLocked.
  ///
  /// In en, this message translates to:
  /// **'Session Locked'**
  String get sessionLocked;

  /// No description provided for @lockedDueToInactivity.
  ///
  /// In en, this message translates to:
  /// **'Locked due to inactivity'**
  String get lockedDueToInactivity;

  /// No description provided for @enterPasswordToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Enter password to unlock'**
  String get enterPasswordToUnlock;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @logoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Logout?'**
  String get logoutQuestion;

  /// No description provided for @logoutConfirmWithSession.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout? Your session will remain open and you can continue later.'**
  String get logoutConfirmWithSession;

  /// No description provided for @logoutInstead.
  ///
  /// In en, this message translates to:
  /// **'Logout Instead'**
  String get logoutInstead;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid password. Please try again.'**
  String get invalidPassword;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes:'**
  String get notes;

  /// No description provided for @exact.
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get exact;

  /// No description provided for @payWithCash.
  ///
  /// In en, this message translates to:
  /// **'Pay with Cash'**
  String get payWithCash;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @createNewCustomer.
  ///
  /// In en, this message translates to:
  /// **'Create New Customer'**
  String get createNewCustomer;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (Optional)'**
  String get emailOptional;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addNewAddress;

  /// No description provided for @pleaseEnterCouponCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a coupon code'**
  String get pleaseEnterCouponCode;

  /// No description provided for @invalidCouponCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid coupon code'**
  String get invalidCouponCode;

  /// No description provided for @applyDiscount.
  ///
  /// In en, this message translates to:
  /// **'Apply Discount'**
  String get applyDiscount;

  /// No description provided for @discountType.
  ///
  /// In en, this message translates to:
  /// **'Discount Type'**
  String get discountType;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get percentage;

  /// No description provided for @fixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get fixed;

  /// No description provided for @discountAmount.
  ///
  /// In en, this message translates to:
  /// **'Discount Amount'**
  String get discountAmount;

  /// No description provided for @updateShipping.
  ///
  /// In en, this message translates to:
  /// **'Update Shipping'**
  String get updateShipping;

  /// No description provided for @selectVariant.
  ///
  /// In en, this message translates to:
  /// **'Select Variant'**
  String get selectVariant;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get item;

  /// No description provided for @itemPlural.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get itemPlural;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'unit'**
  String get unit;

  /// No description provided for @unitPlural.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get unitPlural;

  /// No description provided for @scanProductsToAdd.
  ///
  /// In en, this message translates to:
  /// **'Scan products to add to cart'**
  String get scanProductsToAdd;

  /// No description provided for @useBarcodeScanner.
  ///
  /// In en, this message translates to:
  /// **'Use barcode scanner or search above'**
  String get useBarcodeScanner;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @orderCompletedPrinting.
  ///
  /// In en, this message translates to:
  /// **'Order {orderCode} completed! Printing...'**
  String orderCompletedPrinting(String orderCode);

  /// No description provided for @areYouSureRemoveAllItems.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all items from the cart?'**
  String get areYouSureRemoveAllItems;

  /// No description provided for @sessionFound.
  ///
  /// In en, this message translates to:
  /// **'Session Found'**
  String get sessionFound;

  /// No description provided for @existingSessionMessage.
  ///
  /// In en, this message translates to:
  /// **'You already have an open session. Would you like to continue with that session?'**
  String get existingSessionMessage;

  /// No description provided for @couldNotRecoverSession.
  ///
  /// In en, this message translates to:
  /// **'Could not recover session. Please try again.'**
  String get couldNotRecoverSession;

  /// No description provided for @enterValidOpeningCash.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid opening cash amount'**
  String get enterValidOpeningCash;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @receiptPreview.
  ///
  /// In en, this message translates to:
  /// **'Receipt Preview'**
  String get receiptPreview;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @searchProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode, SKU, or search products...'**
  String get searchProductsHint;

  /// No description provided for @refreshProducts.
  ///
  /// In en, this message translates to:
  /// **'Refresh products'**
  String get refreshProducts;

  /// No description provided for @currentCart.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentCart;

  /// No description provided for @enterLast4Digits.
  ///
  /// In en, this message translates to:
  /// **'Please enter last 4 digits'**
  String get enterLast4Digits;

  /// No description provided for @softwareUpdate.
  ///
  /// In en, this message translates to:
  /// **'Software Update'**
  String get softwareUpdate;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newBadge;

  /// No description provided for @appUpToDate.
  ///
  /// In en, this message translates to:
  /// **'App is up to date'**
  String get appUpToDate;

  /// No description provided for @currentVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Current:'**
  String get currentVersionLabel;

  /// No description provided for @latestVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Latest:'**
  String get latestVersionLabel;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s New:'**
  String get whatsNew;

  /// No description provided for @downloadSize.
  ///
  /// In en, this message translates to:
  /// **'Download size:'**
  String get downloadSize;

  /// No description provided for @installUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Install Update'**
  String get installUpdateTitle;

  /// No description provided for @downloadAndInstallConfirm.
  ///
  /// In en, this message translates to:
  /// **'Download and install version {version}?\n\nThe app will restart after installation.'**
  String downloadAndInstallConfirm(String version);

  /// No description provided for @clearAndResyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear & Resync Products'**
  String get clearAndResyncTitle;

  /// No description provided for @clearAndResyncContent.
  ///
  /// In en, this message translates to:
  /// **'This will:\n• Delete all locally cached products\n• Download fresh product data from server\n• Update product images and prices\n\nYour saved carts and pending orders will NOT be affected.'**
  String get clearAndResyncContent;

  /// No description provided for @clearLocalCacheDescription.
  ///
  /// In en, this message translates to:
  /// **'Clear local product cache and download fresh data from server'**
  String get clearLocalCacheDescription;

  /// No description provided for @clearAllLocalDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove all cached data including products, saved carts, and pending orders'**
  String get clearAllLocalDataDescription;

  /// No description provided for @clearAllDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllDataTitle;

  /// No description provided for @clearAllDataWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ WARNING: This will permanently delete:\n\n• All cached products\n• All saved/held carts\n• All pending offline orders\n• Session history\n\nThis action cannot be undone!'**
  String get clearAllDataWarning;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get notConfigured;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanning;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @escposPrinterNote.
  ///
  /// In en, this message translates to:
  /// **'Requires ESC/POS thermal receipt printer (Epson, Star, HOIN, etc.)\nVirtual printers (PDF, OneNote) are not supported.'**
  String get escposPrinterNote;

  /// No description provided for @noThermalPrintersFound.
  ///
  /// In en, this message translates to:
  /// **'No thermal printers found'**
  String get noThermalPrintersFound;

  /// No description provided for @connectThermalPrinter.
  ///
  /// In en, this message translates to:
  /// **'Connect a USB thermal printer and click Scan'**
  String get connectThermalPrinter;

  /// No description provided for @unknownPrinter.
  ///
  /// In en, this message translates to:
  /// **'Unknown Printer'**
  String get unknownPrinter;

  /// No description provided for @thermalPaperPreview.
  ///
  /// In en, this message translates to:
  /// **'58mm Thermal Paper Preview'**
  String get thermalPaperPreview;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @avgOrder.
  ///
  /// In en, this message translates to:
  /// **'Avg Order'**
  String get avgOrder;

  /// No description provided for @unitsSold.
  ///
  /// In en, this message translates to:
  /// **'Units Sold'**
  String get unitsSold;

  /// No description provided for @productsSold.
  ///
  /// In en, this message translates to:
  /// **'Products Sold'**
  String get productsSold;

  /// No description provided for @noActiveSessionMessage.
  ///
  /// In en, this message translates to:
  /// **'No active session'**
  String get noActiveSessionMessage;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get noOrdersFound;

  /// No description provided for @noProductsSold.
  ///
  /// In en, this message translates to:
  /// **'No products sold'**
  String get noProductsSold;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @customDate.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customDate;

  /// No description provided for @hold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get hold;

  /// No description provided for @selectOptions.
  ///
  /// In en, this message translates to:
  /// **'Select Options'**
  String get selectOptions;

  /// No description provided for @clearCartTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear cart'**
  String get clearCartTooltip;

  /// No description provided for @cardPaymentInstruction.
  ///
  /// In en, this message translates to:
  /// **'Process the card payment on your card terminal, then enter the last 4 digits here for record keeping.'**
  String get cardPaymentInstruction;

  /// No description provided for @defaultPrinterSetTo.
  ///
  /// In en, this message translates to:
  /// **'Default printer set to: {printerName}'**
  String defaultPrinterSetTo(String printerName);

  /// No description provided for @receiptPrintedFor.
  ///
  /// In en, this message translates to:
  /// **'Receipt printed for {orderCode}'**
  String receiptPrintedFor(String orderCode);

  /// No description provided for @noPrinterConfigured.
  ///
  /// In en, this message translates to:
  /// **'No printer configured. Please set up a printer in Settings.'**
  String get noPrinterConfigured;
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
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
