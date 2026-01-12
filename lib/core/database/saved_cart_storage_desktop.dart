import '../models/saved_cart.dart';
import 'saved_cart_storage.dart';
import 'saved_cart_database.dart';

/// Factory function for desktop platform
SavedCartStorage createSavedCartStorage() => SavedCartStorageDesktop();

/// Desktop implementation using SQLite (existing SavedCartDatabase)
class SavedCartStorageDesktop implements SavedCartStorage {
  final SavedCartDatabase _db = SavedCartDatabase();

  @override
  Future<void> init() async {
    // Database initializes lazily when first accessed
    await _db.database;
  }

  @override
  Future<void> saveCart(SavedCart cart) => _db.saveCart(cart);

  @override
  Future<List<SavedCart>> getSavedCartsByUser(int userId) =>
      _db.getSavedCartsByUser(userId);

  @override
  Future<SavedCart?> getCartById(String id, int userId) =>
      _db.getCartById(id, userId);

  @override
  Future<void> deleteCart(String id, int userId) =>
      _db.deleteCart(id, userId);

  @override
  Future<int> getCartCountByUser(int userId) =>
      _db.getCartCountByUser(userId);

  @override
  Future<void> clearAll() => _db.clearAll();

  @override
  Future<void> close() => _db.close();
}
