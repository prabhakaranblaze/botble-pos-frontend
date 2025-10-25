import 'product.dart';
import 'customer.dart';

class CartItem {
  final int productId;
  final String name;
  final double price;
  final int quantity;
  final String? image;
  final String? options;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.image,
    this.options,
  });

  double get total => price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['id'] as int,
      name: json['name'] as String,
      price: double.parse(json['price'].toString()),
      quantity: json['qty'] as int,
      image: json['image'] as String?,
      options: json['options'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': productId,
      'name': name,
      'price': price,
      'qty': quantity,
      'image': image,
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

  factory Cart.empty() {
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
    final cartData = json['cart'] as Map<String, dynamic>;
    final itemsList = cartData['items'] as List<dynamic>? ?? [];
    
    return Cart(
      items: itemsList.map((item) => CartItem.fromJson(item)).toList(),
      subtotal: double.parse(cartData['sub_total']?.toString() ?? '0'),
      discount: double.parse(cartData['discount']?.toString() ?? '0'),
      shipping: double.parse(cartData['shipping_amount']?.toString() ?? '0'),
      tax: double.parse(cartData['tax']?.toString() ?? '0'),
      total: double.parse(cartData['total']?.toString() ?? '0'),
      paymentMethod: cartData['payment_method'] as String?,
      couponCode: cartData['coupon_code'] as String?,
    );
  }
}

class Order {
  final int id;
  final String code;
  final double amount;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final Customer? customer;
  final List<CartItem> items;
  final String? paymentDetails;

  Order({
    required this.id,
    required this.code,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.customer,
    required this.items,
    this.paymentDetails,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    
    return Order(
      id: json['id'] as int,
      code: json['code'] as String,
      amount: double.parse(json['amount'].toString()),
      paymentMethod: json['payment_method'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: itemsList.map((item) => CartItem.fromJson(item)).toList(),
      paymentDetails: json['payment_details'] as String?,
    );
  }

  Map<String, dynamic> toDbJson() {
    return {
      'id': id,
      'code': code,
      'amount': amount,
      'payment_method': paymentMethod,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'customer_id': customer?.id,
      'payment_details': paymentDetails,
      'synced': 0,
    };
  }
}
