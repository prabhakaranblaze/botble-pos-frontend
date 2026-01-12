import 'dart:convert';
import '../config/env_config.dart';

class Product {
  final int id;
  final String name;
  final String? sku;
  final String? barcode;
  final double price;
  final double? salePrice;
  final String? image;
  final int quantity;
  final String? stockStatus;
  final String? description;
  final bool isAvailable;
  final bool isAvailableInPos;
  final bool allowCheckoutWhenOutOfStock;
  final bool withStorehouseManagement;
  final bool hasVariants;
  final List<ProductVariant>? variants;
  final ProductTax? tax;

  Product({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    required this.price,
    this.salePrice,
    this.image,
    this.quantity = 0,
    this.stockStatus,
    this.description,
    this.isAvailable = true,
    this.isAvailableInPos = true,
    this.allowCheckoutWhenOutOfStock = false,
    this.withStorehouseManagement = false,
    this.hasVariants = false,
    this.variants,
    this.tax,
  });

  /// Check if product is in stock
  bool get isInStock => quantity > 0 || stockStatus == 'in_stock';

  /// Check if product can be added to cart
  /// Returns true if: not tracking stock, has stock, or allows checkout when out of stock
  bool canAddToCart(int requestedQty, int currentCartQty) {
    // If not available in POS, cannot add
    if (!isAvailableInPos) return false;

    // If allows checkout when out of stock, always allow
    if (allowCheckoutWhenOutOfStock) return true;

    // If not tracking stock (no storehouse management), allow
    if (!withStorehouseManagement) return true;

    // Check if enough stock for requested + already in cart
    return (currentCartQty + requestedQty) <= quantity;
  }

  /// Get available quantity (considering what's already in cart)
  int availableQuantity(int currentCartQty) {
    if (!withStorehouseManagement) return 999999; // Unlimited
    if (allowCheckoutWhenOutOfStock) return 999999; // Unlimited
    return (quantity - currentCartQty).clamp(0, quantity);
  }

  double get finalPrice => salePrice ?? price;

  /// Check if product has selectable variant options (not just variant flag)
  bool get hasSelectableVariants {
    if (!hasVariants || variants == null) return false;
    return variants!.any((v) => v.options != null && v.options!.isNotEmpty);
  }

  /// Get full image URL with base URL prefix
  String? get fullImageUrl {
    if (image == null || image!.isEmpty) return null;
    return EnvConfig.getImageUrl(image);
  }

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
      quantity: (json['quantity'] as int?) ?? 0,
      stockStatus: json['stock_status'] as String?,
      description: json['description'] as String?,
      isAvailable: json['is_available'] ?? true,
      isAvailableInPos: (json['is_available_in_pos'] == 1 || json['is_available_in_pos'] == true),
      allowCheckoutWhenOutOfStock: (json['allow_checkout_when_out_of_stock'] == 1 || json['allow_checkout_when_out_of_stock'] == true),
      withStorehouseManagement: (json['with_storehouse_management'] == 1 || json['with_storehouse_management'] == true),
      hasVariants: json['has_variants'] ?? false,
      variants: json['variants'] != null
          ? (json['variants'] as List)
              .map((v) => ProductVariant.fromJson(v))
              .toList()
          : null,
      tax: json['tax'] != null ? ProductTax.fromJson(json['tax']) : null,
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
      'stock_status': stockStatus,
      'description': description,
      'is_available': isAvailable,
      'is_available_in_pos': isAvailableInPos,
      'allow_checkout_when_out_of_stock': allowCheckoutWhenOutOfStock,
      'with_storehouse_management': withStorehouseManagement,
      'has_variants': hasVariants,
      'variants': variants?.map((v) => v.toJson()).toList(),
      'tax': tax?.toJson(),
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
      'stock_status': stockStatus,
      'description': description,
      'is_available': isAvailable ? 1 : 0,
      'is_available_in_pos': isAvailableInPos ? 1 : 0,
      'allow_checkout_when_out_of_stock': allowCheckoutWhenOutOfStock ? 1 : 0,
      'with_storehouse_management': withStorehouseManagement ? 1 : 0,
      'has_variants': hasVariants ? 1 : 0,
      'variants_json': variants != null
          ? jsonEncode(variants!.map((v) => v.toJson()).toList())
          : null,
      'tax_json': tax != null ? jsonEncode(tax!.toJson()) : null,
      'synced': 1,
    };
  }

  // ⭐ FROM DATABASE JSON
  factory Product.fromDbJson(Map<String, dynamic> json) {
    List<ProductVariant>? variantsList;
    ProductTax? taxData;

    if (json['variants_json'] != null && json['variants_json'] != '') {
      try {
        final List<dynamic> decoded =
            jsonDecode(json['variants_json'] as String);
        variantsList = decoded.map((v) => ProductVariant.fromJson(v)).toList();
      } catch (e) {
        variantsList = null;
      }
    }

    if (json['tax_json'] != null && json['tax_json'] != '') {
      try {
        final Map<String, dynamic> decoded =
            jsonDecode(json['tax_json'] as String);
        taxData = ProductTax.fromJson(decoded);
      } catch (e) {
        taxData = null;
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
      quantity: (json['quantity'] as int?) ?? 0,
      stockStatus: json['stock_status'] as String?,
      description: json['description'] as String?,
      isAvailable: (json['is_available'] as int) == 1,
      isAvailableInPos: json['is_available_in_pos'] != null
          ? (json['is_available_in_pos'] as int) == 1
          : true,
      allowCheckoutWhenOutOfStock: json['allow_checkout_when_out_of_stock'] != null
          ? (json['allow_checkout_when_out_of_stock'] as int) == 1
          : false,
      withStorehouseManagement: json['with_storehouse_management'] != null
          ? (json['with_storehouse_management'] as int) == 1
          : false,
      hasVariants: json['has_variants'] != null
          ? (json['has_variants'] as int) == 1
          : false,
      variants: variantsList,
      tax: taxData,
    );
  }
}

class ProductVariant {
  final int id;
  final int? productId; // The actual product ID for this variant
  final bool isDefault;
  final String? type; // "Size", "Color", etc. - may be null in simple variants
  final String? name;
  final List<VariantOption>? options;

  ProductVariant({
    required this.id,
    this.productId,
    this.isDefault = false,
    this.type,
    this.name,
    this.options,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    List<VariantOption>? optionsList;
    if (json['options'] != null) {
      optionsList = (json['options'] as List)
          .map((o) => VariantOption.fromJson(o))
          .toList();
    }

    return ProductVariant(
      id: json['id'] as int,
      productId: json['product_id'] as int?,
      isDefault: json['is_default'] ?? false,
      type: json['type'] as String?,
      name: json['name'] as String?,
      options: optionsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'is_default': isDefault,
      'type': type,
      'name': name,
      'options': options?.map((o) => o.toJson()).toList(),
    };
  }
}

class VariantOption {
  final int id;
  final String name;
  final String? color; // Hex color code (e.g., "#FF0000")
  final String? image; // Image URL for this option
  final double? priceModifier; // Additional cost (+ or -)

  VariantOption({
    required this.id,
    required this.name,
    this.color,
    this.image,
    this.priceModifier,
  });

  factory VariantOption.fromJson(Map<String, dynamic> json) {
    return VariantOption(
      id: json['id'] as int,
      name: json['name'] as String,
      color: json['color'] as String?,
      image: json['image'] as String?,
      priceModifier: json['price_modifier'] != null
          ? double.parse(json['price_modifier'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'image': image,
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

/// Tax information for a product
class ProductTax {
  final int? id;
  final String title;
  final double percentage;

  ProductTax({
    this.id,
    required this.title,
    required this.percentage,
  });

  factory ProductTax.fromJson(Map<String, dynamic> json) {
    return ProductTax(
      id: json['id'] as int?,
      title: json['title'] as String? ?? 'Tax',
      percentage: json['percentage'] != null
          ? double.parse(json['percentage'].toString())
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'percentage': percentage,
    };
  }

  /// Calculate tax amount for a given price
  double calculateTax(double price) {
    return price * (percentage / 100);
  }
}
