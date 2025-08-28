import '../core/utils/date_utils.dart' as date_utils;

class Vendor {
  final String id;
  final String userId;
  final String businessName;
  final String businessType;
  final String? businessRegistrationNumber;
  final String? taxId;
  final String? gstNumber;
  final String businessEmail;
  final String businessPhone;
  final String? website;
  final String? description;
  final String? shortDescription;
  final String? logo;
  final String? banner;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String verificationStatus;
  final String? verificationNotes;
  final DateTime? verifiedAt;
  final bool isActive;
  final bool isFeatured;
  final double commissionRate;
  final double averageRating;
  final int totalReviews;
  final double totalSales;
  final int totalOrders;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vendor({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.businessType,
    this.businessRegistrationNumber,
    this.taxId,
    this.gstNumber,
    required this.businessEmail,
    required this.businessPhone,
    this.website,
    this.description,
    this.shortDescription,
    this.logo,
    this.banner,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = 'India',
    this.verificationStatus = 'pending',
    this.verificationNotes,
    this.verifiedAt,
    this.isActive = true,
    this.isFeatured = false,
    this.commissionRate = 10.0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.totalSales = 0.0,
    this.totalOrders = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isVerified => verificationStatus == 'verified';

  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2?.isNotEmpty == true) addressLine2,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      businessName: json['business_name'] ?? '',
      businessType: json['business_type'] ?? '',
      businessRegistrationNumber: json['business_registration_number'],
      taxId: json['tax_id'],
      gstNumber: json['gst_number'],
      businessEmail: json['business_email'] ?? '',
      businessPhone: json['business_phone'] ?? '',
      website: json['website'],
      description: json['description'],
      shortDescription: json['short_description'],
      logo: json['logo'],
      banner: json['banner'],
      addressLine1: json['address_line_1'] ?? '',
      addressLine2: json['address_line_2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postal_code'] ?? '',
      country: json['country'] ?? 'India',
      verificationStatus: json['verification_status'] ?? 'pending',
      verificationNotes: json['verification_notes'],
      verifiedAt: json['verified_at'] != null 
          ? date_utils.DateUtils.safeParseOptionalDate(json['verified_at']) 
          : null,
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      commissionRate: double.tryParse(json['commission_rate']?.toString() ?? '10') ?? 10.0,
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
      totalReviews: json['total_reviews'] ?? 0,
      totalSales: double.tryParse(json['total_sales']?.toString() ?? '0') ?? 0.0,
      totalOrders: json['total_orders'] ?? 0,
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'business_name': businessName,
      'business_type': businessType,
      'business_registration_number': businessRegistrationNumber,
      'tax_id': taxId,
      'gst_number': gstNumber,
      'business_email': businessEmail,
      'business_phone': businessPhone,
      'website': website,
      'description': description,
      'short_description': shortDescription,
      'logo': logo,
      'banner': banner,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'verification_status': verificationStatus,
      'verification_notes': verificationNotes,
      'verified_at': verifiedAt?.toIso8601String(),
      'is_active': isActive,
      'is_featured': isFeatured,
      'commission_rate': commissionRate,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'total_sales': totalSales,
      'total_orders': totalOrders,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class VendorDocument {
  final String id;
  final String vendorId;
  final String documentType;
  final String documentName;
  final String documentFile;
  final String verificationStatus;
  final String? verificationNotes;
  final String? verifiedById;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  VendorDocument({
    required this.id,
    required this.vendorId,
    required this.documentType,
    required this.documentName,
    required this.documentFile,
    this.verificationStatus = 'pending',
    this.verificationNotes,
    this.verifiedById,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VendorDocument.fromJson(Map<String, dynamic> json) {
    return VendorDocument(
      id: json['id']?.toString() ?? '',
      vendorId: json['vendor']?.toString() ?? '',
      documentType: json['document_type'] ?? '',
      documentName: json['document_name'] ?? '',
      documentFile: json['document_file'] ?? '',
      verificationStatus: json['verification_status'] ?? 'pending',
      verificationNotes: json['verification_notes'],
      verifiedById: json['verified_by']?.toString(),
      verifiedAt: json['verified_at'] != null 
          ? date_utils.DateUtils.safeParseOptionalDate(json['verified_at']) 
          : null,
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor': vendorId,
      'document_type': documentType,
      'document_name': documentName,
      'document_file': documentFile,
      'verification_status': verificationStatus,
      'verification_notes': verificationNotes,
      'verified_by': verifiedById,
      'verified_at': verifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class VendorBankAccount {
  final String id;
  final String vendorId;
  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String branchName;
  final String accountType;
  final bool isVerified;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;

  VendorBankAccount({
    required this.id,
    required this.vendorId,
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.branchName,
    this.accountType = 'savings',
    this.isVerified = false,
    this.isPrimary = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VendorBankAccount.fromJson(Map<String, dynamic> json) {
    return VendorBankAccount(
      id: json['id']?.toString() ?? '',
      vendorId: json['vendor']?.toString() ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      bankName: json['bank_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      branchName: json['branch_name'] ?? '',
      accountType: json['account_type'] ?? 'savings',
      isVerified: json['is_verified'] ?? false,
      isPrimary: json['is_primary'] ?? false,
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor': vendorId,
      'account_holder_name': accountHolderName,
      'bank_name': bankName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'branch_name': branchName,
      'account_type': accountType,
      'is_verified': isVerified,
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class VendorSetting {
  final String vendorId;
  final String? storeName;
  final String? storeSlug;
  final String? storeDescription;
  final String? storePolicies;
  final Map<String, dynamic> businessHours;
  final double freeShippingThreshold;
  final double shippingCharge;
  final int returnPolicyDays;
  final bool acceptsReturns;
  final bool orderNotifications;
  final bool inventoryAlerts;
  final bool promotionalEmails;
  final String? metaTitle;
  final String? metaDescription;
  final String? metaKeywords;
  final DateTime createdAt;
  final DateTime updatedAt;

  VendorSetting({
    required this.vendorId,
    this.storeName,
    this.storeSlug,
    this.storeDescription,
    this.storePolicies,
    this.businessHours = const {},
    this.freeShippingThreshold = 0.0,
    this.shippingCharge = 0.0,
    this.returnPolicyDays = 7,
    this.acceptsReturns = true,
    this.orderNotifications = true,
    this.inventoryAlerts = true,
    this.promotionalEmails = true,
    this.metaTitle,
    this.metaDescription,
    this.metaKeywords,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VendorSetting.fromJson(Map<String, dynamic> json) {
    return VendorSetting(
      vendorId: json['vendor']?.toString() ?? '',
      storeName: json['store_name'],
      storeSlug: json['store_slug'],
      storeDescription: json['store_description'],
      storePolicies: json['store_policies'],
      businessHours: json['business_hours'] ?? {},
      freeShippingThreshold: double.tryParse(json['free_shipping_threshold']?.toString() ?? '0') ?? 0.0,
      shippingCharge: double.tryParse(json['shipping_charge']?.toString() ?? '0') ?? 0.0,
      returnPolicyDays: json['return_policy_days'] ?? 7,
      acceptsReturns: json['accepts_returns'] ?? true,
      orderNotifications: json['order_notifications'] ?? true,
      inventoryAlerts: json['inventory_alerts'] ?? true,
      promotionalEmails: json['promotional_emails'] ?? true,
      metaTitle: json['meta_title'],
      metaDescription: json['meta_description'],
      metaKeywords: json['meta_keywords'],
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor': vendorId,
      'store_name': storeName,
      'store_slug': storeSlug,
      'store_description': storeDescription,
      'store_policies': storePolicies,
      'business_hours': businessHours,
      'free_shipping_threshold': freeShippingThreshold,
      'shipping_charge': shippingCharge,
      'return_policy_days': returnPolicyDays,
      'accepts_returns': acceptsReturns,
      'order_notifications': orderNotifications,
      'inventory_alerts': inventoryAlerts,
      'promotional_emails': promotionalEmails,
      'meta_title': metaTitle,
      'meta_description': metaDescription,
      'meta_keywords': metaKeywords,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
