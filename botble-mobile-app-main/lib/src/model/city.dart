class City {
  final String id;
  final String name;
  final String stateId;
  final String countryId;

  City({
    required this.id,
    required this.name,
    required this.stateId,
    required this.countryId,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'].toString(),
      name: json['name'] as String,
      stateId: json['state_id'].toString(),
      countryId: json['country_id'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state_id': stateId,
      'country_id': countryId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
