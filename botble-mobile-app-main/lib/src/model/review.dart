class Review {
  final String userName;
  final String userAvatar;
  final String createdAt;
  final String createdAtTz;
  final String comment;
  final int star;
  final List<ReviewImage> images;
  final String? orderedAt;
  final String? orderedAtTz;

  Review({
    required this.userName,
    required this.userAvatar,
    required this.createdAt,
    required this.createdAtTz,
    required this.comment,
    required this.star,
    required this.images,
    this.orderedAt,
    this.orderedAtTz,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      userName: json['user_name'] as String,
      userAvatar: json['user_avatar'] as String,
      createdAt: json['created_at'] as String,
      createdAtTz: json['created_at_tz'] as String,
      comment: json['comment'] as String,
      star: json['star'] as int,
      images: (json['images'] as List<dynamic>?)
          ?.map((image) => ReviewImage.fromJson(image))
          .toList() ?? [],
      orderedAt: json['ordered_at'] as String?,
      orderedAtTz: json['ordered_at_tz'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_name': userName,
      'user_avatar': userAvatar,
      'created_at': createdAt,
      'created_at_tz': createdAtTz,
      'comment': comment,
      'star': star,
      'images': images.map((image) => image.toJson()).toList(),
      'ordered_at': orderedAt,
      'ordered_at_tz': orderedAtTz,
    };
  }
}

class ReviewImage {
  final String thumbnail;
  final String fullUrl;

  ReviewImage({
    required this.thumbnail,
    required this.fullUrl,
  });

  factory ReviewImage.fromJson(Map<String, dynamic> json) {
    return ReviewImage(
      thumbnail: json['thumbnail'] as String,
      fullUrl: json['full_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'thumbnail': thumbnail,
      'full_url': fullUrl,
    };
  }
} 