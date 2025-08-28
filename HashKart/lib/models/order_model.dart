import 'product_model.dart';
import '../core/utils/date_utils.dart' as date_utils;

// Add missing ProductVariation class
class ProductVariation {
  final String id;
  final String productId;
  final String? name;
  final String? sku;
  final double? price;
  final int? stockQuantity;
  final Map<String, dynamic> attributes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductVariation({
    required this.id,
    required this.productId,
    this.name,
    this.sku,
    this.price,
    this.stockQuantity,
    this.attributes = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    return ProductVariation(
      id: json['id']?.toString() ?? '',
      productId: json['product']?.toString() ?? '',
      name: json['name']?.toString(),
      sku: json['sku']?.toString(),
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      stockQuantity: json['stock_quantity'],
      attributes: json['attributes'] ?? {},
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': productId,
      'name': name,
      'sku': sku,
      'price': price,
      'stock_quantity': stockQuantity,
      'attributes': attributes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ShoppingCart {
  final String id;
  final String? userId;
  final String? sessionKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CartItem> items;

  ShoppingCart({
    required this.id,
    this.userId,
    this.sessionKey,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  int get totalItems {
    return items.fold(0, (total, item) => total + item.quantity);
  }

  double get subtotal {
    return items.fold(0.0, (total, item) => total + item.totalPrice);
  }

  double get totalWeight {
    return items.fold(0.0, (total, item) {
      final weight = item.product?.weight ?? 0.0;
      return total + (weight * item.quantity);
    });
  }

  factory ShoppingCart.fromJson(Map<String, dynamic> json) {
    return ShoppingCart(
      id: json['id']?.toString() ?? '',
      userId: json['user']?.toString(),
      sessionKey: json['session_key'],
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => CartItem.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'session_key': sessionKey,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class CartItem {
  final String id;
  final String cartId;
  final String productId;
  final String? variationId;
  final int quantity;
  final double unitPrice;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Product? product;
  final ProductVariation? variation;

  CartItem({
    required this.id,
    required this.cartId,
    required this.productId,
    this.variationId,
    required this.quantity,
    required this.unitPrice,
    required this.createdAt,
    required this.updatedAt,
    this.product,
    this.variation,
  });

  double get totalPrice => unitPrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      cartId: json['cart']?.toString() ?? '',
      productId: json['product']?.toString() ?? '',
      variationId: json['variation']?.toString(),
      quantity: json['quantity'] ?? 1,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
      product: json['product_detail'] != null 
          ? Product.fromJson(json['product_detail']) 
          : null,
      variation: json['variation_detail'] != null 
          ? ProductVariation.fromJson(json['variation_detail']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cart': cartId,
      'product': productId,
      'variation': variationId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String userId;
  final String status;
  final String paymentStatus;
  final String customerEmail;
  final String? customerPhone;
  final String customerFirstName;
  final String customerLastName;
  
  // Shipping address
  final String shippingAddressLine1;
  final String? shippingAddressLine2;
  final String shippingCity;
  final String shippingState;
  final String shippingPostalCode;
  final String shippingCountry;
  
  // Billing address
  final String billingAddressLine1;
  final String? billingAddressLine2;
  final String billingCity;
  final String billingState;
  final String billingPostalCode;
  final String billingCountry;
  
  // Order totals
  final double subtotal;
  final double shippingCost;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  
  // Payment and tracking
  final String? paymentMethod;
  final String? paymentTransactionId;
  final String? customerNotes;
  final String? adminNotes;
  final String? trackingNumber;
  final String? carrier;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    this.status = 'pending',
    this.paymentStatus = 'pending',
    required this.customerEmail,
    this.customerPhone,
    required this.customerFirstName,
    required this.customerLastName,
    required this.shippingAddressLine1,
    this.shippingAddressLine2,
    required this.shippingCity,
    required this.shippingState,
    required this.shippingPostalCode,
    required this.shippingCountry,
    required this.billingAddressLine1,
    this.billingAddressLine2,
    required this.billingCity,
    required this.billingState,
    required this.billingPostalCode,
    required this.billingCountry,
    this.subtotal = 0.0,
    this.shippingCost = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.totalAmount = 0.0,
    this.paymentMethod,
    this.paymentTransactionId,
    this.customerNotes,
    this.adminNotes,
    this.trackingNumber,
    this.carrier,
    required this.createdAt,
    required this.updatedAt,
    this.shippedAt,
    this.deliveredAt,
    this.items = const [],
  });

  String get customerFullName => '$customerFirstName $customerLastName';
  
  String get shippingAddress {
    final parts = [
      shippingAddressLine1,
      if (shippingAddressLine2?.isNotEmpty == true) shippingAddressLine2,
      shippingCity,
      shippingState,
      shippingPostalCode,
      shippingCountry,
    ];
    return parts.join(', ');
  }

  int get totalItems {
    return items.fold(0, (total, item) => total + item.quantity);
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number'] ?? '',
      userId: json['user']?.toString() ?? '',
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'pending',
      customerEmail: json['customer_email'] ?? '',
      customerPhone: json['customer_phone'],
      customerFirstName: json['customer_first_name'] ?? '',
      customerLastName: json['customer_last_name'] ?? '',
      shippingAddressLine1: json['shipping_address_line_1'] ?? '',
      shippingAddressLine2: json['shipping_address_line_2'],
      shippingCity: json['shipping_city'] ?? '',
      shippingState: json['shipping_state'] ?? '',
      shippingPostalCode: json['shipping_postal_code'] ?? '',
      shippingCountry: json['shipping_country'] ?? '',
      billingAddressLine1: json['billing_address_line_1'] ?? '',
      billingAddressLine2: json['billing_address_line_2'],
      billingCity: json['billing_city'] ?? '',
      billingState: json['billing_state'] ?? '',
      billingPostalCode: json['billing_postal_code'] ?? '',
      billingCountry: json['billing_country'] ?? '',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      shippingCost: double.tryParse(json['shipping_cost']?.toString() ?? '0') ?? 0.0,
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0.0,
      discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method'],
      paymentTransactionId: json['payment_transaction_id'],
      customerNotes: json['customer_notes'],
      adminNotes: json['admin_notes'],
      trackingNumber: json['tracking_number'],
      carrier: json['carrier'],
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
      shippedAt: json['shipped_at'] != null 
          ? date_utils.DateUtils.safeParseOptionalDate(json['shipped_at']) 
          : null,
      deliveredAt: json['delivered_at'] != null 
          ? date_utils.DateUtils.safeParseOptionalDate(json['delivered_at']) 
          : null,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'user': userId,
      'status': status,
      'payment_status': paymentStatus,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'customer_first_name': customerFirstName,
      'customer_last_name': customerLastName,
      'shipping_address_line_1': shippingAddressLine1,
      'shipping_address_line_2': shippingAddressLine2,
      'shipping_city': shippingCity,
      'shipping_state': shippingState,
      'shipping_postal_code': shippingPostalCode,
      'shipping_country': shippingCountry,
      'billing_address_line_1': billingAddressLine1,
      'billing_address_line_2': billingAddressLine2,
      'billing_city': billingCity,
      'billing_state': billingState,
      'billing_postal_code': billingPostalCode,
      'billing_country': billingCountry,
      'subtotal': subtotal,
      'shipping_cost': shippingCost,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_transaction_id': paymentTransactionId,
      'customer_notes': customerNotes,
      'admin_notes': adminNotes,
      'tracking_number': trackingNumber,
      'carrier': carrier,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'shipped_at': shippedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }

  // Helper getter
  double get total => totalAmount;

  Order copyWith({
    String? id,
    String? orderNumber,
    String? userId,
    String? status,
    String? paymentStatus,
    String? customerEmail,
    String? customerPhone,
    String? customerFirstName,
    String? customerLastName,
    String? shippingAddressLine1,
    String? shippingAddressLine2,
    String? shippingCity,
    String? shippingState,
    String? shippingPostalCode,
    String? shippingCountry,
    String? billingAddressLine1,
    String? billingAddressLine2,
    String? billingCity,
    String? billingState,
    String? billingPostalCode,
    String? billingCountry,
    double? subtotal,
    double? shippingCost,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    String? paymentMethod,
    String? paymentTransactionId,
    String? customerNotes,
    String? adminNotes,
    String? trackingNumber,
    String? carrier,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      customerFirstName: customerFirstName ?? this.customerFirstName,
      customerLastName: customerLastName ?? this.customerLastName,
      shippingAddressLine1: shippingAddressLine1 ?? this.shippingAddressLine1,
      shippingAddressLine2: shippingAddressLine2 ?? this.shippingAddressLine2,
      shippingCity: shippingCity ?? this.shippingCity,
      shippingState: shippingState ?? this.shippingState,
      shippingPostalCode: shippingPostalCode ?? this.shippingPostalCode,
      shippingCountry: shippingCountry ?? this.shippingCountry,
      billingAddressLine1: billingAddressLine1 ?? this.billingAddressLine1,
      billingAddressLine2: billingAddressLine2 ?? this.billingAddressLine2,
      billingCity: billingCity ?? this.billingCity,
      billingState: billingState ?? this.billingState,
      billingPostalCode: billingPostalCode ?? this.billingPostalCode,
      billingCountry: billingCountry ?? this.billingCountry,
      subtotal: subtotal ?? this.subtotal,
      shippingCost: shippingCost ?? this.shippingCost,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
      customerNotes: customerNotes ?? this.customerNotes,
      adminNotes: adminNotes ?? this.adminNotes,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      carrier: carrier ?? this.carrier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      items: items ?? this.items,
    );
  }
}

// Single OrderItem class with all necessary properties
class OrderItem {
  final String id;
  final String orderId;
  final String vendorId;
  final String productId;
  final String productName;
  final String productSku;
  final String? productImage;
  final String? variationId;
  final Map<String, dynamic> variationDetails;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Product? product;
  final ProductVariation? variation;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.vendorId,
    required this.productId,
    required this.productName,
    required this.productSku,
    this.productImage,
    this.variationId,
    this.variationDetails = const {},
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
    this.product,
    this.variation,
  });

  // Legacy properties for backward compatibility
  String get imageUrl => productImage ?? '';
  String get name => productName;
  double get price => unitPrice;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      orderId: json['order']?.toString() ?? '',
      vendorId: json['vendor']?.toString() ?? '',
      productId: json['product']?.toString() ?? '',
      productName: json['product_name'] ?? '',
      productSku: json['product_sku'] ?? '',
      productImage: json['product_image'],
      variationId: json['variation']?.toString(),
      variationDetails: json['variation_details'] ?? {},
      quantity: json['quantity'] ?? 1,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'pending',
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
      product: json['product_detail'] != null 
          ? Product.fromJson(json['product_detail']) 
          : null,
      variation: json['variation_detail'] != null 
          ? ProductVariation.fromJson(json['variation_detail']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': orderId,
      'vendor': vendorId,
      'product': productId,
      'product_name': productName,
      'product_sku': productSku,
      'product_image': productImage,
      'variation': variationId,
      'variation_details': variationDetails,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ShippingMethod {
  final String id;
  final String name;
  final String? description;
  final double baseCost;
  final double costPerKg;
  final double? freeShippingThreshold;
  final int minDeliveryDays;
  final int maxDeliveryDays;
  final bool isActive;
  final List<String> availableCountries;
  final double? maxWeight;
  final double? maxLength;
  final double? maxWidth;
  final double? maxHeight;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShippingMethod({
    required this.id,
    required this.name,
    this.description,
    this.baseCost = 0.0,
    this.costPerKg = 0.0,
    this.freeShippingThreshold,
    this.minDeliveryDays = 1,
    this.maxDeliveryDays = 7,
    this.isActive = true,
    this.availableCountries = const [],
    this.maxWeight,
    this.maxLength,
    this.maxWidth,
    this.maxHeight,
    required this.createdAt,
    required this.updatedAt,
  });

  double calculateCost({double weight = 0.0, double orderTotal = 0.0}) {
    if (freeShippingThreshold != null && orderTotal >= freeShippingThreshold!) {
      return 0.0;
    }
    return baseCost + (weight * costPerKg);
  }

  bool isAvailableForCountry(String country) {
    if (availableCountries.isEmpty) return true;
    return availableCountries.contains(country);
  }

  factory ShippingMethod.fromJson(Map<String, dynamic> json) {
    return ShippingMethod(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      baseCost: double.tryParse(json['base_cost']?.toString() ?? '0') ?? 0.0,
      costPerKg: double.tryParse(json['cost_per_kg']?.toString() ?? '0') ?? 0.0,
      freeShippingThreshold: json['free_shipping_threshold'] != null 
          ? double.tryParse(json['free_shipping_threshold'].toString()) 
          : null,
      minDeliveryDays: json['min_delivery_days'] ?? 1,
      maxDeliveryDays: json['max_delivery_days'] ?? 7,
      isActive: json['is_active'] ?? true,
      availableCountries: (json['available_countries'] as List<dynamic>?)
          ?.map((country) => country.toString())
          .toList() ?? [],
      maxWeight: json['max_weight'] != null 
          ? double.tryParse(json['max_weight'].toString()) 
          : null,
      maxLength: json['max_length'] != null 
          ? double.tryParse(json['max_length'].toString()) 
          : null,
      maxWidth: json['max_width'] != null 
          ? double.tryParse(json['max_width'].toString()) 
          : null,
      maxHeight: json['max_height'] != null 
          ? double.tryParse(json['max_height'].toString()) 
          : null,
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'base_cost': baseCost,
      'cost_per_kg': costPerKg,
      'free_shipping_threshold': freeShippingThreshold,
      'min_delivery_days': minDeliveryDays,
      'max_delivery_days': maxDeliveryDays,
      'is_active': isActive,
      'available_countries': availableCountries,
      'max_weight': maxWeight,
      'max_length': maxLength,
      'max_width': maxWidth,
      'max_height': maxHeight,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Coupon {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String discountType;
  final double discountValue;
  final double minimumOrderAmount;
  final double? maximumDiscountAmount;
  final int? usageLimit;
  final int usageLimitPerUser;
  final int usedCount;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Coupon({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minimumOrderAmount = 0.0,
    this.maximumDiscountAmount,
    this.usageLimit,
    this.usageLimitPerUser = 1,
    this.usedCount = 0,
    this.isActive = true,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isValid({double cartTotal = 0.0}) {
    final now = DateTime.now();
    
    if (!isActive) return false;
    if (now.isBefore(startDate)) return false;
    if (now.isAfter(endDate)) return false;
    if (cartTotal < minimumOrderAmount) return false;
    if (usageLimit != null && usedCount >= usageLimit!) return false;
    
    return true;
  }

  double calculateDiscount(double cartTotal) {
    if (discountType == 'percentage') {
      double discount = cartTotal * (discountValue / 100);
      if (maximumDiscountAmount != null) {
        discount = discount > maximumDiscountAmount! ? maximumDiscountAmount! : discount;
      }
      return discount;
    } else if (discountType == 'fixed') {
      return discountValue > cartTotal ? cartTotal : discountValue;
    }
    return 0.0;
  }

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      discountType: json['discount_type'] ?? 'percentage',
      discountValue: double.tryParse(json['discount_value']?.toString() ?? '0') ?? 0.0,
      minimumOrderAmount: double.tryParse(json['minimum_order_amount']?.toString() ?? '0') ?? 0.0,
      maximumDiscountAmount: json['maximum_discount_amount'] != null 
          ? double.tryParse(json['maximum_discount_amount'].toString()) 
          : null,
      usageLimit: json['usage_limit'],
      usageLimitPerUser: json['usage_limit_per_user'] ?? 1,
      usedCount: json['used_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      startDate: date_utils.DateUtils.safeParseDate(json['start_date']),
      endDate: date_utils.DateUtils.safeParseDate(json['end_date']),
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'minimum_order_amount': minimumOrderAmount,
      'maximum_discount_amount': maximumDiscountAmount,
      'usage_limit': usageLimit,
      'usage_limit_per_user': usageLimitPerUser,
      'used_count': usedCount,
      'is_active': isActive,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
