import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/database_service.dart';
import '../../utils/format_helpers.dart';
import '../../widgets/dashboard/dashboard_card.dart';
import '../../widgets/dashboard/sales_chart.dart';
import '../../widgets/dashboard/expiry_alert.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // Load dashboard data
      final today = DateTime.now().toIso8601String().split('T').first;
      
      // Today's sales
      final todaySales = await _db.getTodaySales();
      // Today's expenses
      final todayExpenses = await _db.getTodayExpenses();
      // Customer receivables
      final receivables = await _db.getTotalReceivables();
      // Supplier payables
      final payables = await _db.getTotalPayables();
      // Total stock value
      final stockValue = await _db.getTotalStockValue();
      // Low stock items
      final lowStock = await _db.getLowStockProducts();
      // Expired products
      final expired = await _db.getExpiredProducts();
      // Expiring soon
      final expiringSoon = await _db.getExpiringProducts(90);
      
      setState(() {
        _dashboardData = {
          'todaySales': todaySales,
          'todayExpenses': todayExpenses,
          'receivables': receivables,
          'payables': payables,
          'stockValue': stockValue,
          'lowStockCount': lowStock.length,
          'expiredCount': expired.length,
          'expiringCount': expiringSoon.length,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: DashboardCard(
                          title: "Today's Sales",
                          value: FormatHelpers.formatCurrency(
                            _dashboardData['todaySales'] ?? 0,
                          ),
                          icon: Icons.today,
                          color: AppTheme.primaryColor,
                          onTap: () {
                            // Navigate to sales report
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DashboardCard(
                          title: "Today's Expenses",
                          value: FormatHelpers.formatCurrency(
                            _dashboardData['todayExpenses'] ?? 0,
                          ),
                          icon: Icons.money_off,
                          color: Colors.orange,
                          onTap: () {
                            // Navigate to expenses
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // More Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: DashboardCard(
                          title: 'Customer Receivables',
                          value: FormatHelpers.formatCurrency(
                            _dashboardData['receivables'] ?? 0,
                          ),
                          icon: Icons.people,
                          color: Colors.blue,
                          onTap: () {
                            // Navigate to customers
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DashboardCard(
                          title: 'Supplier Payables',
                          value: FormatHelpers.formatCurrency(
                            _dashboardData['payables'] ?? 0,
                          ),
                          icon: Icons.business,
                          color: Colors.purple,
                          onTap: () {
                            // Navigate to suppliers
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Stock Value
                  Row(
                    children: [
                      Expanded(
                        child: DashboardCard(
                          title: 'Total Stock Value',
                          value: FormatHelpers.formatCurrency(
                            _dashboardData['stockValue'] ?? 0,
                          ),
                          icon: Icons.inventory,
                          color: Colors.teal,
                          onTap: () {
                            // Navigate to inventory
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DashboardCard(
                          title: 'Low Stock Items',
                          value: '${_dashboardData['lowStockCount'] ?? 0}',
                          icon: Icons.warning,
                          color: Colors.orange,
                          onTap: () {
                            // Navigate to low stock products
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Expiry Alerts
                  const Text(
                    'Expiry Alerts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if ((_dashboardData['expiredCount'] ?? 0) > 0)
                    ExpiryAlertCard(
                      title: 'Expired Products',
                      count: _dashboardData['expiredCount'] ?? 0,
                      icon: Icons.warning_amber,
                      color: Colors.red,
                      onTap: () {
                        // Navigate to expired products
                      },
                    ),
                  if ((_dashboardData['expiringCount'] ?? 0) > 0)
                    ExpiryAlertCard(
                      title: 'Expiring Within 90 Days',
                      count: _dashboardData['expiringCount'] ?? 0,
                      icon: Icons.access_time,
                      color: Colors.orange,
                      onTap: () {
                        // Navigate to expiring products
                      },
                    ),
                  if ((_dashboardData['expiredCount'] ?? 0) == 0 && 
                      (_dashboardData['expiringCount'] ?? 0) == 0)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text('No expiry alerts. All products are in good standing.'),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Sales Chart
                  const Text(
                    'Sales Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const SalesChart(),
                ],
              ),
            ),
    );
  }
}