import '../models/saved_cart.dart';
import 'saved_cart_storage.dart';

/// Stub factory - should never be used
SavedCartStorage createSavedCartStorage() => _StubSavedCartStorage();

class _StubSavedCartStorage implements SavedCartStorage {
  @override
  Future<void> init() async {}

  @override
  Future<void> saveCart(SavedCart cart) async {}

  @override
  Future<List<SavedCart>> getSavedCartsByUser(int userId) async => [];

  @override
  Future<SavedCart?> getCartById(String id, int userId) async => null;

  @override
  Future<void> deleteCart(String id, int userId) async {}

  @override
  Future<int> getCartCountByUser(int userId) async => 0;

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> close() async {}
}
