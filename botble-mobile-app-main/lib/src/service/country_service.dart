import 'package:martfury/src/service/base_service.dart';
import 'package:martfury/src/model/country.dart';

class CountryService extends BaseService {
  Future<List<Country>> getCountries() async {
    try {
      final response = await get('/api/v1/ecommerce/countries');

      final List<dynamic> countriesJson = response['data'];
      return countriesJson.map((json) => Country.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch countries: $e');
    }
  }
}
