import '../core/utils/date_utils.dart' as date_utils;
import '../core/constants/api_constants.dart';
import 'category_model.dart';

class Brand {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logo;
  final String? website;
  final bool isActive;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  Brand({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logo,
    this.website,
    this.isActive = true,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    final id = json['id']?.toString();
    final name = json['name']?.toString();
    final slug = json['slug']?.toString();
    
    if (id == null || id.isEmpty) {
      throw FormatException('Brand ID cannot be null or empty');
    }
    if (name == null || name.isEmpty) {
      throw FormatException('Brand name cannot be null or empty');
    }
    if (slug == null || slug.isEmpty) {
      throw FormatException('Brand slug cannot be null or empty');
    }
    
    return Brand(
      id: id,
      name: name,
      slug: slug,
      description: json['description']?.toString(),
      logo: json['logo']?.toString(),
      website: json['website']?.toString(),
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'logo': logo,
      'website': website,
      'is_active': isActive,
      'is_featured': isFeatured,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Product {
  final String id;
  final String vendorId;
  final String name;
  final String slug;
  final String? sku;
  final String? barcode;
  final String? categoryId;
  final String? brandId;
  final String productType;
  final String? shortDescription;
  final String description;
  final Map<String, dynamic> specifications;
  final double price;
  final double? comparePrice;
  final double? costPrice;
  final int stockQuantity;
  final int lowStockThreshold;
  final bool manageStock;
  final String stockStatus;
  final double? weight;
  final double? length;
  final double? width;
  final double? height;
  final bool requiresShipping;
  final String? shippingClass;
  final String status;
  final bool isFeatured;
  final bool isDigital;
  final String? metaTitle;
  final String? metaDescription;
  final String? metaKeywords;
  final int viewCount;
  final int salesCount;
  final double averageRating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final List<ProductImage> images;
  final List<ProductVariation> variations;
  final List<ProductReview> reviews;
  final Category? category;
  final Brand? brand;

  Product({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.slug,
    this.sku,
    this.barcode,
    this.categoryId,
    this.brandId,
    this.productType = 'simple',
    this.shortDescription,
    required this.description,
    this.specifications = const {},
    required this.price,
    this.comparePrice,
    this.costPrice,
    this.stockQuantity = 0,
    this.lowStockThreshold = 5,
    this.manageStock = true,
    this.stockStatus = 'in_stock',
    this.weight,
    this.length,
    this.width,
    this.height,
    this.requiresShipping = true,
    this.shippingClass,
    this.status = 'draft',
    this.isFeatured = false,
    this.isDigital = false,
    this.metaTitle,
    this.metaDescription,
    this.metaKeywords,
    this.viewCount = 0,
    this.salesCount = 0,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.images = const [],
    this.variations = const [],
    this.reviews = const [],
    this.category,
    this.brand,
  });

  bool get isInStock => !manageStock || stockQuantity > 0;
  bool get isLowStock => manageStock && stockQuantity <= lowStockThreshold;
  
  double get discountPercentage {
    if (comparePrice != null && comparePrice! > price) {
      return ((comparePrice! - price) / comparePrice!) * 100;
    }
    return 0.0;
  }

  String? get primaryImageUrl {
    final primaryImage = images.where((img) => img.isPrimary).firstOrNull;
    final raw = primaryImage?.image ?? images.firstOrNull?.image;
    if (raw == null || raw.isEmpty) return null;
    // If backend returns relative media path like "/media/...", convert to absolute URL
    final isAbsolute = raw.startsWith('http://') || raw.startsWith('https://');
    if (isAbsolute) return raw;

    // Derive base origin from ApiConstants.baseUrl (strip trailing path like "/api")
    try {
      final uri = Uri.parse(ApiConstants.baseUrl);
      final origin = uri.hasPort
          ? '${uri.scheme}://${uri.host}:${uri.port}'
          : '${uri.scheme}://${uri.host}';
      if (raw.startsWith('/')) {
        return '$origin$raw';
      }
      return '$origin/$raw';
    } catch (_) {
      // Fallback to raw if parsing fails
      return raw;
    }
  }

  // Legacy properties for backward compatibility
  List<String> get imageUrls {
    return images.map((img) => img.image).toList();
  }

  double? get originalPrice => comparePrice;
  
  double get rating => averageRating;

  factory Product.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    final id = json['id']?.toString();
    final vendorId = json['vendor']?.toString();
    final name = json['name']?.toString();
    final slug = json['slug']?.toString();
    final description = json['description']?.toString();
    
    if (id == null || id.isEmpty) {
      throw FormatException('Product ID cannot be null or empty');
    }
    if (vendorId == null || vendorId.isEmpty) {
      throw FormatException('Product vendor ID cannot be null or empty');
    }
    if (name == null || name.isEmpty) {
      throw FormatException('Product name cannot be null or empty');
    }
    if (slug == null || slug.isEmpty) {
      throw FormatException('Product slug cannot be null or empty');
    }
    if (description == null || description.isEmpty) {
      throw FormatException('Product description cannot be null or empty');
    }
    
    return Product(
      id: id,
      vendorId: vendorId,
      name: name,
      slug: slug,
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),
      categoryId: json['category']?.toString(),
      brandId: json['brand']?.toString(),
      productType: json['product_type']?.toString() ?? 'simple',
      shortDescription: json['short_description']?.toString(),
      description: description,
      specifications: (json['specifications'] as Map<String, dynamic>?) ?? {},
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      comparePrice: json['compare_price'] != null 
          ? double.tryParse(json['compare_price'].toString()) 
          : null,
      costPrice: json['cost_price'] != null 
          ? double.tryParse(json['cost_price'].toString()) 
          : null,
      stockQuantity: json['stock_quantity'] ?? 0,
      lowStockThreshold: json['low_stock_threshold'] ?? 5,
      manageStock: json['manage_stock'] ?? true,
      stockStatus: json['stock_status']?.toString() ?? 'in_stock',
      weight: json['weight'] != null 
          ? double.tryParse(json['weight'].toString()) 
          : null,
      length: json['length'] != null 
          ? double.tryParse(json['length'].toString()) 
          : null,
      width: json['width'] != null 
          ? double.tryParse(json['width'].toString()) 
          : null,
      height: json['height'] != null 
          ? double.tryParse(json['height'].toString()) 
          : null,
      requiresShipping: json['requires_shipping'] ?? true,
      shippingClass: json['shipping_class']?.toString(),
      status: json['status']?.toString() ?? 'draft',
      isFeatured: json['is_featured'] ?? false,
      isDigital: json['is_digital'] ?? false,
      metaTitle: json['meta_title']?.toString(),
      metaDescription: json['meta_description']?.toString(),
      metaKeywords: json['meta_keywords']?.toString(),
      viewCount: json['view_count'] ?? 0,
      salesCount: json['sales_count'] ?? 0,
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
      publishedAt: json['published_at'] != null 
          ? date_utils.DateUtils.safeParseOptionalDate(json['published_at']) 
          : null,
      images: (json['images'] as List<dynamic>?)
          ?.map((img) => ProductImage.fromJson(img))
          .toList() ?? [],
      variations: (json['variations'] as List<dynamic>?)
          ?.map((variation) => ProductVariation.fromJson(variation))
          .toList() ?? [],
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((review) => ProductReview.fromJson(review))
          .toList() ?? [],
      category: json['category_detail'] != null 
          ? Category.fromJson(json['category_detail']) 
          : null,
      brand: json['brand_detail'] != null 
          ? Brand.fromJson(json['brand_detail']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor': vendorId,
      'name': name,
      'slug': slug,
      'sku': sku,
      'barcode': barcode,
      'category': categoryId,
      'brand': brandId,
      'product_type': productType,
      'short_description': shortDescription,
      'description': description,
      'specifications': specifications,
      'price': price,
      'compare_price': comparePrice,
      'cost_price': costPrice,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'manage_stock': manageStock,
      'stock_status': stockStatus,
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
      'requires_shipping': requiresShipping,
      'shipping_class': shippingClass,
      'status': status,
      'is_featured': isFeatured,
      'is_digital': isDigital,
      'meta_title': metaTitle,
      'meta_description': metaDescription,
      'meta_keywords': metaKeywords,
      'view_count': viewCount,
      'sales_count': salesCount,
      'average_rating': averageRating,
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'published_at': publishedAt?.toIso8601String(),
    };
  }

  // Helper getters
  bool get isActive => status == 'active' || status == 'published';
  int get stock => stockQuantity;

  // Factory method for empty product
  factory Product.empty() {
    return Product(
      id: '',
      vendorId: '',
      name: '',
      slug: '',
      description: '',
      price: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class ProductImage {
  final String id;
  final String productId;
  final String image;
  final String? altText;
  final bool isPrimary;
  final int sortOrder;
  final DateTime createdAt;

  ProductImage({
    required this.id,
    required this.productId,
    required this.image,
    this.altText,
    this.isPrimary = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id']?.toString() ?? '',
      productId: json['product']?.toString() ?? '',
      image: json['image'] ?? '',
      altText: json['alt_text'],
      isPrimary: json['is_primary'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': productId,
      'image': image,
      'alt_text': altText,
      'is_primary': isPrimary,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ProductVariation {
  final String id;
  final String productId;
  final String? sku;
  final double price;
  final double? comparePrice;
  final double? costPrice;
  final int stockQuantity;
  final double? weight;
  final double? length;
  final double? width;
  final double? height;
  final bool isActive;
  final bool isDefault;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> attributes;

  ProductVariation({
    required this.id,
    required this.productId,
    this.sku,
    required this.price,
    this.comparePrice,
    this.costPrice,
    this.stockQuantity = 0,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.isActive = true,
    this.isDefault = false,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    this.attributes = const {},
  });

  bool get isInStock => stockQuantity > 0;

  String get displayName {
    final attributeEntries = attributes.entries.where((entry) => entry.value != null);
    if (attributeEntries.isNotEmpty) {
      return attributeEntries.map((entry) => '${entry.key}: ${entry.value}').join(', ');
    }
    return sku ?? 'Variation ${id.substring(0, 8)}';
  }

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    return ProductVariation(
      id: json['id']?.toString() ?? '',
      productId: json['product']?.toString() ?? '',
      sku: json['sku'],
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      comparePrice: json['compare_price'] != null 
          ? double.tryParse(json['compare_price'].toString()) 
          : null,
      costPrice: json['cost_price'] != null 
          ? double.tryParse(json['cost_price'].toString()) 
          : null,
      stockQuantity: json['stock_quantity'] ?? 0,
      weight: json['weight'] != null 
          ? double.tryParse(json['weight'].toString()) 
          : null,
      length: json['length'] != null 
          ? double.tryParse(json['length'].toString()) 
          : null,
      width: json['width'] != null 
          ? double.tryParse(json['width'].toString()) 
          : null,
      height: json['height'] != null 
          ? double.tryParse(json['height'].toString()) 
          : null,
      isActive: json['is_active'] ?? true,
      isDefault: json['is_default'] ?? false,
      image: json['image'],
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
      attributes: json['attributes'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': productId,
      'sku': sku,
      'price': price,
      'compare_price': comparePrice,
      'cost_price': costPrice,
      'stock_quantity': stockQuantity,
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
      'is_active': isActive,
      'is_default': isDefault,
      'image': image,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'attributes': attributes,
    };
  }
}

class ProductReview {
  final String id;
  final String productId;
  final String userId;
  final int rating;
  final String? title;
  final String comment;
  final int helpfulCount;
  final int notHelpfulCount;
  final bool isVerifiedPurchase;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userFirstName;
  final String? userLastName;

  ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    this.title,
    required this.comment,
    this.helpfulCount = 0,
    this.notHelpfulCount = 0,
    this.isVerifiedPurchase = false,
    this.isApproved = true,
    required this.createdAt,
    required this.updatedAt,
    this.userFirstName,
    this.userLastName,
  });

  String get userName {
    if (userFirstName?.isNotEmpty == true || userLastName?.isNotEmpty == true) {
      return '${userFirstName ?? ''} ${userLastName ?? ''}'.trim();
    }
    return 'Anonymous';
  }

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id']?.toString() ?? '',
      productId: json['product']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      rating: json['rating'] ?? 5,
      title: json['title'],
      comment: json['comment'] ?? '',
      helpfulCount: json['helpful_count'] ?? 0,
      notHelpfulCount: json['not_helpful_count'] ?? 0,
      isVerifiedPurchase: json['is_verified_purchase'] ?? false,
      isApproved: json['is_approved'] ?? true,
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
      userFirstName: json['user_first_name'],
      userLastName: json['user_last_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': productId,
      'user': userId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'helpful_count': helpfulCount,
      'not_helpful_count': notHelpfulCount,
      'is_verified_purchase': isVerifiedPurchase,
      'is_approved': isApproved,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Wishlist {
  final String id;
  final String userId;
  final String productId;
  final DateTime createdAt;
  final Product? product;

  Wishlist({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
    this.product,
  });

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      id: json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      productId: json['product']?.toString() ?? '',
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      product: json['product_detail'] != null 
          ? Product.fromJson(json['product_detail']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'product': productId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Extension to handle null safety for firstOrNull
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
