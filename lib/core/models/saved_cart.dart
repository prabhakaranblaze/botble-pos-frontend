import 'dart:convert';

/// Saved Cart Model - User ID only mapping
class SavedCart {
  final String id;
  final int userId;
  final String userName;
  final String name;
  final DateTime savedAt;
  final String? customerId;
  final String? customerName;
  final List<SavedCartItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final bool isOnline;
  final int? onlineId;

  SavedCart({
    required this.id,
    required this.userId,
    required this.userName,
    required this.name,
    required this.savedAt,
    this.customerId,
    this.customerName,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.isOnline = false,
    this.onlineId,
  });

  factory SavedCart.fromJson(Map<String, dynamic> json) {
    return SavedCart(
      id: json['id'].toString(),
      userId: json['user_id'] as int,
      userName: json['user_name'] as String,
      name: json['name'] as String,
      savedAt: DateTime.parse(json['saved_at'] as String),
      customerId: json['customer_id']?.toString(),
      customerName: json['customer_name'] as String?,
      items: (json['items'] as List)
          .map((item) => SavedCartItem.fromJson(item))
          .toList(),
      subtotal: double.parse(json['subtotal'].toString()),
      tax: double.parse(json['tax'].toString()),
      total: double.parse(json['total'].toString()),
      isOnline: json['is_online'] as bool? ?? false,
      onlineId: json['online_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'name': name,
      'saved_at': savedAt.toIso8601String(),
      'customer_id': customerId,
      'customer_name': customerName,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'is_online': isOnline,
      'online_id': onlineId,
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'name': name,
      'saved_at': savedAt.toIso8601String(),
      'customer_id': customerId,
      'customer_name': customerName,
      'items': jsonEncode(items.map((item) => item.toJson()).toList()),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'is_online': isOnline ? 1 : 0,
      'online_id': onlineId,
    };
  }

  factory SavedCart.fromDbMap(Map<String, dynamic> map) {
    return SavedCart(
      id: map['id'] as String,
      userId: map['user_id'] as int,
      userName: map['user_name'] as String,
      name: map['name'] as String,
      savedAt: DateTime.parse(map['saved_at'] as String),
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      items: (jsonDecode(map['items'] as String) as List)
          .map((item) => SavedCartItem.fromJson(item))
          .toList(),
      subtotal: map['subtotal'] as double,
      tax: map['tax'] as double,
      total: map['total'] as double,
      isOnline: (map['is_online'] as int) == 1,
      onlineId: map['online_id'] as int?,
    );
  }

  SavedCart copyWith({
    String? id,
    int? userId,
    String? userName,
    String? name,
    DateTime? savedAt,
    String? customerId,
    String? customerName,
    List<SavedCartItem>? items,
    double? subtotal,
    double? tax,
    double? total,
    bool? isOnline,
    int? onlineId,
  }) {
    return SavedCart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      name: name ?? this.name,
      savedAt: savedAt ?? this.savedAt,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      isOnline: isOnline ?? this.isOnline,
      onlineId: onlineId ?? this.onlineId,
    );
  }
}

class SavedCartItem {
  final int productId;
  final String name;
  final double price;
  final int quantity;
  final String? image;
  final String? sku;
  final String? options; // "Size: Large • Color: Red"
  final double taxRate;

  SavedCartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.image,
    this.sku,
    this.options,
    this.taxRate = 0.0,
  });

  double get total => price * quantity;

  factory SavedCartItem.fromJson(Map<String, dynamic> json) {
    return SavedCartItem(
      productId: json['product_id'] as int,
      name: json['name'] as String,
      price: double.parse(json['price'].toString()),
      quantity: json['quantity'] as int,
      image: json['image'] as String?,
      sku: json['sku'] as String?,
      options: json['options'] as String?,
      taxRate: json['tax_rate'] != null
          ? double.parse(json['tax_rate'].toString())
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image': image,
      'sku': sku,
      'options': options,
      'tax_rate': taxRate,
    };
  }

  SavedCartItem copyWith({
    int? productId,
    String? name,
    double? price,
    int? quantity,
    String? image,
    String? sku,
    String? options,
    double? taxRate,
  }) {
    return SavedCartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      image: image ?? this.image,
      sku: sku ?? this.sku,
      options: options ?? this.options,
      taxRate: taxRate ?? this.taxRate,
    );
  }
}
