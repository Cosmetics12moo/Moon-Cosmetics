import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../services/database_service.dart';
import '../../widgets/common/search_field.dart';
import 'product_form_dialog.dart';
import 'product_detail_screen.dart';
import '../../utils/format_helpers.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, active, inactive, low-stock

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _db.getAllProducts(includeInactive: true);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<Product> _getFilteredProducts() {
    var filtered = _products;
    
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((p) =>
        p.name.toLowerCase().contains(query) ||
        (p.barcode?.toLowerCase().contains(query) ?? false) ||
        (p.sku?.toLowerCase().contains(query) ?? false) ||
        (p.brand?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    
    switch (_filter) {
      case 'active':
        filtered = filtered.where((p) => p.isActive == 1).toList();
        break;
      case 'inactive':
        filtered = filtered.where((p) => p.isActive == 0).toList();
        break;
      case 'low-stock':
        filtered = filtered.where((p) => p.isLowStock).toList();
        break;
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
            onPressed: () async {
              final result = await showDialog<Product>(
                context: context,
                builder: (context) => const ProductFormDialog(),
              );
              if (result != null) {
                _loadProducts();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SearchField(
                    controller: _searchController,
                    hintText: 'Search products...',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _filter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Products')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                    DropdownMenuItem(value: 'low-stock', child: Text('Low Stock')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filter = value!;
                    });
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadProducts,
                ),
              ],
            ),
          ),
          
          // Product Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_getFilteredProducts().length} products',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                if (_filter == 'low-stock')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Low Stock Alert',
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Product List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredProducts().isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No products found', style: TextStyle(fontSize: 18)),
                            Text('Add your first product', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _getFilteredProducts().length,
                        itemBuilder: (context, index) {
                          final product = _getFilteredProducts()[index];
                          return _buildProductCard(product);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: product.imagePath != null
              ? Image.file(
                  File(product.imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                )
              : const Icon(Icons.inventory, color: Colors.grey),
        ),
        title: Text(
          product.name,
          style: TextStyle(
            decoration: product.isActive == 0 ? TextDecoration.lineThrough : null,
            color: product.isActive == 0 ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SKU: ${product.sku ?? 'N/A'} | Barcode: ${product.barcode ?? 'N/A'}',
              style: const TextStyle(fontSize: 12),
            ),
            if (product.categoryName != null)
              Text('Category: ${product.categoryName}', style: const TextStyle(fontSize: 12)),
            if (product.expiryDate != null)
              Text(
                'Expiry: ${FormatHelpers.formatDate(product.expiryDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: product.isExpired ? Colors.red : 
                         product.isExpiringSoon ? Colors.orange : Colors.grey,
                ),
              ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              FormatHelpers.formatCurrency(product.retailPrice),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Stock: ${product.currentStock}',
                  style: TextStyle(
                    color: product.isLowStock ? Colors.red : Colors.green,
                    fontSize: 12,
                  ),
                ),
                if (product.isActive == 0)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.block, size: 16, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          ).then((_) => _loadProducts());
        },
        isThreeLine: true,
      ),
    );
  }
}