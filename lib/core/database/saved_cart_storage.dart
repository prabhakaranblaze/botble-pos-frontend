import '../models/saved_cart.dart';

/// Abstract interface for saved cart storage
/// Implemented differently for desktop (SQLite) and web (LocalStorage)
abstract class SavedCartStorage {
  /// Initialize the storage
  Future<void> init();

  /// Save a cart
  Future<void> saveCart(SavedCart cart);

  /// Get all saved carts for a user
  Future<List<SavedCart>> getSavedCartsByUser(int userId);

  /// Get a cart by ID
  Future<SavedCart?> getCartById(String id, int userId);

  /// Delete a cart
  Future<void> deleteCart(String id, int userId);

  /// Get the count of saved carts for a user
  Future<int> getCartCountByUser(int userId);

  /// Clear all saved carts
  Future<void> clearAll();

  /// Close the storage
  Future<void> close();
}
