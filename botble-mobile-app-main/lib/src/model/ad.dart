class Ad {
  final String key;
  final String name;
  final String image;
  final String? tabletImage;
  final String? mobileImage;
  final String? link;

  Ad({
    required this.key,
    required this.name,
    required this.image,
    this.tabletImage,
    this.mobileImage,
    this.link,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      key: json['key'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      tabletImage: json['tablet_image'] as String?,
      mobileImage: json['mobile_image'] as String?,
      link: json['link'] as String?,
    );
  }
}
