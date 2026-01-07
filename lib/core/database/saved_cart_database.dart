import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/saved_cart.dart';

class SavedCartDatabase {
  static final SavedCartDatabase _instance = SavedCartDatabase._internal();
  factory SavedCartDatabase() => _instance;
  SavedCartDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pos_saved_carts.db');

    debugPrint('📂 SavedCartDB: Initializing at $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE saved_carts (
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        name TEXT NOT NULL,
        saved_at TEXT NOT NULL,
        customer_id TEXT,
        customer_name TEXT,
        items TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        total REAL NOT NULL,
        is_online INTEGER NOT NULL DEFAULT 0,
        online_id INTEGER
      )
    ''');

    await db.execute('CREATE INDEX idx_user_id ON saved_carts(user_id)');
    await db.execute('CREATE INDEX idx_saved_at ON saved_carts(saved_at DESC)');

    debugPrint('✅ SavedCartDB: Tables created');
  }

  Future<void> saveCart(SavedCart cart) async {
    final db = await database;
    await db.insert('saved_carts', cart.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    debugPrint('💾 SavedCartDB: Saved "${cart.name}"');
  }

  Future<List<SavedCart>> getSavedCartsByUser(int userId) async {
    final db = await database;
    final maps = await db.query(
      'saved_carts',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'saved_at DESC',
    );
    debugPrint('📋 SavedCartDB: Found ${maps.length} carts for user $userId');
    return maps.map((map) => SavedCart.fromDbMap(map)).toList();
  }

  Future<SavedCart?> getCartById(String id, int userId) async {
    final db = await database;
    final maps = await db.query(
      'saved_carts',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    return maps.isEmpty ? null : SavedCart.fromDbMap(maps.first);
  }

  Future<void> deleteCart(String id, int userId) async {
    final db = await database;
    final count = await db.delete(
      'saved_carts',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    debugPrint(count > 0 ? '🗑️ Deleted cart $id' : '⚠️ Cart $id not found');
  }

  Future<int> getCartCountByUser(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM saved_carts WHERE user_id = ?',
      [userId],
    );
    // ✅ Parse directly from result
    if (result.isEmpty) return 0;
    return result.first['count'] as int? ?? 0;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Clear all saved carts
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('saved_carts');
    debugPrint('🗑️ SavedCartDB: All saved carts cleared');
  }
}
