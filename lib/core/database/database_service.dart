import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/product.dart';
import '../models/cart.dart';
import '../models/session.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    String path = join(await getDatabasesPath(), 'pos_local.db');

    return await openDatabase(
      path,
      version: 3, // ⭐ UPDATED VERSION for tax support
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Products table with variants and tax support
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        sku TEXT,
        barcode TEXT,
        price REAL NOT NULL,
        sale_price REAL,
        image TEXT,
        quantity INTEGER,
        description TEXT,
        is_available INTEGER DEFAULT 1,
        has_variants INTEGER DEFAULT 0,
        variants_json TEXT,
        tax_json TEXT,
        synced INTEGER DEFAULT 1,
        last_updated TEXT
      )
    ''');

    // Pending orders table (for offline orders)
    await db.execute('''
      CREATE TABLE pending_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        customer_id INTEGER,
        payment_details TEXT,
        items TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY,
        cash_register_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        opened_at TEXT NOT NULL,
        closed_at TEXT,
        opening_cash REAL NOT NULL,
        closing_cash REAL,
        opening_notes TEXT,
        closing_notes TEXT,
        difference REAL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        attempts INTEGER DEFAULT 0
      )
    ''');
  }

  // ⭐ MIGRATION for existing databases
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for variants support
      await db.execute(
          'ALTER TABLE products ADD COLUMN has_variants INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE products ADD COLUMN variants_json TEXT');
    }
    if (oldVersion < 3) {
      // Add tax support
      await db.execute('ALTER TABLE products ADD COLUMN tax_json TEXT');
    }
  }

  // Product operations
  Future<void> saveProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();

    for (var product in products) {
      batch.insert(
        'products',
        {
          ...product.toDbJson(),
          'last_updated': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Product>> getProducts({String? search, int? limit}) async {
    final db = await database;

    String query = 'SELECT * FROM products WHERE is_available = 1';
    List<dynamic> args = [];

    if (search != null && search.isNotEmpty) {
      query += ' AND (name LIKE ? OR sku LIKE ? OR barcode LIKE ?)';
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }

    query += ' ORDER BY name ASC';

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }

    final maps = await db.rawQuery(query, args);
    return maps.map((map) => Product.fromDbJson(map)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'barcode = ? AND is_available = 1',
      whereArgs: [barcode],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Product.fromDbJson(maps.first);
  }

  // Order operations
  Future<int> savePendingOrder(Order order, List<CartItem> items) async {
    final db = await database;

    return await db.insert('pending_orders', {
      'code': order.code,
      'amount': order.amount,
      'payment_method': order.paymentMethod,
      'status': order.status,
      'created_at': order.createdAt.toIso8601String(),
      'customer_id': order.customer?.id,
      'payment_details': order.paymentDetails,
      'items': _encodeItems(items),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingOrders() async {
    final db = await database;
    return await db.query(
      'pending_orders',
      where: 'synced = 0',
      orderBy: 'created_at DESC',
    );
  }

  Future<void> markOrderAsSynced(int orderId) async {
    final db = await database;
    await db.update(
      'pending_orders',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // Session operations
  Future<void> saveSession(PosSession session) async {
    final db = await database;
    await db.insert(
      'sessions',
      session.toDbJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PosSession?> getActiveSession() async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'status = ?',
      whereArgs: ['open'],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return PosSession.fromJson(maps.first);
  }

  // Sync queue operations
  Future<void> addToSyncQueue(String type, String data) async {
    final db = await database;
    await db.insert('sync_queue', {
      'type': type,
      'data': data,
      'created_at': DateTime.now().toIso8601String(),
      'attempts': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'attempts < 3',
      orderBy: 'created_at ASC',
    );
  }

  Future<void> removeSyncItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementSyncAttempts(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE sync_queue SET attempts = attempts + 1 WHERE id = ?',
      [id],
    );
  }

  // Helper methods
  String _encodeItems(List<CartItem> items) {
    return items.map((item) => item.toJson().toString()).join('|||');
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('products');
    await db.delete('pending_orders');
    await db.delete('sessions');
    await db.delete('sync_queue');
  }
}

Future<String> getDatabasesPath() async {
  // For desktop, use app documents directory
  if (Platform.isWindows) {
    return join(
      Platform.environment['USERPROFILE']!,
      'Documents',
      'StampSmartPOS',
    );
  } else if (Platform.isLinux) {
    return join(
      Platform.environment['HOME']!,
      '.stampsmart_pos',
    );
  } else if (Platform.isMacOS) {
    return join(
      Platform.environment['HOME']!,
      'Library',
      'Application Support',
      'StampSmartPOS',
    );
  }
  return '';
}
