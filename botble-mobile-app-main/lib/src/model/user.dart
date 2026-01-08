class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? dob;
  final String? avatar;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.dob,
    this.avatar,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      dob: json['dob'],
      avatar: json['avatar'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'dob': dob,
      'avatar': avatar,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, phone: $phone}';
  }
}
