class Store {
  final int id;
  final String slug;
  final String name;

  Store({
    required this.id,
    required this.slug,
    required this.name,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as int,
      slug: json['slug'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
    };
  }
} 