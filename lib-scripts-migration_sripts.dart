import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../services/database_service.dart';

class MigrationScript {
  final DatabaseService _db = DatabaseService();

  Future<void> migrateFromOldDatabase(String oldDbPath) async {
    try {
      // Check if old database exists
      final oldDbFile = File(oldDbPath);
      if (!await oldDbFile.exists()) {
        print('Old database not found at: $oldDbPath');
        return;
      }

      // Open old database
      final oldDb = await openDatabase(oldDbPath);
      
      // Start migration transaction
      final newDb = await _db.database;
      await newDb.transaction((txn) async {
        // Migrate categories
        final categories = await oldDb.query('categories');
        for (var cat in categories) {
          // Check if category already exists
          final existing = await txn.query(
            'categories',
            where: 'name = ?',
            whereArgs: [cat['name']],
          );
          if (existing.isEmpty) {
            await txn.insert('categories', {
              'name': cat['name'],
              'description': cat['description'],
              'is_active': cat['is_active'] ?? 1,
              'created_at': cat['created_at'] ?? DateTime.now().toIso8601String(),
            });
          }
        }

        // Migrate suppliers
        final suppliers = await oldDb.query('suppliers');
        for (var sup in suppliers) {
          final existing = await txn.query(
            'suppliers',
            where: 'name = ?',
            whereArgs: [sup['name']],
          );
          if (existing.isEmpty) {
            await txn.insert('suppliers', {
              'name': sup['name'],
              'phone': sup['phone'],
              'address': sup['address'],
              'opening_balance': sup['opening_balance'] ?? 0,
              'is_active': 1,
              'created_at': sup['created_at'] ?? DateTime.now().toIso8601String(),
            });
          }
        }

        // Migrate customers
        final customers = await oldDb.query('customers');
        for (var cust in customers) {
          final existing = await txn.query(
            'customers',
            where: 'phone = ?',
            whereArgs: [cust['phone']],
          );
          if (existing.isEmpty) {
            await txn.insert('customers', {
              'name': cust['name'],
              'phone': cust['phone'],
              'address': cust['address'],
              'opening_balance': cust['opening_balance'] ?? 0,
              'is_active': 1,
              'created_at': cust['created_at'] ?? DateTime.now().toIso8601String(),
            });
          }
        }

        // Migrate products (skip mobile/accessories specific fields)
        final products = await oldDb.query('products');
        for (var prod in products) {
          // Skip if product is mobile or accessory
          if (prod['category'] == 'Mobile' || 
              prod['category'] == 'Accessories' ||
              prod['category'] == 'Repair') {
            continue;
          }

          // Get or create category
          var categoryId = await _getOrCreateCategory(txn, prod['category']);
          var subCategoryId = await _getOrCreateCategory(txn, prod['sub_category']);

          await txn.insert('products', {
            'name': prod['name'],
            'brand': prod['brand'],
            'sku': prod['sku'],
            'barcode': prod['barcode'],
            'category_id': categoryId,
            'sub_category_id': subCategoryId,
            'variant': prod['variant'],
            'size': prod['size'],
            'unit': prod['unit'],
            'purchase_price': prod['purchase_price'] ?? 0,
            'retail_price': prod['retail_price'] ?? 0,
            'wholesale_price': prod['wholesale_price'] ?? 0,
            'minimum_stock': prod['minimum_stock'] ?? 0,
            'current_stock': prod['current_stock'] ?? 0,
            'expiry_date': prod['expiry_date'],
            'supplier_id': await _getSupplierId(txn, prod['supplier']),
            'description': prod['description'],
            'is_active': prod['is_active'] ?? 1,
            'created_at': prod['created_at'] ?? DateTime.now().toIso8601String(),
          });
        }

        print('Migration completed successfully!');
      });

      await oldDb.close();
      
    } catch (e) {
      print('Migration failed: $e');
      rethrow;
    }
  }

  Future<int?> _getOrCreateCategory(Transaction txn, String? name) async {
    if (name == null || name.isEmpty) return null;
    
    final result = await txn.query(
      'categories',
      where: 'name = ?',
      whereArgs: [name],
    );
    
    if (result.isNotEmpty) {
      return result.first['id'];
    }
    
    final id = await txn.insert('categories', {
      'name': name,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<int?> _getSupplierId(Transaction txn, String? name) async {
    if (name == null || name.isEmpty) return null;
    
    final result = await txn.query(
      'suppliers',
      where: 'name = ?',
      whereArgs: [name],
    );
    
    if (result.isNotEmpty) {
      return result.first['id'];
    }
    return null;
  }
}