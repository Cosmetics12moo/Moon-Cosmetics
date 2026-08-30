import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/database_service.dart';
import '../../widgets/settings/shop_info_form.dart';
import '../../widgets/settings/printer_settings.dart';
import '../../widgets/settings/backup_settings.dart';
import '../../widgets/settings/user_management.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _db = DatabaseService();
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                _buildSidebarItem('Shop Information', 0, Icons.store),
                _buildSidebarItem('Users', 1, Icons.people),
                _buildSidebarItem('Printer Settings', 2, Icons.print),
                _buildSidebarItem('Backup & Restore', 3, Icons.backup),
                _buildSidebarItem('About', 4, Icons.info),
                const Spacer(),
                _buildSidebarItem('Logout', 5, Icons.logout, danger: true),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String title, int index, IconData icon, {bool danger = false}) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
          border: Border(
            left: isSelected
                ? BorderSide(color: AppTheme.primaryColor, width: 4)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: danger ? Colors.red : (isSelected ? AppTheme.primaryColor : Colors.grey),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: danger ? Colors.red : (isSelected ? AppTheme.primaryColor : null),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return const ShopInfoForm();
      case 1:
        return const UserManagement();
      case 2:
        return const PrinterSettings();
      case 3:
        return const BackupSettings();
      case 4:
        return _buildAboutSection();
      case 5:
        return _buildLogoutConfirmation();
      default:
        return const SizedBox();
    }
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About Moon Cosmetics POS',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Moon Cosmetics & Beauty Shop POS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Version: 1.0.0', style: TextStyle(color: Colors.grey.shade600)),
                Text('Platform: Windows Desktop', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                const Text(
                  'A professional Point of Sale system designed specifically for '
                  'Moon Cosmetics & Beauty Shop.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text('Features:'),
                const SizedBox(height: 4),
                const Text('• Fast barcode-based POS workflow'),
                const Text('• Comprehensive inventory management'),
                const Text('• Batch and expiry tracking'),
                const Text('• Customer and supplier management'),
                const Text('• Financial reporting and analysis'),
                const Text('• Professional invoice printing'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutConfirmation() {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Logout',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Are you sure you want to logout?'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(120, 48),
                    ),
                    child: const Text('Logout'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _selectedTab = 0);
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}