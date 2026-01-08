class Country {
  final String id;
  final String name;
  final String? code;

  Country({required this.id, required this.name, this.code});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'].toString(),
      name: json['name'] as String,
      code: json['code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code ?? '',
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
