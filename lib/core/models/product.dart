import 'dart:convert';

class Product {
  final int id;
  final String name;
  final String? sku;
  final String? barcode;
  final double price;
  final double? salePrice;
  final String? image;
  final int? quantity;
  final String? description;
  final bool isAvailable;
  final bool hasVariants;
  final List<ProductVariant>? variants;

  Product({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    required this.price,
    this.salePrice,
    this.image,
    this.quantity,
    this.description,
    this.isAvailable = true,
    this.hasVariants = false,
    this.variants,
  });

  double get finalPrice => salePrice ?? price;

  // ⭐ FROM API JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      price: double.parse(json['price'].toString()),
      salePrice: json['sale_price'] != null
          ? double.parse(json['sale_price'].toString())
          : null,
      image: json['image'] as String?,
      quantity: json['quantity'] as int?,
      description: json['description'] as String?,
      isAvailable: json['is_available'] ?? true,
      hasVariants: json['has_variants'] ?? false,
      variants: json['variants'] != null
          ? (json['variants'] as List)
              .map((v) => ProductVariant.fromJson(v))
              .toList()
          : null,
    );
  }

  // ⭐ TO API JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'price': price,
      'sale_price': salePrice,
      'image': image,
      'quantity': quantity,
      'description': description,
      'is_available': isAvailable,
      'has_variants': hasVariants,
      'variants': variants?.map((v) => v.toJson()).toList(),
    };
  }

  // ⭐ TO DATABASE JSON (for sqflite)
  Map<String, dynamic> toDbJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'price': price,
      'sale_price': salePrice,
      'image': image,
      'quantity': quantity,
      'description': description,
      'is_available': isAvailable ? 1 : 0,
      'has_variants': hasVariants ? 1 : 0,
      'variants_json': variants != null
          ? jsonEncode(variants!.map((v) => v.toJson()).toList())
          : null,
      'synced': 1,
    };
  }

  // ⭐ FROM DATABASE JSON
  factory Product.fromDbJson(Map<String, dynamic> json) {
    List<ProductVariant>? variantsList;

    if (json['variants_json'] != null && json['variants_json'] != '') {
      try {
        final List<dynamic> decoded =
            jsonDecode(json['variants_json'] as String);
        variantsList = decoded.map((v) => ProductVariant.fromJson(v)).toList();
      } catch (e) {
        variantsList = null;
      }
    }

    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      price: (json['price'] as num).toDouble(),
      salePrice: json['sale_price'] != null
          ? (json['sale_price'] as num).toDouble()
          : null,
      image: json['image'] as String?,
      quantity: json['quantity'] as int?,
      description: json['description'] as String?,
      isAvailable: (json['is_available'] as int) == 1,
      hasVariants: json['has_variants'] != null
          ? (json['has_variants'] as int) == 1
          : false,
      variants: variantsList,
    );
  }
}

class ProductVariant {
  final int id;
  final String type; // "Size", "Color", etc.
  final String name;
  final List<VariantOption> options;

  ProductVariant({
    required this.id,
    required this.type,
    required this.name,
    required this.options,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int,
      type: json['type'] as String,
      name: json['name'] as String,
      options: (json['options'] as List)
          .map((o) => VariantOption.fromJson(o))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}

class VariantOption {
  final int id;
  final String name;
  final double? priceModifier; // Additional cost (+ or -)

  VariantOption({
    required this.id,
    required this.name,
    this.priceModifier,
  });

  factory VariantOption.fromJson(Map<String, dynamic> json) {
    return VariantOption(
      id: json['id'] as int,
      name: json['name'] as String,
      priceModifier: json['price_modifier'] != null
          ? double.parse(json['price_modifier'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price_modifier': priceModifier,
    };
  }
}

class ProductCategory {
  final int id;
  final String name;
  final int productCount;

  ProductCategory({
    required this.id,
    required this.name,
    required this.productCount,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      productCount: json['product_count'] ?? 0,
    );
  }
}
