import 'dart:convert';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../models/saved_cart.dart';
import 'saved_cart_storage.dart';

/// Factory function for web platform
SavedCartStorage createSavedCartStorage() => SavedCartStorageWeb();

/// Web implementation of SavedCartStorage using LocalStorage
class SavedCartStorageWeb implements SavedCartStorage {
  static const String _storageKey = 'pos_saved_carts';

  List<SavedCart> _carts = [];

  @override
  Future<void> init() async {
    debugPrint('📂 SavedCartStorageWeb: Initializing...');
    await _loadFromStorage();
    debugPrint('📂 SavedCartStorageWeb: Loaded ${_carts.length} carts');
  }

  Future<void> _loadFromStorage() async {
    try {
      final data = html.window.localStorage[_storageKey];
      if (data != null && data.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(data);
        _carts = jsonList.map((j) => SavedCart.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('❌ SavedCartStorageWeb: Error loading: $e');
      _carts = [];
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final jsonList = _carts.map((c) => c.toJson()).toList();
      html.window.localStorage[_storageKey] = json.encode(jsonList);
    } catch (e) {
      debugPrint('❌ SavedCartStorageWeb: Error saving: $e');
    }
  }

  @override
  Future<void> saveCart(SavedCart cart) async {
    // Remove existing cart with same ID
    _carts.removeWhere((c) => c.id == cart.id);
    // Add new cart
    _carts.add(cart);
    await _saveToStorage();
    debugPrint('💾 SavedCartStorageWeb: Saved "${cart.name}"');
  }

  @override
  Future<List<SavedCart>> getSavedCartsByUser(int userId) async {
    final userCarts = _carts.where((c) => c.userId == userId).toList();
    // Sort by savedAt descending
    userCarts.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    debugPrint('📋 SavedCartStorageWeb: Found ${userCarts.length} carts for user $userId');
    return userCarts;
  }

  @override
  Future<SavedCart?> getCartById(String id, int userId) async {
    try {
      return _carts.firstWhere(
        (c) => c.id == id && c.userId == userId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteCart(String id, int userId) async {
    final initialLength = _carts.length;
    _carts.removeWhere((c) => c.id == id && c.userId == userId);

    if (_carts.length < initialLength) {
      await _saveToStorage();
      debugPrint('🗑️ SavedCartStorageWeb: Deleted cart $id');
    } else {
      debugPrint('⚠️ SavedCartStorageWeb: Cart $id not found');
    }
  }

  @override
  Future<int> getCartCountByUser(int userId) async {
    return _carts.where((c) => c.userId == userId).length;
  }

  @override
  Future<void> clearAll() async {
    _carts.clear();
    html.window.localStorage.remove(_storageKey);
    debugPrint('🗑️ SavedCartStorageWeb: All saved carts cleared');
  }

  @override
  Future<void> close() async {
    // Nothing to close for LocalStorage
  }
}
