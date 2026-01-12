// lib/core/models/cart.dart

import 'package:flutter/foundation.dart';
import 'product.dart';
import 'customer.dart';
import '../config/env_config.dart';

class CartItem {
  final int productId;
  final String name;
  final double price;
  final int quantity;
  final String? image;
  final String? sku;
  final String? options;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.image,
    this.sku,
    this.options,
  });

  double get total => price * quantity;
  double get lineTotal => total; // Alias for total

  /// Get full image URL with base URL prefix
  String? get fullImageUrl {
    if (image == null || image!.isEmpty) return null;
    return EnvConfig.getImageUrl(image);
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    debugPrint('🛒 CART ITEM: Parsing from JSON');
    debugPrint('🛒 CART ITEM: JSON data: $json');

    try {
      // Handle both Node.js format and Laravel format
      // Node.js: id, name, quantity
      // Laravel: product_id, product_name, qty

      // Parse price - handle both num and string
      double parsePrice(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }

      final item = CartItem(
        productId: json['id'] as int? ?? json['product_id'] as int,
        name: json['name'] as String? ?? json['product_name'] as String,
        price: parsePrice(json['price']),
        quantity: json['quantity'] as int? ?? json['qty'] as int? ?? 1,
        image: json['image'] as String? ?? json['product_image'] as String?,
        sku: json['sku'] as String?,
      );

      debugPrint(
          '✅ CART ITEM: Parsed - ${item.name} (qty: ${item.quantity}, price: ${item.price})');
      return item;
    } catch (e) {
      debugPrint('❌ CART ITEM: Parse error - $e');
      debugPrint('❌ CART ITEM: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': productId,
      'name': name,
      'price': price,
      'quantity': quantity, // ✅ Changed from 'qty' to 'quantity'
      'image': image,
      'sku': sku,
      'options': options,
    };
  }
}

class Cart {
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double shipping;
  final double tax;
  final double total;
  final Customer? customer;
  final String? paymentMethod;
  final String? couponCode;

  Cart({
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.tax,
    required this.total,
    this.customer,
    this.paymentMethod,
    this.couponCode,
  });

  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  int get totalQuantity => itemCount; // Alias for itemCount

  factory Cart.empty() {
    debugPrint('🛒 CART: Creating empty cart');

    return Cart(
      items: [],
      subtotal: 0,
      discount: 0,
      shipping: 0,
      tax: 0,
      total: 0,
    );
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    debugPrint('🛒 CART: Parsing cart from JSON');
    debugPrint('🛒 CART: JSON keys: ${json.keys.toList()}');

    try {
      // ✅ Backend sends cart data directly (not nested in 'cart' key)
      final cartData = json.containsKey('cart')
          ? json['cart'] as Map<String, dynamic>
          : json;

      debugPrint('🛒 CART: Cart data keys: ${cartData.keys.toList()}');

      // Parse items
      final itemsList = cartData['items'] as List<dynamic>? ?? [];
      debugPrint('🛒 CART: Items count in JSON: ${itemsList.length}');

      if (itemsList.isNotEmpty) {
        debugPrint('🛒 CART: First item data: ${itemsList.first}');
      }

      final items = itemsList.map((item) {
        debugPrint('🛒 CART: Parsing item...');
        return CartItem.fromJson(item as Map<String, dynamic>);
      }).toList();

      debugPrint('🛒 CART: Items parsed: ${items.length}');

      // ✅ Parse amounts - handle both int and double
      final subtotal = (cartData['subtotal'] as num?)?.toDouble() ?? 0.0;

      // ✅ Backend might send discount in different fields
      final discount = (cartData['discount'] as num?)?.toDouble() ??
          (cartData['coupon_discount'] as num?)?.toDouble() ??
          (cartData['manual_discount'] as num?)?.toDouble() ??
          0.0;

      final shipping = (cartData['shipping_amount'] as num?)?.toDouble() ?? 0.0;
      final tax = (cartData['tax'] as num?)?.toDouble() ?? 0.0;
      final total = (cartData['total'] as num?)?.toDouble() ?? 0.0;

      debugPrint('🛒 CART: Subtotal: $subtotal');
      debugPrint('🛒 CART: Discount: $discount');
      debugPrint('🛒 CART: Shipping: $shipping');
      debugPrint('🛒 CART: Tax: $tax');
      debugPrint('🛒 CART: Total: $total');

      final cart = Cart(
        items: items,
        subtotal: subtotal,
        discount: discount,
        shipping: shipping,
        tax: tax,
        total: total,
        paymentMethod: cartData['payment_method'] as String?,
        couponCode: cartData['coupon_code'] as String?,
      );

      debugPrint('✅ CART: Cart parsed successfully');
      debugPrint('✅ CART: Final items count: ${cart.items.length}');
      debugPrint('✅ CART: Final total: ${cart.total}');

      return cart;
    } catch (e) {
      debugPrint('❌ CART: Parse error - $e');
      debugPrint('❌ CART: Error type: ${e.runtimeType}');
      debugPrint('❌ CART: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
}

class Order {
  final int id;
  final String code;
  final double amount;
  final double subTotal;
  final double taxAmount;
  final double discountAmount;
  final double shippingAmount;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final Customer? customer;
  final List<CartItem> items;
  final String? paymentDetails;
  final Map<String, dynamic>? paymentMetadata;

  Order({
    required this.id,
    required this.code,
    required this.amount,
    this.subTotal = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.shippingAmount = 0,
    this.paymentMethod = 'pos_cash',
    required this.status,
    required this.createdAt,
    this.customer,
    required this.items,
    this.paymentDetails,
    this.paymentMetadata,
  });

  // Helper getters for payment metadata
  double? get cashReceived => paymentMetadata?['cash_received']?.toDouble();
  double? get changeGiven => paymentMetadata?['change_given']?.toDouble();
  String? get cardLastFour => paymentMetadata?['card_last_four']?.toString();

  /// Helper to parse fields that can be either String or {value: String, label: String}
  static String _parseStringOrObject(dynamic field, [String defaultValue = '']) {
    if (field == null) return defaultValue;
    if (field is String) return field;
    if (field is Map) return field['value']?.toString() ?? defaultValue;
    return defaultValue;
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    debugPrint('📦 ORDER: Parsing order from JSON');
    debugPrint('📦 ORDER: Order ID: ${json['id']}');
    debugPrint('📦 ORDER: Order code: ${json['code']}');

    try {
      // Handle items from 'items' or 'products' field
      final itemsList = json['items'] as List<dynamic>? ??
                        json['products'] as List<dynamic>? ?? [];

      // Parse payment method from payment object or direct field
      String paymentMethod = 'pos_cash';
      if (json['payment'] != null && json['payment'] is Map) {
        paymentMethod = _parseStringOrObject(json['payment']['payment_channel'], 'pos_cash');
      } else {
        paymentMethod = _parseStringOrObject(json['payment_method'], 'pos_cash');
      }

      // Helper to parse numeric values (handles both num and string)
      double parseNum(dynamic value, [double defaultValue = 0]) {
        if (value == null) return defaultValue;
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? defaultValue;
        return defaultValue;
      }

      final order = Order(
        id: json['id'] as int,
        code: json['code'] as String,
        amount: parseNum(json['amount']),
        subTotal: parseNum(json['sub_total']),
        taxAmount: parseNum(json['tax_amount']),
        discountAmount: parseNum(json['discount_amount']),
        shippingAmount: parseNum(json['shipping_amount']),
        paymentMethod: paymentMethod,
        status: _parseStringOrObject(json['status'], 'pending'),
        createdAt: DateTime.parse(json['created_at'] as String),
        items: itemsList
            .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        paymentDetails: json['payment_details'] as String?,
        paymentMetadata: json['payment_metadata'] as Map<String, dynamic>?,
      );

      debugPrint('✅ ORDER: Order parsed - ${order.items.length} items');
      return order;
    } catch (e) {
      debugPrint('❌ ORDER: Parse error - $e');
      rethrow;
    }
  }

  Map<String, dynamic> toDbJson() {
    return {
      'id': id,
      'code': code,
      'amount': amount,
      'sub_total': subTotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'shipping_amount': shippingAmount,
      'payment_method': paymentMethod,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'customer_id': customer?.id,
      'payment_details': paymentDetails,
      'synced': 0,
    };
  }
}
