class LogoSizes {
  final String origin;
  final String thumb;
  final String medium;
  final String small;

  LogoSizes({
    required this.origin,
    required this.thumb,
    required this.medium,
    required this.small,
  });

  factory LogoSizes.fromJson(Map<String, dynamic> json) {
    return LogoSizes(
      origin: json['origin'] as String,
      thumb: json['thumb'] as String? ?? json['origin'],
      medium: json['medium'] as String? ?? json['origin'],
      small: json['small'] as String? ?? json['origin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'thumb': thumb,
      'medium': medium,
      'small': small,
    };
  }
}

class Brand {
  final int id;
  final String name;
  final String slug;
  final String? logo;
  final LogoSizes? logoWithSizes;
  final String? description;
  final bool isFeatured;
  final String? website;

  Brand({
    required this.id,
    required this.name,
    required this.slug,
    this.logo,
    this.logoWithSizes,
    this.description,
    required this.isFeatured,
    this.website,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logo: json['logo'] as String?,
      logoWithSizes: json['logo_with_sizes'] != null
          ? LogoSizes.fromJson(
              json['logo_with_sizes'] as Map<String, dynamic>,
            )
          : null,
      description: json['description'] as String?,
      isFeatured: json['is_featured'] == 1,
      website: json['website'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'logo': logo,
      'logo_with_sizes': logoWithSizes?.toJson(),
      'description': description,
      'is_featured': isFeatured ? 1 : 0,
      'website': website,
    };
  }
}
