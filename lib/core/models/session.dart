class CashRegister {
  final int id;
  final String name;
  final String code;
  final int storeId;
  final String? description;
  final bool isActive;
  final double? initialFloat;

  CashRegister({
    required this.id,
    required this.name,
    required this.code,
    required this.storeId,
    this.description,
    this.isActive = true,
    this.initialFloat,
  });

  factory CashRegister.fromJson(Map<String, dynamic> json) {
    return CashRegister(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      storeId: json['store_id'] as int,
      description: json['description'] as String?,
      isActive: json['is_active'] ?? true,
      initialFloat: json['initial_float'] != null
          ? double.parse(json['initial_float'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'store_id': storeId,
      'description': description,
      'is_active': isActive,
      'initial_float': initialFloat,
    };
  }
}

class PosSession {
  final int id;
  final int cashRegisterId;
  final String? cashRegisterName;
  final int userId;
  final String? userName;
  final String status;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingCash;
  final double? closingCash;
  final Map<String, int>? openingDenominations;
  final Map<String, int>? closingDenominations;
  final String? openingNotes;
  final String? closingNotes;
  final double? difference;

  PosSession({
    required this.id,
    required this.cashRegisterId,
    this.cashRegisterName,
    required this.userId,
    this.userName,
    required this.status,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    this.closingCash,
    this.openingDenominations,
    this.closingDenominations,
    this.openingNotes,
    this.closingNotes,
    this.difference,
  });

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';

  factory PosSession.fromJson(Map<String, dynamic> json) {
    return PosSession(
      id: json['id'] as int,
      cashRegisterId: json['cash_register_id'] as int,
      cashRegisterName: json['cash_register_name'] as String?,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String?,
      status: json['status'] as String,
      openedAt: DateTime.parse(json['opened_at'] as String),
      closedAt: json['closed_at'] != null 
          ? DateTime.parse(json['closed_at'] as String)
          : null,
      openingCash: double.parse(json['opening_cash'].toString()),
      closingCash: json['closing_cash'] != null 
          ? double.parse(json['closing_cash'].toString())
          : null,
      openingDenominations: json['opening_denominations'] != null
          ? Map<String, int>.from(json['opening_denominations'])
          : null,
      closingDenominations: json['closing_denominations'] != null
          ? Map<String, int>.from(json['closing_denominations'])
          : null,
      openingNotes: json['opening_notes'] as String?,
      closingNotes: json['closing_notes'] as String?,
      difference: json['difference'] != null 
          ? double.parse(json['difference'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cash_register_id': cashRegisterId,
      'cash_register_name': cashRegisterName,
      'user_id': userId,
      'user_name': userName,
      'status': status,
      'opened_at': openedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'opening_cash': openingCash,
      'closing_cash': closingCash,
      'opening_denominations': openingDenominations,
      'closing_denominations': closingDenominations,
      'opening_notes': openingNotes,
      'closing_notes': closingNotes,
      'difference': difference,
    };
  }

  Map<String, dynamic> toDbJson() {
    return {
      'id': id,
      'cash_register_id': cashRegisterId,
      'user_id': userId,
      'status': status,
      'opened_at': openedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'opening_cash': openingCash,
      'closing_cash': closingCash,
      'opening_notes': openingNotes,
      'closing_notes': closingNotes,
      'difference': difference,
      'synced': status == 'closed' ? 0 : 1,
    };
  }
}

class Denomination {
  final int id;
  final String currency;
  final double value;
  final String type;
  final String displayName;

  Denomination({
    required this.id,
    required this.currency,
    required this.value,
    required this.type,
    required this.displayName,
  });

  factory Denomination.fromJson(Map<String, dynamic> json) {
    return Denomination(
      id: json['id'] as int,
      currency: json['currency'] as String,
      value: double.parse(json['value'].toString()),
      type: json['type'] as String,
      displayName: json['display_name'] as String,
    );
  }
}
