class ImageSizes {
  final String origin;
  final String thumb;
  final String medium;
  final String small;

  ImageSizes({
    required this.origin,
    required this.thumb,
    required this.medium,
    required this.small,
  });

  factory ImageSizes.fromJson(Map<String, dynamic> json) {
    return ImageSizes(
      origin: json['origin'] as String,
      thumb: json['thumb'] as String? ?? json['origin'],
      medium: json['medium'] as String? ?? json['origin'],
      small: json['small'] as String? ?? json['origin'],
    );
  }
}

class Category {
  final int id;
  final String name;
  final String? icon;
  final String? iconImage;
  final bool isFeatured;
  final dynamic parentId; // Can be String, int, or null
  final String slug;
  final ImageSizes? imageWithSizes;
  final List<Category> children;

  Category({
    required this.id,
    required this.name,
    this.icon,
    this.iconImage,
    required this.isFeatured,
    this.parentId,
    required this.slug,
    this.imageWithSizes,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      iconImage: json['icon_image'] as String?,
      isFeatured: json['is_featured'] == 1,
      parentId: json['parent_id'], // Keep as-is: can be String, int, or null
      slug: json['slug'] as String,
      imageWithSizes:
          json['image_with_sizes'] != null
              ? ImageSizes.fromJson(
                json['image_with_sizes'] as Map<String, dynamic>,
              )
              : null,
      children:
          (json['children'] as List<dynamic>?)
              ?.map((child) => Category.fromJson(child as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
