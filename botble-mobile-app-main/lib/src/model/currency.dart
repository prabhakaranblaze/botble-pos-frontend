class Currency {
  final int id;
  final String title;
  final String symbol;
  final bool isDefault;
  final double exchangeRate;
  final int order;
  final String createdAt;
  final String updatedAt;

  Currency({
    required this.id,
    required this.title,
    required this.symbol,
    required this.isDefault,
    required this.exchangeRate,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id'] as int,
      title: json['title'] as String,
      symbol: json['symbol'] as String,
      isDefault: json['is_default'] as bool,
      exchangeRate: (json['exchange_rate'] as num).toDouble(),
      order: json['order'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'symbol': symbol,
      'is_default': isDefault,
      'exchange_rate': exchangeRate,
      'order': order,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
