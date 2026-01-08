class Address {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String country;
  final String state;
  final String city;
  final String address;
  final bool isDefault;
  final String? zipCode;
  final String? fullAddress;

  Address({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.country,
    required this.state,
    required this.city,
    required this.address,
    required this.isDefault,
    this.zipCode,
    this.fullAddress,
  });

  // Computed property to get full address
  String get computedFullAddress {
    if (fullAddress != null && fullAddress!.isNotEmpty) {
      return fullAddress!;
    }

    // Build full address from components
    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (zipCode != null && zipCode!.isNotEmpty) parts.add(zipCode!);
    if (country.isNotEmpty) parts.add(country);

    return parts.join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      country: json['country'],
      state: json['state'],
      city: json['city'],
      address: json['address'],
      isDefault: json['is_default'] == 1,
      zipCode: json['zip_code'],
      fullAddress: json['full_address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'country': country,
      'state': state,
      'city': city,
      'address': address,
      'is_default': isDefault,
      'zip_code': zipCode,
      'full_address': fullAddress,
    };
  }
}
