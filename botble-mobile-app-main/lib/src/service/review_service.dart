import 'package:martfury/src/service/base_service.dart';

class ReviewService extends BaseService {
  Future<Map<String, dynamic>> getReviews({int page = 1}) async {
    try {
      final response = await get('/api/v1/ecommerce/reviews?page=$page');
      return response;
    } catch (e) {
      throw Exception('Failed to load reviews: $e');
    }
  }

  Future<void> deleteReview(int reviewId) async {
    try {
      await delete('/api/v1/ecommerce/reviews/$reviewId', {});
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }
}
