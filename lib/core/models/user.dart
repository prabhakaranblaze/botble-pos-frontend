class User {
  final int id;
  final String name;
  final String email;
  final int? storeId;
  final String? storeName;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.storeId,
    this.storeName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      storeId: json['store_id'] as int?,
      storeName: json['store_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'store_id': storeId,
      'store_name': storeName,
    };
  }
}

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
