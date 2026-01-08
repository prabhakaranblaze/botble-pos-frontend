import 'dart:convert';
import 'dart:io';
import 'package:martfury/src/model/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:martfury/src/service/base_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:martfury/core/app_config.dart';
import 'package:martfury/src/service/token_service.dart';

class ProductService extends BaseService {
  static const String _recentlyViewedKey = 'recently_viewed_products';
  static const int _maxRecentlyViewed = 20;

  // Add a product to recently viewed
  static Future<void> addToRecentlyViewed(Map<String, dynamic> product) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedProducts = prefs.getString(_recentlyViewedKey);

      List<Map<String, dynamic>> recentlyViewed = [];
      if (storedProducts != null) {
        final List<dynamic> decoded = jsonDecode(storedProducts);
        recentlyViewed = List<Map<String, dynamic>>.from(decoded);
      }

      // Create minimal product data
      final minimalProduct = {
        'id': product['id'],
        'slug': product['slug'],
        'image': product['image'] ?? product['images']?[0],
      };

      // Remove if product already exists
      recentlyViewed.removeWhere((item) => item['id'] == product['id']);

      // Add new product at the beginning
      recentlyViewed.insert(0, minimalProduct);

      // Keep only the last 20 products
      if (recentlyViewed.length > _maxRecentlyViewed) {
        recentlyViewed = recentlyViewed.sublist(0, _maxRecentlyViewed);
      }

      // Save back to storage
      await prefs.setString(_recentlyViewedKey, jsonEncode(recentlyViewed));
    } catch (e) {
      debugPrint('Error adding to recently viewed: $e');
    }
  }

  // Get recently viewed products
  static Future<List<Map<String, dynamic>>> getRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedProducts = prefs.getString(_recentlyViewedKey);

      if (storedProducts != null) {
        final List<dynamic> decoded = jsonDecode(storedProducts);
        return List<Map<String, dynamic>>.from(decoded);
      }

      return [];
    } catch (e) {
      debugPrint('Error getting recently viewed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getProductDetail(String slug) async {
    final response = await get('/api/v1/ecommerce/products/$slug?thumbnail_size=${AppConfig.productImageThumbnailSize}');

    return response;
  }

  Future<List<Map<String, dynamic>>> getRelatedProducts(String slug) async {
    final response = await get('/api/v1/ecommerce/products/$slug/related?thumbnail_size=${AppConfig.productImageThumbnailSize}');
    return List<Map<String, dynamic>>.from(response['data']);
  }

  Future<int?> getProductVariationId(
    int productId,
    List<int> attributes,
  ) async {
    final response = await post(
      '/api/v1/ecommerce/products/$productId/variation',
      {'attributes': attributes},
    );
    return response['id'];
  }

  Future<Map<String, dynamic>?> getProductVariation(
    int productId,
    List<int> attributes,
  ) async {
    try {
      final response = await get(
        '/api/v1/ecommerce/product-variation/$productId?${attributes.map((id) => 'attributes[]=$id').join('&')}',
      );
      return response['data'];
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final response = await get('/api/v1/ecommerce/products?q=$query&thumbnail_size=${AppConfig.productImageThumbnailSize}');

    return List<Map<String, dynamic>>.from(response['data']);
  }

  Future<Map<String, dynamic>> getFlashSaleProducts() async {
    try {
      final response = await get('/api/v1/ecommerce/flash-sales?thumbnail_size=${AppConfig.productImageThumbnailSize}');

      final List<dynamic> data = response['data'];

      final flashSale = data[0];

      return {
        'endDate': DateTime.parse(flashSale['end_date']),
        'products': flashSale['products'] as List<dynamic>,
        'name': flashSale['name'] as String,
      };
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getProductReviews(String slug) async {
    try {
      String endpoint = '/api/v1/ecommerce/products/$slug/reviews';

      final response = await get(endpoint);

      return response['data'];
    } catch (e) {
      throw Exception('Failed to load product reviews: $e');
    }
  }

  Future<Map<String, dynamic>> submitProductReview({
    required int productId,
    required int rating,
    required String comment,
    List<File>? images,
  }) async {
    try {
      if (images != null && images.isNotEmpty) {
        // Use multipart request for images
        return await _submitReviewWithImages(
          productId: productId,
          rating: rating,
          comment: comment,
          images: images,
        );
      } else {
        // Use regular JSON request for text-only reviews
        final response = await post('/api/v1/ecommerce/reviews', {
          'product_id': productId,
          'star': rating,
          'comment': comment,
        });

        return response;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _submitReviewWithImages({
    required int productId,
    required int rating,
    required String comment,
    required List<File> images,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/ecommerce/reviews'),
      );

      // Add authorization header
      final token = await TokenService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add form fields
      request.fields['product_id'] = productId.toString();
      request.fields['star'] = rating.toString();
      request.fields['comment'] = comment;

      // Add image files
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        request.files.add(
          await http.MultipartFile.fromPath(
            'images[]', // Use array notation for multiple images
            file.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to submit review');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFilters(int? categoryId) async {
    String endpoint = '/api/v1/ecommerce/filters';
    if (categoryId != null) {
      endpoint += '?category=$categoryId';
    }

    final response = await get(endpoint);
    return response['data'];
  }

  Future<Map<String, dynamic>> getAllProducts({
    Map<String, dynamic>? filter,
    String? order,
    int page = 1,
  }) async {
    try {
      String endpoint = '/api/v1/ecommerce/products';
      final queryParameters = <String>[];

      // Add page parameter
      queryParameters.add('page=$page');
      
      // Add thumbnail size parameter from config
      queryParameters.add('thumbnail_size=${AppConfig.productImageThumbnailSize}');

      // Add filter parameters
      if (filter != null && filter.isNotEmpty) {
        filter.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            if (key == 'brands' || key == 'tags' || key == 'categories') {
              queryParameters.add(value.map((v) => '$key[]=$v').join('&'));
            } else if (key.startsWith('attr_set_')) {
              final attrSlug = key.substring('attr_set_'.length);
              queryParameters.add(
                value.map((v) => 'attributes[$attrSlug][]=$v').join('&'),
              );
            }
          } else if (key == 'min_price' || key == 'max_price') {
            queryParameters.add('$key=$value');
          } else if (value != null) {
            queryParameters.add('$key=$value');
          }
        });
      }

      if (order != null && order.isNotEmpty) {
        queryParameters.add('sort-by=$order');
      }

      if (queryParameters.isNotEmpty) {
        endpoint += '?${queryParameters.join('&')}';
      }

      final response = await get(endpoint);
    

      return {
        'data': List<Product>.from(
          response['data'].map((json) => Product.fromJson(json)),
        ),
        'meta': response['meta'],
        'links': response['links'],
      };
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }
}
