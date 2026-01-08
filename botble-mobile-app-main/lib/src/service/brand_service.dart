import 'package:martfury/src/model/brand.dart';
import 'package:martfury/src/service/base_service.dart';

class BrandService extends BaseService {
  Future<List<Brand>> getBrands({bool? isFeatured}) async {
    String endpoint = '/api/v1/ecommerce/brands';
    if (isFeatured != null) {
      endpoint += '?is_featured=${isFeatured ? '1' : '0'}';
    }

    try {
      final response = await get(endpoint);
      final List<dynamic> brandsJson = response['data'];
      return brandsJson.map((json) => Brand.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load brands: $e');
    }
  }
}
