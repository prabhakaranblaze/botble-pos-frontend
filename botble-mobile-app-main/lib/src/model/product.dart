import '../../core/app_config.dart';
import 'image_sizes.dart';
import 'store.dart';

class Product {
  final int id;
  final String slug;
  final String name;
  final String? sku;
  final String? description;
  final String? content;
  final int? quantity;
  final bool isOutOfStock;
  final String stockStatusLabel;
  final String stockStatusHtml;
  final double price;
  final String priceFormatted;
  final double? originalPrice;
  final String originalPriceFormatted;
  final double? reviewsAvg;
  final int reviewsCount;
  final ImageSizes? imageWithSizes;
  final int? weight;
  final int? height;
  final int? wide;
  final int? length;
  final String imageUrl;
  final List<dynamic> productOptions;
  final Store? store;
  final bool? withStorehouseManagement;

  Product({
    required this.id,
    required this.slug,
    required this.name,
    this.sku,
    this.description,
    this.content,
    this.quantity,
    required this.isOutOfStock,
    required this.stockStatusLabel,
    required this.stockStatusHtml,
    required this.price,
    required this.priceFormatted,
    this.originalPrice,
    required this.originalPriceFormatted,
    this.reviewsAvg,
    required this.reviewsCount,
    this.imageWithSizes,
    this.weight,
    this.height,
    this.wide,
    this.length,
    required this.imageUrl,
    required this.productOptions,
    this.store,
    this.withStorehouseManagement,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      slug: json['slug'] as String,
      name: json['name'] as String,
      sku: json['sku'] != null ? json['sku'] as String : '',
      description: json['description'] != null ? json['description'] as String : '',
      content: json['content'] != null ? json['content'] as String : '',
      quantity: json['quantity'] as int?,
      isOutOfStock: json['is_out_of_stock'] as bool,
      stockStatusLabel: json['stock_status_label'] as String,
      stockStatusHtml: json['stock_status_html'] as String,
      price: (json['price'] as num).toDouble(),
      priceFormatted: json['price_formatted'] as String,
      originalPrice:
          json['original_price'] != null
              ? (json['original_price'] as num).toDouble()
              : null,
      originalPriceFormatted: json['original_price_formatted'] as String,
      reviewsAvg:
          json['reviews_avg'] != null
              ? (json['reviews_avg'] as num).toDouble()
              : null,
      reviewsCount: json['reviews_count'] as int,
      imageWithSizes: json['image_with_sizes'] != null
          ? ImageSizes.fromJson(json['image_with_sizes'] as Map<String, dynamic>)
          : null,
      weight: json['weight'] != null ? (json['weight'] as num).toInt() : null,
      height: json['height'] != null ? (json['height'] as num).toInt() : null,
      wide: json['wide'] != null ? (json['wide'] as num).toInt() : null,
      length: json['length'] != null ? (json['length'] as num).toInt() : null,
      imageUrl: json['image_url'] as String,
      productOptions: json['product_options'] as List<dynamic>,
      store:
          json['store'] != null && json['store']['name'] != null
              ? Store.fromJson(json['store'] as Map<String, dynamic>)
              : null,
      withStorehouseManagement: json['with_storehouse_management'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'sku': sku,
      'description': description,
      'content': content,
      'quantity': quantity,
      'is_out_of_stock': isOutOfStock,
      'stock_status_label': stockStatusLabel,
      'stock_status_html': stockStatusHtml,
      'price': price,
      'price_formatted': priceFormatted,
      'original_price': originalPrice,
      'original_price_formatted': originalPriceFormatted,
      'reviews_avg': reviewsAvg,
      'reviews_count': reviewsCount,
      'image_with_sizes': imageWithSizes?.toJson(),
      'weight': weight,
      'height': height,
      'wide': wide,
      'length': length,
      'image_url': imageUrl,
      'product_options': productOptions,
      'store': store?.toJson(),
      'with_storehouse_management': withStorehouseManagement,
    };
  }

  /// Get the thumbnail image URL based on the configured size
  String getThumbnailUrl() {
    if (imageWithSizes == null) {
      return imageUrl;
    }

    final size = AppConfig.productImageThumbnailSize;
    
    switch (size) {
      case 'medium':
        return imageWithSizes!.medium.isNotEmpty ? imageWithSizes!.medium.first : imageUrl;
      case 'large':
        return imageWithSizes!.origin.isNotEmpty ? imageWithSizes!.origin.first : imageUrl;
      case 'thumb':
        return imageWithSizes!.thumb.isNotEmpty ? imageWithSizes!.thumb.first : imageUrl;
      case 'small':
      default:
        return imageWithSizes!.small.isNotEmpty ? imageWithSizes!.small.first : imageUrl;
    }
  }
}
