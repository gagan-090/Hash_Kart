import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'package:hashkart/data/all_products.dart';

class SubcategoryScreen extends StatefulWidget {
  final String? categoryName;
  final String? subcategoryName;

  const SubcategoryScreen({
    super.key,
    this.categoryName,
    this.subcategoryName,
  });

  @override
  State<SubcategoryScreen> createState() => _SubcategoryScreenState();
}

class _SubcategoryScreenState extends State<SubcategoryScreen> {
  String _sortBy = 'Popular';
  bool _isGridView = true;

  // Sample product data - in a real app, this would come from an API
  final List<Product> _products = allProducts;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subcategoryName ?? 'Products',
              style: AppTheme.heading3.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 18,
              ),
            ),
            if (widget.categoryName != null)
              Text(
                widget.categoryName!,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.textPrimary),
            onPressed: () => NavigationHelper.goToSearch(),
          ),
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
        ],
      ),
      body: Column(
        children: [
          // Filter and Sort Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => NavigationHelper.goToFilter(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tune,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Filter',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _showSortOptions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sort,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sort: $_sortBy',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Results Count
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_products.length} products found',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Products Grid/List
          Expanded(
            child: _isGridView ? _buildGridView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Stack(
          children: [
            ProductCard(
              imageUrl: product.imageUrls[0],
              title: product.name,
              price: '₹${product.price.toStringAsFixed(2)}',
              originalPrice: product.originalPrice != null ? '₹${product.originalPrice!.toStringAsFixed(2)}' : null,
              rating: product.rating,
              onTap: () => NavigationHelper.goToProductDetails(product: product),
              onFavorite: () {},
            ),
          ],
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: InkWell(
            onTap: () => NavigationHelper.goToProductDetails(product: product),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[100],
                      child: Image.network(
                        product.imageUrls[0],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.image,
                              size: 30,
                              color: AppTheme.primaryColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.description,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '₹${product.price.toStringAsFixed(2)}',
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            if (product.originalPrice != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '₹${product.originalPrice!.toStringAsFixed(2)}',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textLight,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: AppTheme.warningColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  product.rating.toString(),
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort by',
                style: AppTheme.heading3,
              ),
              const SizedBox(height: 16),
              ...[
                'Popular',
                'Price: Low to High',
                'Price: High to Low',
                'Customer Rating',
                'Newest First',
                'Best Sellers',
              ].map((option) => ListTile(
                title: Text(option),
                trailing: _sortBy == option
                    ? const Icon(Icons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _sortBy = option;
                  });
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }
}
