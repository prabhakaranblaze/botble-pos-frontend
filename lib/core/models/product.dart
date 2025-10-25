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
  });

  double get finalPrice => salePrice ?? price;

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
    );
  }

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
    };
  }

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
      'synced': 1,
    };
  }

  factory Product.fromDbJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      price: json['price'] as double,
      salePrice: json['sale_price'] as double?,
      image: json['image'] as String?,
      quantity: json['quantity'] as int?,
      description: json['description'] as String?,
      isAvailable: (json['is_available'] as int) == 1,
    );
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
