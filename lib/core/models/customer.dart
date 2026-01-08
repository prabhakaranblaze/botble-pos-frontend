import 'customer_address.dart';

class Customer {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final List<CustomerAddress> addresses;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.addresses = const [],
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      addresses: json['addresses'] != null
          ? (json['addresses'] as List)
              .map((a) => CustomerAddress.fromJson(a))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'addresses': addresses.map((a) => a.toJson()).toList(),
    };
  }

  /// Get default address if exists
  CustomerAddress? get defaultAddress {
    if (addresses.isEmpty) return null;
    try {
      return addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return addresses.first;
    }
  }
}
