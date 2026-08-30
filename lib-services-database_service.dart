import 'dart:io';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/product.dart';
// ... other imports

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static bool _initialized = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for Windows
    if (Platform.isWindows) {
      sqfliteFfiInit();
    }

    Directory appDir;
    if (Platform.isWindows) {
      appDir = await getApplicationDocumentsDirectory();
    } else {
      appDir = await getApplicationDocumentsDirectory();
    }

    final dbPath = join(appDir.path, 'moon_cosmetics.db');
    debugPrint('Database path: $dbPath');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating database tables...');
    
    // Read and execute schema from file
    final schema = await rootBundle.loadString('assets/database/schema.sql');
    final statements = schema.split(';').where((s) => s.trim().isNotEmpty);
    
    for (var statement in statements) {
      try {
        await db.execute(statement.trim());
      } catch (e) {
        debugPrint('Error executing statement: $e');
      }
    }
    
    debugPrint('Database created successfully.');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from $oldVersion to $newVersion');
    // Migration logic
  }

  // ============ USER METHODS ============
  
  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND is_active = 1',
      whereArgs: [username],
    );
    
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> authenticateUser(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND password = ? AND is_active = 1',
      whereArgs: [username, password],
    );
    
    if (maps.isNotEmpty) {
      final user = User.fromMap(maps.first);
      // Update last login
      await db.update(
        'users',
        {'last_login': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return user;
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'is_active = 1',
      orderBy: 'full_name ASC',
    );
    
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<int> createUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    final updated = user.copyWith(updatedAt: DateTime.now());
    return await db.update(
      'users',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.update(
      'users',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ CATEGORY METHODS ============
  
  Future<List<Category>> getAllCategories({bool includeInactive = false}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: includeInactive ? null : 'is_active = 1',
      orderBy: 'name ASC',
    );
    
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<List<Category>> getSubCategories(int parentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'parent_id = ? AND is_active = 1',
      whereArgs: [parentId],
      orderBy: 'name ASC',
    );
    
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  Future<Category?> getCategoryByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [name],
    );
    
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  Future<int> createCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    final updated = category.copyWith(updatedAt: DateTime.now());
    return await db.update(
      'categories',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> toggleCategoryStatus(int id, bool active) async {
    final db = await database;
    return await db.update(
      'categories',
      {
        'is_active': active ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ PRODUCT METHODS ============
  
  Future<List<Product>> getAllProducts({bool includeInactive = false}) async {
    final db = await database;
    final String sql = '''
      SELECT p.*, c.name as category_name, s.name as supplier_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.is_deleted = 0 ${includeInactive ? '' : 'AND p.is_active = 1'}
      ORDER BY p.name ASC
    ''';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql);
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final String sql = '''
      SELECT p.*, c.name as category_name, s.name as supplier_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.is_deleted = 0 AND p.is_active = 1
      AND (
        p.name LIKE ? OR 
        p.barcode LIKE ? OR 
        p.sku LIKE ? OR 
        p.brand LIKE ?
      )
      ORDER BY p.name ASC
    ''';
    
    final searchPattern = '%$query%';
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      sql,
      [searchPattern, searchPattern, searchPattern, searchPattern],
    );
    
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final String sql = '''
      SELECT p.*, c.name as category_name, s.name as supplier_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.barcode = ? AND p.is_deleted = 0 AND p.is_active = 1
    ''';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [barcode]);
    
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<Product?> getProductBySku(String sku) async {
    final db = await database;
    final String sql = '''
      SELECT p.*, c.name as category_name, s.name as supplier_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.sku = ? AND p.is_deleted = 0 AND p.is_active = 1
    ''';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [sku]);
    
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final db = await database;
    final String sql = '''
      SELECT p.*, c.name as category_name, s.name as supplier_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.category_id = ? AND p.is_deleted = 0 AND p.is_active = 1
      ORDER BY p.name ASC
    ''';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [categoryId]);
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getExpiringProducts(int daysThreshold) async {
    final db = await database;
    final expiryDate = DateTime.now().add(Duration(days: daysThreshold));
    final dateString = expiryDate.toIso8601String().split('T').first;
    
    final String sql = '''
      SELECT p.*, c.name as category_name, s.name as supplier_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.is_deleted = 0 AND p.is_active = 1
      AND p.expiry_date <= ? AND p.expiry_date >= date('now')
      ORDER BY p.expiry_date ASC
    ''';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [dateString]);
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getExpiredProducts() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T').first;
    
    final String sql = '''
      SELECT p.*, c.name as category_name, s.name as supplier_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.is_deleted = 0 AND p.is_active = 1
      AND p.expiry_date < ?
      ORDER BY p.expiry_date ASC
    ''';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [today]);
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final String sql = '''
      SELECT p.*, c.name as category_name, s.name as supplier_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.is_deleted = 0 AND p.is_active = 1
      AND p.current_stock <= p.minimum_stock
      ORDER BY p.current_stock ASC
    ''';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql);
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> createProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    final updated = product.copyWith(updatedAt: DateTime.now());
    return await db.update(
      'products',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> softDeleteProduct(int id) async {
    final db = await database;
    return await db.update(
      'products',
      {
        'is_deleted': 1,
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateProductStock(int id, int newStock) async {
    final db = await database;
    return await db.update(
      'products',
      {
        'current_stock': newStock,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ BATCH METHODS ============
  
  Future<List<Map<String, dynamic>>> getProductBatches(int productId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'batches',
      where: 'product_id = ? AND remaining_quantity > 0 AND is_active = 1',
      whereArgs: [productId],
      orderBy: 'expiry_date ASC',
    );
    return maps;
  }

  Future<int> createBatch(Map<String, dynamic> batch) async {
    final db = await database;
    return await db.insert('batches', batch);
  }

  Future<int> updateBatchRemaining(int batchId, int newRemaining) async {
    final db = await database;
    return await db.update(
      'batches',
      {
        'remaining_quantity': newRemaining,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [batchId],
    );
  }

  // ============ STOCK TRANSACTION METHODS ============
  
  Future<int> createStockTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.insert('stock_transactions', transaction);
  }

  Future<List<Map<String, dynamic>>> getProductStockHistory(int productId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_transactions',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC',
      limit: 100,
    );
    return maps;
  }

  // ============ SHOP SETTINGS ============
  
  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shop_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    
    if (maps.isNotEmpty) {
      return maps.first['value'];
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    final exists = await getSetting(key) != null;
    
    if (exists) {
      await db.update(
        'shop_settings',
        {
          'value': value,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'key = ?',
        whereArgs: [key],
      );
    } else {
      await db.insert(
        'shop_settings',
        {
          'key': key,
          'value': value,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('shop_settings');
    
    final Map<String, String> settings = {};
    for (var map in maps) {
      settings[map['key']] = map['value'] ?? '';
    }
    return settings;
  }

  // ============ AUDIT LOG ============
  
  Future<void> logAction({
    required int? userId,
    required String action,
    String? tableName,
    int? recordId,
    String? oldValue,
    String? newValue,
    String? ipAddress,
    String? userAgent,
  }) async {
    final db = await database;
    await db.insert('audit_logs', {
      'user_id': userId,
      'action': action,
      'table_name': tableName,
      'record_id': recordId,
      'old_value': oldValue,
      'new_value': newValue,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ============ DATABASE UTILITY ============
  
  Future<void> backupDatabase(String backupPath) async {
    final db = await database;
    final dbPath = db.path;
    
    final File sourceFile = File(dbPath);
    if (await sourceFile.exists()) {
      final backupFile = File(backupPath);
      await sourceFile.copy(backupFile.path);
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}