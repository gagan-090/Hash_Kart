import 'product_model.dart';

class Cart {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double shipping;
  final double discount;
  final double total;
  final Map<String, dynamic>? coupon;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.discount,
    required this.total,
    this.coupon,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => CartItem.fromJson(item))
          .toList() ?? [],
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      tax: 0.0, // Django doesn't calculate tax in cart
      shipping: 0.0, // Django doesn't calculate shipping in cart
      discount: 0.0, // Django doesn't calculate discount in cart
      total: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0, // Use subtotal as total for now
      coupon: json['coupon'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shipping,
      'discount': discount,
      'total': total,
      'coupon': coupon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CartItem {
  final String id;
  final Product product;
  final int quantity;
  final double price;
  final double subtotal;
  final Map<String, dynamic>? variation;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
    double? subtotal,
    this.variation,
    DateTime? addedAt,
  }) : subtotal = subtotal ?? (price * quantity),
       addedAt = addedAt ?? DateTime.now();

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      product: Product.fromJson(json['product'] ?? {}),
      quantity: json['quantity'] ?? 1,
      price: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0, // Django uses 'unit_price'
      subtotal: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0, // Django uses 'total_price'
      variation: json['variation_details'], // Django uses 'variation_details'
      addedAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(), // Django uses 'created_at'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
      'variation': variation,
      'added_at': addedAt.toIso8601String(),
    };
  }

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    double? price,
    double? subtotal,
    Map<String, dynamic>? variation,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
      variation: variation ?? this.variation,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
