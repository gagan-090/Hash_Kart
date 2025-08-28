import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class CartItemCard extends StatelessWidget {
  final CartItem cartItem;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.cartItem,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                cartItem.product?.primaryImageUrl?.isNotEmpty == true
                    ? cartItem.product!.primaryImageUrl!
                    : 'https://via.placeholder.com/80',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.product?.name ?? 'Unknown Product',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${(cartItem.product?.price ?? 0.0).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quantity Controls
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => onQuantityChanged(cartItem.quantity - 1),
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 20,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${cartItem.quantity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onQuantityChanged(cartItem.quantity + 1),
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 20,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove Button and Total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove item',
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${((cartItem.product?.price ?? 0.0) * cartItem.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
