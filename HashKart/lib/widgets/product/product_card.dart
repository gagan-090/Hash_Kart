import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';
import 'rating_stars.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onToggleWishlist;
  final bool isInWishlist;
  final bool showAddToCart;
  final double? width;
  final double? height;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onToggleWishlist,
    this.isInWishlist = false,
    this.showAddToCart = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 180,
      height: height ?? 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: CachedNetworkImage(
                          imageUrl: product.primaryImageUrl ?? 'https://via.placeholder.com/200',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Discount Badge
                    if (product.discountPercentage > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    
                    // Wishlist Button
                    if (onToggleWishlist != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: onToggleWishlist,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isInWishlist ? Icons.favorite : Icons.favorite_border,
                              color: isInWishlist ? AppTheme.accentColor : Colors.grey,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Product Details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand
                      if (product.brand != null)
                        Text(
                          product.brand!.name,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      // Product Name
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Rating
                      if (product.averageRating > 0)
                        Row(
                          children: [
                            RatingStars(
                              rating: product.averageRating,
                              size: 10,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${product.reviewCount})',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 4),
                      
                      // Price
                      Row(
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (product.comparePrice != null && product.comparePrice! > product.price) ...[
                            const SizedBox(width: 4),
                            Text(
                              '₹${product.comparePrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      // Add to Cart Button
                      if (showAddToCart && onAddToCart != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: double.infinity,
                            height: 28,
                            child: ElevatedButton(
                              onPressed: onAddToCart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Add to Cart',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductCardHorizontal extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onToggleWishlist;
  final bool isInWishlist;

  const ProductCardHorizontal({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onToggleWishlist,
    this.isInWishlist = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: product.primaryImageUrl ?? 'https://via.placeholder.com/120',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Product Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand
                      if (product.brand != null)
                        Text(
                          product.brand!.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      // Product Name
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Rating
                      if (product.averageRating > 0)
                        Row(
                          children: [
                            RatingStars(
                              rating: product.averageRating,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${product.reviewCount})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 4),
                      
                      // Price and Actions
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹${product.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                if (product.comparePrice != null && product.comparePrice! > product.price)
                                  Text(
                                    '₹${product.comparePrice!.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          // Action Buttons
                          Column(
                            children: [
                              if (onToggleWishlist != null)
                                IconButton(
                                  onPressed: onToggleWishlist,
                                  icon: Icon(
                                    isInWishlist ? Icons.favorite : Icons.favorite_border,
                                    color: isInWishlist ? AppTheme.accentColor : Colors.grey,
                                    size: 20,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              if (onAddToCart != null)
                                SizedBox(
                                  width: 80,
                                  height: 28,
                                  child: ElevatedButton(
                                    onPressed: onAddToCart,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Add',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}