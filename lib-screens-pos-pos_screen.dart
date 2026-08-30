import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../services/database_service.dart';
import '../../models/product.dart';
import '../../models/customer.dart';
import '../../widgets/pos/product_search_dialog.dart';
import '../../widgets/pos/cart_item_widget.dart';
import '../../widgets/pos/payment_dialog.dart';
import '../../widgets/pos/customer_select_dialog.dart';
import '../../utils/keyboard_shortcuts.dart';
import '../../utils/format_helpers.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> with KeyboardShortcutsMixin {
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();
  final DatabaseService _db = DatabaseService();
  
  Customer? selectedCustomer;
  String? discountType = 'none';
  double discountValue = 0;
  double extraCharges = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    if (barcode.isEmpty) return;
    
    final product = await _db.getProductByBarcode(barcode);
    if (product != null) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.addItem(product);
      _barcodeController.clear();
      _barcodeFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} added to cart')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product not found'), backgroundColor: Colors.red),
      );
      _barcodeController.clear();
    }
  }

  void _showProductSearch() {
    showDialog(
      context: context,
      builder: (context) => const ProductSearchDialog(),
    ).then((product) {
      if (product != null) {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        cartProvider.addItem(product);
      }
    });
  }

  void _showCustomerSelect() {
    showDialog(
      context: context,
      builder: (context) => const CustomerSelectDialog(),
    ).then((customer) {
      if (customer != null) {
        setState(() {
          selectedCustomer = customer;
        });
      }
    });
  }

  void _showPaymentDialog() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        total: cartProvider.total,
        customer: selectedCustomer,
        onPaymentComplete: _completeSale,
      ),
    );
  }

  void _completeSale(Map<String, dynamic> paymentInfo) {
    // Implement sale completion with database transaction
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sale completed successfully!')),
    );
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.clearCart();
    setState(() {
      selectedCustomer = null;
      discountType = 'none';
      discountValue = 0;
      extraCharges = 0;
    });
    _barcodeFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        actions: [
          if (selectedCustomer != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 4),
                  Text(selectedCustomer!.name),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => setState(() => selectedCustomer = null),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Select Customer (F4)',
            onPressed: _showCustomerSelect,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Product (F2)',
            onPressed: _showProductSearch,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left: Product Search and Cart
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Barcode Scanner Input
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _barcodeController,
                    focusNode: _barcodeFocusNode,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                      hintText: 'Scan or enter barcode...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _showProductSearch,
                      ),
                    ),
                    onSubmitted: _handleBarcodeScan,
                  ),
                ),
                
                // Category Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildCategoryFilter(),
                ),
                
                // Cart Items
                Expanded(
                  child: Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      if (cartProvider.items.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Cart is empty',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              Text(
                                'Scan barcode or search product',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: cartProvider.items.length,
                        itemBuilder: (context, index) {
                          final item = cartProvider.items[index];
                          return CartItemWidget(
                            item: item,
                            onQuantityChanged: (newQuantity) {
                              cartProvider.updateQuantity(item.product.id!, newQuantity);
                            },
                            onRemove: () {
                              cartProvider.removeItem(index);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Right: Cart Summary and Checkout
          Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(left: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                // Summary Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          return Text(
                            '${cartProvider.items.length} items',
                            style: const TextStyle(color: Colors.grey),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Discount and Extra Charges
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDiscountSection(),
                      const SizedBox(height: 8),
                      _buildExtraChargesSection(),
                    ],
                  ),
                ),
                
                // Totals
                Expanded(
                  child: Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildTotalRow('Subtotal', cartProvider.subtotal),
                            if (discountType != 'none' && discountValue > 0)
                              _buildTotalRow(
                                'Discount',
                                -cartProvider.discountAmount,
                                color: Colors.green,
                              ),
                            if (extraCharges > 0)
                              _buildTotalRow('Extra Charges', extraCharges),
                            const Divider(height: 20),
                            _buildTotalRow(
                              'Total',
                              cartProvider.total,
                              isTotal: true,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      final cartProvider = Provider.of<CartProvider>(
                                        context,
                                        listen: false,
                                      );
                                      cartProvider.clearCart();
                                      setState(() {
                                        discountType = 'none';
                                        discountValue = 0;
                                        extraCharges = 0;
                                      });
                                    },
                                    icon: const Icon(Icons.clear),
                                    label: const Text('Clear Cart'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      minimumSize: const Size(0, 48),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: _showPaymentDialog,
                                    icon: const Icon(Icons.payment),
                                    label: const Text('Checkout (F8)'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      minimumSize: const Size(0, 48),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.save, size: 18),
                                    label: const Text('Hold Sale (F9)'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip('All', true),
          _buildCategoryChip('Makeup', false),
          _buildCategoryChip('Skincare', false),
          _buildCategoryChip('Hair Care', false),
          _buildCategoryChip('Fragrance', false),
          _buildCategoryChip('Personal Care', false),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (value) {},
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryColor.withOpacity(0.1),
        checkmarkColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Row(
      children: [
        const Text('Discount:'),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: discountType,
          items: const [
            DropdownMenuItem(value: 'none', child: Text('None')),
            DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
            DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
          ],
          onChanged: (value) {
            setState(() {
              discountType = value;
              if (value == 'none') discountValue = 0;
            });
          },
        ),
        if (discountType != 'none')
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: discountType == 'percentage' ? '%' : 'Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onChanged: (value) {
                setState(() {
                  discountValue = double.tryParse(value) ?? 0;
                  if (discountType == 'percentage' && discountValue > 100) {
                    discountValue = 100;
                  }
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildExtraChargesSection() {
    return Row(
      children: [
        const Text('Extra Charges:'),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Amount',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            onChanged: (value) {
              setState(() {
                extraCharges = double.tryParse(value) ?? 0;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            FormatHelpers.formatCurrency(amount),
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isTotal ? AppTheme.primaryColor : null),
            ),
          ),
        ],
      ),
    );
  }
}

mixin KeyboardShortcutsMixin on State<PosScreen> {
  // Keyboard shortcut handling
}