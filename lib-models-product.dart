class Product {
  final int? id;
  final String name;
  final String? brand;
  final String? sku;
  final String? barcode;
  final int? categoryId;
  final int? subCategoryId;
  final String? variant;
  final String? shadeColor;
  final String? size;
  final String? unit;
  final double purchasePrice;
  final double retailPrice;
  final double wholesalePrice;
  final int minimumStock;
  final int currentStock;
  final String? batchNumber;
  final DateTime? manufacturingDate;
  final DateTime? expiryDate;
  final int? supplierId;
  final String? imagePath;
  final String? description;
  final int isActive;
  final int isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? createdBy;
  final int? updatedBy;

  // Optional related data
  String? categoryName;
  String? supplierName;

  Product({
    this.id,
    required this.name,
    this.brand,
    this.sku,
    this.barcode,
    this.categoryId,
    this.subCategoryId,
    this.variant,
    this.shadeColor,
    this.size,
    this.unit,
    this.purchasePrice = 0,
    this.retailPrice = 0,
    this.wholesalePrice = 0,
    this.minimumStock = 0,
    this.currentStock = 0,
    this.batchNumber,
    this.manufacturingDate,
    this.expiryDate,
    this.supplierId,
    this.imagePath,
    this.description,
    this.isActive = 1,
    this.isDeleted = 0,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.categoryName,
    this.supplierName,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      brand: map['brand'],
      sku: map['sku'],
      barcode: map['barcode'],
      categoryId: map['category_id'],
      subCategoryId: map['sub_category_id'],
      variant: map['variant'],
      shadeColor: map['shade_color'],
      size: map['size'],
      unit: map['unit'],
      purchasePrice: (map['purchase_price'] ?? 0).toDouble(),
      retailPrice: (map['retail_price'] ?? 0).toDouble(),
      wholesalePrice: (map['wholesale_price'] ?? 0).toDouble(),
      minimumStock: map['minimum_stock'] ?? 0,
      currentStock: map['current_stock'] ?? 0,
      batchNumber: map['batch_number'],
      manufacturingDate: map['manufacturing_date'] != null
          ? DateTime.parse(map['manufacturing_date'])
          : null,
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'])
          : null,
      supplierId: map['supplier_id'],
      imagePath: map['image_path'],
      description: map['description'],
      isActive: map['is_active'] ?? 1,
      isDeleted: map['is_deleted'] ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      createdBy: map['created_by'],
      updatedBy: map['updated_by'],
      categoryName: map['category_name'],
      supplierName: map['supplier_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'sku': sku,
      'barcode': barcode,
      'category_id': categoryId,
      'sub_category_id': subCategoryId,
      'variant': variant,
      'shade_color': shadeColor,
      'size': size,
      'unit': unit,
      'purchase_price': purchasePrice,
      'retail_price': retailPrice,
      'wholesale_price': wholesalePrice,
      'minimum_stock': minimumStock,
      'current_stock': currentStock,
      'batch_number': batchNumber,
      'manufacturing_date': manufacturingDate?.toIso8601String().split('T').first,
      'expiry_date': expiryDate?.toIso8601String().split('T').first,
      'supplier_id': supplierId,
      'image_path': imagePath,
      'description': description,
      'is_active': isActive,
      'is_deleted': isDeleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? brand,
    String? sku,
    String? barcode,
    int? categoryId,
    int? subCategoryId,
    String? variant,
    String? shadeColor,
    String? size,
    String? unit,
    double? purchasePrice,
    double? retailPrice,
    double? wholesalePrice,
    int? minimumStock,
    int? currentStock,
    String? batchNumber,
    DateTime? manufacturingDate,
    DateTime? expiryDate,
    int? supplierId,
    String? imagePath,
    String? description,
    int? isActive,
    int? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
    int? updatedBy,
    String? categoryName,
    String? supplierName,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      variant: variant ?? this.variant,
      shadeColor: shadeColor ?? this.shadeColor,
      size: size ?? this.size,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      minimumStock: minimumStock ?? this.minimumStock,
      currentStock: currentStock ?? this.currentStock,
      batchNumber: batchNumber ?? this.batchNumber,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      expiryDate: expiryDate ?? this.expiryDate,
      supplierId: supplierId ?? this.supplierId,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      categoryName: categoryName ?? this.categoryName,
      supplierName: supplierName ?? this.supplierName,
    );
  }

  bool get isLowStock => currentStock <= minimumStock;
  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = DateTime.now().difference(expiryDate!).inDays.abs();
    return daysUntilExpiry <= 90;
  }
}