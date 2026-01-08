class LocationState {
  final String id;
  final String name;
  final String countryId;

  LocationState({
    required this.id,
    required this.name,
    required this.countryId,
  });

  factory LocationState.fromJson(Map<String, dynamic> json) {
    return LocationState(
      id: json['id'].toString(),
      name: json['name'] as String,
      countryId: json['country_id'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country_id': countryId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationState && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
