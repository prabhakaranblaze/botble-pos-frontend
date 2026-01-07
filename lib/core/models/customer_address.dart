class CustomerAddress {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final bool isDefault;
  final String? fullAddress;

  CustomerAddress({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.isDefault = false,
    this.fullAddress,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      zipCode: json['zip_code'] as String?,
      isDefault: json['is_default'] == true,
      fullAddress: json['full_address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zip_code': zipCode,
      'is_default': isDefault,
    };
  }

  /// Display string for dropdown
  String get displayText {
    if (fullAddress != null && fullAddress!.isNotEmpty) {
      return fullAddress!;
    }
    return [address, city, zipCode].where((e) => e != null && e.isNotEmpty).join(', ');
  }
}
