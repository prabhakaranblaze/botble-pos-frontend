import 'package:martfury/src/model/category.dart';
import 'package:martfury/src/service/base_service.dart';

class CategoryService extends BaseService {
  Future<List<Category>> getCategories({bool? isFeatured}) async {
    String endpoint = '/api/v1/ecommerce/product-categories';
    if (isFeatured != null) {
      endpoint += '?is_featured=${isFeatured ? '1' : '0'}';
    }

    try {
      final response = await get(endpoint);
      final List<dynamic> categoriesJson = response['data'];
      return categoriesJson.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }
}
