class User {
  final int id;
  final String name;
  final String email;
  final int? storeId;
  final String? storeName;
  final bool isSuperUser;
  final List<String> permissions;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.storeId,
    this.storeName,
    this.isSuperUser = false,
    this.permissions = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      storeId: json['store_id'] as int?,
      storeName: json['store_name'] as String?,
      isSuperUser: json['is_super_user'] as bool? ?? false,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'store_id': storeId,
      'store_name': storeName,
      'is_super_user': isSuperUser,
      'permissions': permissions,
    };
  }

  /// Check if user has a specific permission
  bool hasPermission(String permission) {
    // Super user has all permissions
    if (isSuperUser || permissions.contains('*')) {
      return true;
    }
    return permissions.contains(permission);
  }

  /// Check if user has any of the given permissions
  bool hasAnyPermission(List<String> perms) {
    if (isSuperUser || permissions.contains('*')) {
      return true;
    }
    return perms.any((p) => permissions.contains(p));
  }

  /// Check if user has all of the given permissions
  bool hasAllPermissions(List<String> perms) {
    if (isSuperUser || permissions.contains('*')) {
      return true;
    }
    return perms.every((p) => permissions.contains(p));
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

/// POS Permission constants
class PosPermissions {
  // Core POS access
  static const String posIndex = 'pos.index';
  static const String posPro = 'pos-pro';

  // Settings
  static const String posSettings = 'pos.settings';

  // Reports
  static const String posReports = 'pos.reports';

  // Transactions
  static const String posRefund = 'pos.refund';
  static const String posDiscount = 'pos.discount';
  static const String posVoid = 'pos.void';

  // Cash management
  static const String posCashDrop = 'pos.cash_drop';
  static const String posCashPickup = 'pos.cash_pickup';

  // Session management
  static const String posCloseSession = 'pos.close_session';
  static const String posOpenSession = 'pos.open_session';
}
