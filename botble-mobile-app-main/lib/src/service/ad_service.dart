import 'package:martfury/core/app_config.dart';
import 'package:martfury/src/model/ad.dart';
import 'package:martfury/src/service/base_service.dart';

class AdService extends BaseService {
  Future<List<Ad>> getAds() async {
    if (AppConfig.adKeys == null || AppConfig.adKeys!.isEmpty) {
      return [];
    }
    try {
      final response = await get(
        '/api/v1/ads?keys[]=${AppConfig.adKeys!.join('&keys[]=')}',
      );

      final List<dynamic> adList = response['data'];
      return adList.map((json) => Ad.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load ads: $e');
    }
  }
}
