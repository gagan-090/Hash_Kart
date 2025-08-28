import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product_model.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        // Show loading state
        if (productProvider.isLoading && productProvider.wishlistItems.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: _buildAppBar(0),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show error state
        if (productProvider.error != null && productProvider.wishlistItems.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: _buildAppBar(0),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Wishlist Error',
                    style: AppTheme.heading3.copyWith(color: AppTheme.accentColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    productProvider.error!,
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      productProvider.clearError();
                      productProvider.loadWishlist();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: _buildAppBar(productProvider.wishlistItems.length),
          body: productProvider.wishlistItems.isEmpty
              ? _buildEmptyState()
              : _buildWishlistContent(productProvider),
          bottomNavigationBar: productProvider.wishlistItems.isNotEmpty 
              ? _buildBottomBar(productProvider) 
              : null,
        );
      },
    );
  }

  AppBar _buildAppBar(int itemCount) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'My Wishlist${itemCount > 0 ? ' ($itemCount)' : ''}',
        style: AppTheme.heading3.copyWith(color: AppTheme.textPrimary),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isGridView ? Icons.view_list : Icons.grid_view,
            color: AppTheme.textPrimary,
          ),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
          onSelected: (value) {
            if (value == 'clear') {
              _showClearWishlistDialog();
            } else if (value == 'share') {
              _shareWishlist();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20),
                  SizedBox(width: 12),
                  Text('Share Wishlist'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(
                    Icons.clear_all,
                    size: 20,
                    color: AppTheme.accentColor,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Clear All',
                    style: TextStyle(color: AppTheme.accentColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      title: 'Your wishlist is empty',
      subtitle: 'Save items you love to buy them later',
      icon: Icons.favorite_outline,
      buttonText: 'Start Shopping',
      onButtonPressed: () => NavigationHelper.goToHome(),
    );
  }

  Widget _buildWishlistContent(ProductProvider productProvider) {
    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: productProvider.wishlistItems.length,
        itemBuilder: (context, index) {
          final item = productProvider.wishlistItems[index];
          return _buildGridItem(item, index, productProvider);
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: productProvider.wishlistItems.length,
        itemBuilder: (context, index) {
          final item = productProvider.wishlistItems[index];
          return _buildListItem(item, index, productProvider);
        },
      );
    }
  }

  Widget _buildGridItem(Product item, int index, ProductProvider productProvider) {
    final product = item;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey[100],
                    child:                     Image.network(
                      product.primaryImageUrl ?? 'https://via.placeholder.com/150',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.image,
                            size: 50,
                            color: AppTheme.primaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _removeFromWishlist(item.id, productProvider),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: AppTheme.accentColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                if (!product.isInStock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Out of Stock',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        product.averageRating.toStringAsFixed(1),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(2)}',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.comparePrice != null && product.comparePrice! > product.price)
                        Text(
                          '₹${product.comparePrice!.toStringAsFixed(2)}',
                          style: AppTheme.bodySmall.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppTheme.textLight,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(Product item, int index, ProductProvider productProvider) {
    final product = item;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey[100],
              child: Stack(
                children: [
                  Image.network(
                    product.primaryImageUrl ?? 'https://via.placeholder.com/80',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.image,
                          color: AppTheme.primaryColor,
                        ),
                      );
                    },
                  ),
                  if (!product.isInStock)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Center(
                        child: Text(
                          'Out of\nStock',
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      product.averageRating.toStringAsFixed(1),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                                              '₹${product.price.toStringAsFixed(2)}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                                          if (product.comparePrice != null && product.comparePrice! > product.price)
                      Text(
                        '₹${product.comparePrice!.toStringAsFixed(2)}',
                        style: AppTheme.bodySmall.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppTheme.textLight,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _removeFromWishlist(item.id, productProvider),
                icon: const Icon(Icons.favorite, color: AppTheme.accentColor),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 80,
                child: ElevatedButton(
                  onPressed: product.isInStock 
                      ? () => _addToCart(item.id) 
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Add',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ProductProvider productProvider) {
    final inStockItems = productProvider.wishlistItems
        .where((item) => item.isInStock)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$inStockItems items available',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Ready to add to cart',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          CustomButton(
            text: 'Add All to Cart',
            onPressed: inStockItems > 0 ? () => _addAllToCart(productProvider) : null,
            width: 150,
          ),
        ],
      ),
    );
  }

  Future<void> _removeFromWishlist(String productId, ProductProvider productProvider) async {
    final success = await productProvider.toggleWishlist(productId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed from wishlist')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(productProvider.error ?? 'Failed to remove item'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  Future<void> _addToCart(String productId) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.addToCartById(productId, quantity: 1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added to cart')),
    );
  }

  Future<void> _addAllToCart(ProductProvider productProvider) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final inStockItems = productProvider.wishlistItems
        .where((item) => item.isInStock)
        .toList();
    
    for (final item in inStockItems) {
      await cartProvider.addToCartById(item.id, quantity: 1);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${inStockItems.length} items added to cart')),
    );
  }

  void _shareWishlist() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Wishlist shared!')));
  }

  void _showClearWishlistDialog() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Wishlist', style: AppTheme.heading3),
        content: Text(
          'Are you sure you want to remove all items from your wishlist?',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Remove all items from wishlist
              final items = List.from(productProvider.wishlistItems);
              for (final item in items) {
                await productProvider.toggleWishlist(item.id);
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wishlist cleared')),
              );
            },
            child: Text(
              'Clear',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
