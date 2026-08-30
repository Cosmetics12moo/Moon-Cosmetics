# Moon Cosmetics & Beauty Shop POS

A professional Windows Point of Sale system designed specifically for cosmetics and beauty retail shops.

## Features

### Core Features
- **Fast POS Workflow**: Barcode scanning, quick product search, and keyboard shortcuts
- **Inventory Management**: Stock tracking with batch and expiry management
- **Customer Management**: Customer profiles with purchase history and credit tracking
- **Supplier Management**: Supplier profiles with purchase history and balance tracking
- **Purchase Management**: Complete purchase workflow with batch tracking
- **Sales Returns**: Professional sales return processing with stock correction
- **Purchase Returns**: Supplier return processing with stock correction
- **Expense Management**: Track shop expenses with category breakdown
- **Financial Accounts**: Multiple account support (Cash, Bank, Mobile Wallets)
- **Professional Invoices**: A4 and 80mm thermal receipt formats
- **Comprehensive Reports**: Sales, profit, inventory, customer, supplier, financial reports
- **User Roles**: Admin, Manager, Cashier with appropriate permissions
- **Audit Log**: Track all sensitive actions
- **Backup & Restore**: Reliable database backup and restore functionality

### Cosmetics-Specific Features
- **Custom Categories**: Fully flexible category system
- **Batch & Expiry Management**: Track batches with expiry dates
- **FEFO**: First Expire, First Out for sales
- **Expiry Alerts**: Dashboard alerts for expired and expiring products
- **Product Variants**: Support for shades, colors, sizes, and units
- **Brand Management**: Track products by brand

## System Requirements

- Windows 10 or 11 (64-bit)
- Minimum 4GB RAM
- 500MB free disk space
- SQLite (embedded)

## Installation

1. Download the installer from the release page
2. Run `Moon_Cosmetics_POS_Setup.exe`
3. Follow the installation wizard
4. Launch from desktop shortcut or start menu

## Quick Start

1. **Default Login**
   - Username: `admin`
   - Password: `admin123`
   - Change the default password immediately after first login!

2. **Setup Workflow**
   - Go to Settings > Shop Information to configure your shop details
   - Add categories before adding products
   - Add suppliers before making purchases
   - Add products with barcodes for scanning
   - Start making sales

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| F2 | Product Search |
| F4 | Customer Selection |
| F6 | Discount |
| F8 | Payment |
| F9 | Hold Sale |
| F10 | Complete Sale |
| ESC | Clear/Cancel |

## Database

The system uses SQLite as the embedded database. The database file is located at: