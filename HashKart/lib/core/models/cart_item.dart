import '../../models/product_model.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.product.id == product.id &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => product.id.hashCode ^ quantity.hashCode;

  @override
  String toString() {
    return 'CartItem(product: ${product.name}, quantity: $quantity)';
  }
}
