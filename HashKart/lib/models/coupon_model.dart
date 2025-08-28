class Coupon {
  final String id;
  final String code;
  final String description;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final double? minimumPurchase;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int? usageLimit;
  final int usageCount;
  final bool isActive;
  final List<String>? applicableCategories;
  final List<String>? applicableProducts;
  final List<String>? applicableVendors;

  Coupon({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minimumPurchase,
    this.validFrom,
    this.validUntil,
    this.usageLimit,
    required this.usageCount,
    required this.isActive,
    this.applicableCategories,
    this.applicableProducts,
    this.applicableVendors,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discount_type'] ?? 'fixed',
      discountValue: (json['discount_value'] ?? 0).toDouble(),
      minimumPurchase: json['minimum_purchase']?.toDouble(),
      validFrom: json['valid_from'] != null 
          ? DateTime.tryParse(json['valid_from']) 
          : null,
      validUntil: json['valid_until'] != null 
          ? DateTime.tryParse(json['valid_until']) 
          : null,
      usageLimit: json['usage_limit'],
      usageCount: json['usage_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      applicableCategories: json['applicable_categories'] != null
          ? List<String>.from(json['applicable_categories'])
          : null,
      applicableProducts: json['applicable_products'] != null
          ? List<String>.from(json['applicable_products'])
          : null,
      applicableVendors: json['applicable_vendors'] != null
          ? List<String>.from(json['applicable_vendors'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'minimum_purchase': minimumPurchase,
      'valid_from': validFrom?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'usage_limit': usageLimit,
      'usage_count': usageCount,
      'is_active': isActive,
      'applicable_categories': applicableCategories,
      'applicable_products': applicableProducts,
      'applicable_vendors': applicableVendors,
    };
  }

  bool get isValid {
    final now = DateTime.now();
    
    if (!isActive) return false;
    
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    
    if (usageLimit != null && usageCount >= usageLimit!) return false;
    
    return true;
  }

  double calculateDiscount(double amount) {
    if (!isValid) return 0;
    
    if (minimumPurchase != null && amount < minimumPurchase!) return 0;
    
    if (discountType == 'percentage') {
      return amount * (discountValue / 100);
    } else {
      return discountValue > amount ? amount : discountValue;
    }
  }
}
