import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../models/account.dart';
import '../../services/database_service.dart';
import '../../utils/format_helpers.dart';

class PaymentDialog extends StatefulWidget {
  final double total;
  final Customer? customer;
  final Function(Map<String, dynamic>) onPaymentComplete;

  const PaymentDialog({
    super.key,
    required this.total,
    this.customer,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _paidController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _paymentMethod = 'cash';
  int? _selectedAccountId;
  List<Account> _accounts = [];
  
  double get _paidAmount => double.tryParse(_paidController.text) ?? 0;
  double get _dueAmount => widget.total - _paidAmount;

  @override
  void initState() {
    super.initState();
    _paidController.text = widget.total.toStringAsFixed(2);
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    // Load accounts from database
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Customer Info
            if (widget.customer != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Customer: ${widget.customer!.name}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text('Phone: ${widget.customer!.phone ?? 'N/A'}'),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                Text(
                  FormatHelpers.formatCurrency(widget.total),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            
            const Divider(height: 32),
            
            // Paid Amount
            Row(
              children: [
                const Expanded(
                  child: Text('Amount Paid', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _paidController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      prefixText: 'Rs. ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Due Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Due Amount', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  FormatHelpers.formatCurrency(_dueAmount),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _dueAmount > 0 ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Payment Method
            Row(
              children: [
                const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _paymentMethod,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                      DropdownMenuItem(value: 'jazzcash', child: Text('JazzCash')),
                      DropdownMenuItem(value: 'easypaisa', child: Text('Easypaisa')),
                      DropdownMenuItem(value: 'credit', child: Text('Credit')),
                      DropdownMenuItem(value: 'mixed', child: Text('Mixed')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Notes (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_paidAmount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid amount'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      widget.onPaymentComplete({
                        'paid': _paidAmount,
                        'due': _dueAmount,
                        'method': _paymentMethod,
                        'notes': _notesController.text,
                        'customer': widget.customer,
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('Complete Payment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}