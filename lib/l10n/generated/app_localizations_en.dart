// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  // Auth
  @override
  String get appTitle => 'StampSmart POS';
  @override
  String get login => 'Login';
  @override
  String get logout => 'Logout';
  @override
  String get email => 'Email';
  @override
  String get password => 'Password';
  @override
  String get username => 'Username';
  @override
  String get loginButton => 'Sign In';
  @override
  String get loggingIn => 'Signing in...';
  @override
  String get loginFailed => 'Login failed';
  @override
  String get invalidCredentials => 'Invalid email or password';
  @override
  String get deviceName => 'Device Name';
  @override
  String get deviceNameHint => 'POS Terminal 1';
  @override
  String get enterPassword => 'Enter your password';
  @override
  String get unlockScreen => 'Unlock Screen';
  @override
  String get locked => 'Locked';
  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  // Navigation
  @override
  String get sales => 'Sales';
  @override
  String get products => 'Products';
  @override
  String get categories => 'Categories';
  @override
  String get customers => 'Customers';
  @override
  String get orders => 'Orders';
  @override
  String get reports => 'Reports';
  @override
  String get settings => 'Settings';

  // Cart
  @override
  String get cart => 'Cart';
  @override
  String get emptyCart => 'Cart is empty';
  @override
  String get addToCart => 'Add to Cart';
  @override
  String get removeFromCart => 'Remove';
  @override
  String get clearCart => 'Clear Cart';
  @override
  String get clearCartConfirm => 'Clear Cart?';
  @override
  String get clearCartMessage => 'This will remove all items from the cart.';
  @override
  String get saveCart => 'Save Cart';
  @override
  String get savedCarts => 'Saved Carts';
  @override
  String get loadCart => 'Load Cart';
  @override
  String get deleteCart => 'Delete Cart';
  @override
  String get cartName => 'Cart Name';
  @override
  String get enterCartName => 'Enter cart name...';
  @override
  String get cartHeldSuccess => 'Cart held successfully!';
  @override
  String get cartLoadedSuccess => 'Cart loaded!';
  @override
  String get userNotLoggedIn => 'User not logged in';
  @override
  String get clear => 'Clear';

  // Checkout/Payment
  @override
  String get checkout => 'Checkout';
  @override
  String get payment => 'Payment';
  @override
  String get cash => 'Cash';
  @override
  String get card => 'Card';
  @override
  String get cashReceived => 'Cash Received';
  @override
  String get change => 'Change';
  @override
  String get cardLastDigits => 'Last 4 digits of card';
  @override
  String get cardLastDigitsHint => '1234';
  @override
  String get completePayment => 'Complete Payment';
  @override
  String get insufficientCash => 'Insufficient cash received';
  @override
  String get enterCardDigits => 'Please enter last 4 digits';
  @override
  String get payNow => 'Pay Now';
  @override
  String get processing => 'Processing...';

  // Amounts
  @override
  String get subtotal => 'Subtotal';
  @override
  String get tax => 'Tax';
  @override
  String get discount => 'Discount';
  @override
  String get total => 'Total';
  @override
  String get quantity => 'Quantity';
  @override
  String get price => 'Price';
  @override
  String get amount => 'Amount';
  @override
  String get shipping => 'Shipping';
  @override
  String get shippingAmount => 'Shipping Amount';
  @override
  String get enterShippingAmount => 'Enter shipping amount';
  @override
  String get shippingUpdated => 'Shipping updated!';

  // Coupon
  @override
  String get coupon => 'Coupon';
  @override
  String get couponCode => 'Coupon Code';
  @override
  String get enterCouponCode => 'Enter coupon code';
  @override
  String get applyCoupon => 'Apply Coupon';
  @override
  String get removeCoupon => 'Remove Coupon';
  @override
  String get couponApplied => 'Coupon applied successfully!';
  @override
  String get apply => 'Apply';
  @override
  String get applying => 'Applying...';

  // Discount
  @override
  String get discountDescription => 'Description (Optional)';
  @override
  String get discountDescriptionHint => 'e.g., Staff discount, Loyalty reward';
  @override
  String get discountApplied => 'Discount applied successfully!';

  // Order
  @override
  String get orderComplete => 'Order Complete';
  @override
  String get orderCode => 'Order Code';
  @override
  String get orderNumber => 'Order #';
  @override
  String get orderDate => 'Date';
  @override
  String get dateTime => 'Date/Time';
  @override
  String get paymentMethod => 'Payment Method';
  @override
  String get printReceipt => 'Print Receipt';
  @override
  String get newSale => 'New Sale';
  @override
  String get orderCompleted => 'Order completed!';
  @override
  String get printing => 'Printing...';
  @override
  String get receiptPrinted => 'Receipt printed';
  @override
  String get items => 'Items';
  @override
  String get status => 'Status';
  @override
  String get mode => 'Mode';

  // Session
  @override
  String get session => 'Session';
  @override
  String get openRegister => 'Open Register';
  @override
  String get closeRegister => 'Close Register';
  @override
  String get openingCash => 'Opening Cash';
  @override
  String get openingCashAmount => 'Opening Cash Amount';
  @override
  String get closingCash => 'Closing Cash';
  @override
  String get closingCashAmount => 'Closing Cash Amount';
  @override
  String get expectedCash => 'Expected Cash';
  @override
  String get actualCash => 'Actual Cash';
  @override
  String get difference => 'Difference';
  @override
  String get cashSales => 'Cash Sales';
  @override
  String get cardSales => 'Card Sales';
  @override
  String get totalSales => 'Total Sales';
  @override
  String get sessionNotes => 'Session Notes';
  @override
  String get notesOptional => 'Notes (Optional)';
  @override
  String get addNotes => 'Add any notes...';
  @override
  String get closeSession => 'Close Session';
  @override
  String get closingSession => 'Closing Session...';
  @override
  String get sessionClosed => 'Session Closed';
  @override
  String get noActiveSession => 'No Active Session';
  @override
  String get noSession => 'No Session';
  @override
  String get viewActiveSession => 'View Active Session';
  @override
  String get openSessionFirst => 'Please open a register to start selling';
  @override
  String get closeSessionFirst => 'Close Session First';
  @override
  String get closeSessionFirstMessage => 'You have an active session. Please close your session before logging out.';
  @override
  String get viewSession => 'View Session';
  @override
  String get continueSession => 'Continue Session';
  @override
  String get startFresh => 'Start Fresh';
  @override
  String get existingSession => 'Existing Session';
  @override
  String get sessionOpen => 'OPEN';
  @override
  String get openedAt => 'Opened At';
  @override
  String get openedBy => 'Opened By';
  @override
  String get duration => 'Duration';
  @override
  String get countDenominations => 'Count Denominations (Optional)';
  @override
  String get checkingSession => 'Checking for existing session...';

  // Search & General
  @override
  String get search => 'Search';
  @override
  String get searchProducts => 'Search products...';
  @override
  String get scanBarcode => 'Scan barcode, SKU, or search products...';
  @override
  String get searchCustomers => 'Search customers...';
  @override
  String get searchCustomer => 'Search customer...';
  @override
  String get searchByOrderCode => 'Search by order code...';
  @override
  String get noResults => 'No results found';
  @override
  String get loading => 'Loading...';
  @override
  String get error => 'Error';
  @override
  String get retry => 'Retry';
  @override
  String get cancel => 'Cancel';
  @override
  String get confirm => 'Confirm';
  @override
  String get save => 'Save';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get close => 'Close';
  @override
  String get back => 'Back';
  @override
  String get next => 'Next';
  @override
  String get done => 'Done';
  @override
  String get yes => 'Yes';
  @override
  String get no => 'No';
  @override
  String get ok => 'OK';
  @override
  String get update => 'Update';
  @override
  String get refresh => 'Refresh';
  @override
  String get all => 'All';
  @override
  String get filter => 'Filter';
  @override
  String get sortBy => 'Sort by';
  @override
  String get current => 'Current';
  @override
  String get useArrowKeys => 'Use arrow keys to select product';

  // Customer
  @override
  String get customer => 'Customer';
  @override
  String get walkIn => 'Walk in';
  @override
  String get walkInCustomer => 'Walk-in Customer';
  @override
  String get selectCustomer => 'Select Customer';
  @override
  String get noCustomer => 'No customer selected';
  @override
  String get addCustomer => 'Add Customer';
  @override
  String get customerName => 'Customer Name';
  @override
  String get enterName => 'Enter name';
  @override
  String get enterEmail => 'Enter email';
  @override
  String get enterEmailOptional => 'Enter email (optional)';
  @override
  String get enterPhone => 'Enter phone';
  @override
  String get deliver => 'Deliver';
  @override
  String get deliveryAddress => 'Delivery Address';
  @override
  String get addAddress => 'Add Address';
  @override
  String get streetAddress => 'Street Address';
  @override
  String get enterStreetAddress => 'Enter street address';
  @override
  String get city => 'City';
  @override
  String get enterCity => 'Enter city';
  @override
  String get zipCode => 'Zip Code';
  @override
  String get enterZipCode => 'Enter zip code';
  @override
  String get phone => 'Phone';
  @override
  String get name => 'Name';

  // Product
  @override
  String get productNotFound => 'Product not found';
  @override
  String get outOfStock => 'Out of Stock';
  @override
  String get inStock => 'In Stock';
  @override
  String get lowStock => 'Low Stock';
  @override
  String get sku => 'SKU';
  @override
  String get variation => 'Variation';
  @override
  String get qtySold => 'Qty Sold';
  @override
  String get revenue => 'Revenue';
  @override
  String get product => 'Product';

  // Language
  @override
  String get language => 'Language';
  @override
  String get english => 'English';
  @override
  String get french => 'French';
  @override
  String get currency => 'Currency';

  // Receipt
  @override
  String get receipt => 'Receipt';
  @override
  String get posReceipt => 'POS Receipt';
  @override
  String get thankYou => 'Thank you for your purchase!';
  @override
  String get pleaseReturn => 'Please come again';

  // Denominations
  @override
  String get enterDenominations => 'Enter Denominations';
  @override
  String get quickCash => 'Quick Cash';

  // Dashboard
  @override
  String get recentBills => 'Recent Bills';
  @override
  String get calculator => 'Calculator';
  @override
  String get fullScreen => 'Full Screen';
  @override
  String get exitFullScreen => 'Exit Full Screen';

  // Connectivity
  @override
  String get workingOffline => 'Working Offline - Changes will sync when online';
  @override
  String get online => 'Online';
  @override
  String get offline => 'Offline';

  // Export
  @override
  String get exportCsv => 'Export CSV';
  @override
  String get exportSuccess => 'Exported successfully';
  @override
  String get exportFailed => 'Export failed';
  @override
  String get noOrdersToExport => 'No orders to export';
  @override
  String get noProductsToExport => 'No products to export';

  // Resync
  @override
  String get resync => 'Resync';
  @override
  String get resyncProducts => 'Resync Products';
  @override
  String get clearAndResyncProducts => 'Clear & Resync Products';
  @override
  String get resyncNow => 'Resync Now';
  @override
  String get resyncing => 'Resyncing products...';
  @override
  String get resyncSuccess => 'Products resynced successfully!';
  @override
  String get resyncFailed => 'Resync failed';

  // Clear Data
  @override
  String get clearAllData => 'Clear All Data';
  @override
  String get clearAll => 'Clear All';
  @override
  String get clearingData => 'Clearing all data...';
  @override
  String get dataCleared => 'All local data cleared and resynced!';
  @override
  String get clearFailed => 'Clear failed';

  // Printer
  @override
  String get printerSettings => 'Printer Settings';
  @override
  String get selectPrinter => 'Select Printer';
  @override
  String get defaultPrinter => 'Default Printer';
  @override
  String get defaultPrinterSet => 'Default printer set';
  @override
  String get defaultPrinterCleared => 'Default printer cleared';
  @override
  String get selectPrinterFirst => 'Please select a printer first';
  @override
  String get testPrint => 'Test Print';
  @override
  String get testPrintSuccess => 'Test print sent successfully!';
  @override
  String get printFailed => 'Print failed';
  @override
  String get autoPrintOnPayment => 'Auto Print on Payment';
  @override
  String get autoPrintDescription => 'Automatically print receipt when order is paid';
  @override
  String get usb => 'USB';
  @override
  String get bluetooth => 'BT';
  @override
  String get wifi => 'WiFi';
  @override
  String get demoPayment => 'Demo Payment';

  // Updates
  @override
  String get checkForUpdates => 'Check for Updates';
  @override
  String get installUpdate => 'Install Update';
  @override
  String get updateNow => 'Update Now';
  @override
  String get updateAvailable => 'Update Available';
  @override
  String get noUpdatesAvailable => 'No updates available';
  @override
  String get check => 'Check';

  // Additional Auth
  @override
  String get signInToContinue => 'Sign in to continue';
  @override
  String get pleaseEnterUsername => 'Please enter your username';
  @override
  String get usernameTooShort => 'Username must be at least 3 characters';
  @override
  String get pleaseEnterPassword => 'Please enter your password';
  @override
  String get passwordTooShort => 'Password must be at least 6 characters';
  @override
  String get pleaseEnterDeviceName => 'Please enter device name';

  // Lock Screen
  @override
  String get sessionLocked => 'Session Locked';
  @override
  String get lockedDueToInactivity => 'Locked due to inactivity';
  @override
  String get enterPasswordToUnlock => 'Enter password to unlock';
  @override
  String get unlock => 'Unlock';
  @override
  String get logoutQuestion => 'Logout?';
  @override
  String get logoutConfirmWithSession => 'Are you sure you want to logout? Your session will remain open and you can continue later.';
  @override
  String get logoutInstead => 'Logout Instead';
  @override
  String get invalidPassword => 'Invalid password. Please try again.';

  // Additional UI
  @override
  String get changeLanguage => 'Change Language';
  @override
  String get notes => 'Notes:';
  @override
  String get exact => 'Exact';
  @override
  String get payWithCash => 'Pay with Cash';
  @override
  String get totalAmount => 'Total Amount';
  @override
  String get createNewCustomer => 'Create New Customer';
  @override
  String get add => 'Add';
  @override
  String get emailOptional => 'Email (Optional)';
  @override
  String get addNewAddress => 'Add New Address';
  @override
  String get pleaseEnterCouponCode => 'Please enter a coupon code';
  @override
  String get invalidCouponCode => 'Invalid coupon code';
  @override
  String get applyDiscount => 'Apply Discount';
  @override
  String get discountType => 'Discount Type';
  @override
  String get percentage => 'Percentage';
  @override
  String get fixed => 'Fixed';
  @override
  String get discountAmount => 'Discount Amount';
  @override
  String get updateShipping => 'Update Shipping';
  @override
  String get selectVariant => 'Select Variant';
  @override
  String get options => 'Options';
  @override
  String get item => 'item';
  @override
  String get itemPlural => 'items';
  @override
  String get unit => 'unit';
  @override
  String get unitPlural => 'units';
  @override
  String get scanProductsToAdd => 'Scan products to add to cart';
  @override
  String get useBarcodeScanner => 'Use barcode scanner or search above';
  @override
  String get noProductsFound => 'No products found';
  @override
  String orderCompletedPrinting(String orderCode) => 'Order $orderCode completed! Printing...';
  @override
  String get areYouSureRemoveAllItems => 'Are you sure you want to remove all items from the cart?';
  @override
  String get sessionFound => 'Session Found';
  @override
  String get existingSessionMessage => 'You already have an open session. Would you like to continue with that session?';
  @override
  String get couldNotRecoverSession => 'Could not recover session. Please try again.';
  @override
  String get enterValidOpeningCash => 'Please enter a valid opening cash amount';
  @override
  String get dataManagement => 'Data Management';
  @override
  String get about => 'About';
  @override
  String get receiptPreview => 'Receipt Preview';
  @override
  String get version => 'Version';

  // Dashboard Session
  @override
  String get closeSessionFirst => 'Close Session First';
  @override
  String get closeSessionFirstMessage => 'You have an active session. Please close your session before logging out.';
  @override
  String get viewSession => 'View Session';
  @override
  String get viewActiveSession => 'View Active Session';
  @override
  String get noSession => 'No Session';
  @override
  String get sessionOpen => 'OPEN';
  @override
  String get openedAt => 'Opened At';
  @override
  String get openedBy => 'Opened By';
  @override
  String get searchByOrderCode => 'Search by order code...';
  @override
  String get userNotLoggedIn => 'User not logged in';
  @override
  String get cartHeldSuccess => 'Cart held successfully!';
  @override
  String get cartLoadedSuccess => 'Cart loaded!';
  @override
  String get searchProductsHint => 'Scan barcode, SKU, or search products...';
  @override
  String get refreshProducts => 'Refresh products';
  @override
  String get currentCart => 'Current';
  @override
  String get completePayment => 'Complete Payment';
  @override
  String get insufficientCash => 'Insufficient cash received';
  @override
  String get enterLast4Digits => 'Please enter last 4 digits';
}
