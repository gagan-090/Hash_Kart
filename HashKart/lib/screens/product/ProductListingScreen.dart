import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';

class ProductListingScreen extends StatefulWidget {
  final String category;
  final String? subCategory;
  final String? categoryId;

  const ProductListingScreen({
    super.key,
    required this.category,
    this.subCategory,
    this.categoryId,
  });

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  bool _isGridView = true;
  String _sortBy = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      // Load products based on category
      if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
        // Use category ID directly for filtering
        print('Loading products for category ID: ${widget.categoryId}');
        productProvider.loadCategoryProducts(widget.categoryId!);
      } else if (widget.category.isNotEmpty && widget.category.toLowerCase() != 'all') {
        // Fallback: Find category by name
        final category = productProvider.categories.firstWhere(
          (cat) => cat.name.toLowerCase() == widget.category.toLowerCase(),
          orElse: () => Category(
            id: '', 
            name: widget.category, 
            slug: '',
            productCount: 0,
            isActive: true,
            order: 0,
            createdAt: DateTime.now(), 
            updatedAt: DateTime.now()
          ),
        );
        
        if (category.id.isNotEmpty) {
          print('Found category by name, loading products for ID: ${category.id}');
          productProvider.loadCategoryProducts(category.id);
        } else {
          print('Category not found by name, loading all products');
          productProvider.loadProducts();
        }
      } else {
        print('Loading all products');
        productProvider.loadProducts();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      if (productProvider.hasMoreProducts && !productProvider.isLoading) {
        productProvider.loadMoreProducts();
      }
    }
  }

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
              widget.subCategory ?? widget.category,
              style: AppTheme.heading3.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 18,
              ),
            ),
            if (widget.subCategory != null)
              Text(
                widget.category,
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
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          return Column(
            children: [
              // Filter and Sort Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      '${productProvider.products.length} Products',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => NavigationHelper.goToFilter(),
                      child: Row(
                        children: [
                          const Icon(Icons.tune, size: 20, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Filter',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _showSortOptions(productProvider),
                      child: Row(
                        children: [
                          const Icon(Icons.sort, size: 20, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Sort',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Products List/Grid
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _refreshProducts(productProvider),
                  child: _isGridView 
                      ? _buildGridView(productProvider) 
                      : _buildListView(productProvider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _refreshProducts(ProductProvider productProvider) async {
    if (widget.category.isNotEmpty) {
      final category = productProvider.categories.firstWhere(
        (cat) => cat.name.toLowerCase() == widget.category.toLowerCase(),
        orElse: () => Category(
          id: '', 
          name: widget.category, 
          slug: '',
          productCount: 0,
          isActive: true,
          order: 0,
          createdAt: DateTime.now(), 
          updatedAt: DateTime.now()
        ),
      );
      
      if (category.id.isNotEmpty) {
        await productProvider.loadCategoryProducts(category.id);
      } else {
        await productProvider.loadProducts();
      }
    } else {
      await productProvider.loadProducts();
    }
  }

  Widget _buildGridView(ProductProvider productProvider) {
    if (productProvider.isLoading && productProvider.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (productProvider.products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.textLight),
            SizedBox(height: 16),
            Text('No products found', style: AppTheme.heading3),
            Text('Try adjusting your search or filters', style: AppTheme.bodyMedium),
          ],
        ),
      );
    }
    
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: productProvider.products.length + (productProvider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= productProvider.products.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final product = productProvider.products[index];
        return _buildProductGridCard(product, productProvider);
      },
    );
  }

  Widget _buildListView(ProductProvider productProvider) {
    if (productProvider.isLoading && productProvider.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (productProvider.products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.textLight),
            SizedBox(height: 16),
            Text('No products found', style: AppTheme.heading3),
            Text('Try adjusting your search or filters', style: AppTheme.bodyMedium),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: productProvider.products.length + (productProvider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= productProvider.products.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final product = productProvider.products[index];
        return _buildProductListCard(product, productProvider);
      },
    );
  }

  Widget _buildProductGridCard(Product product, ProductProvider productProvider) {
    return _ProductCard(
      imageUrl: product.primaryImageUrl ?? '',
      title: product.name,
      price: '₹${product.price.toStringAsFixed(0)}',
      originalPrice: null,
      rating: product.averageRating,
      isFavorite: productProvider.isInWishlist(product.id),
      onTap: () => _showProductDetails(product),
      onFavorite: () => _toggleFavorite(product, productProvider),
    );
  }

  Widget _buildProductListCard(Product product, ProductProvider productProvider) {
    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
                  product.primaryImageUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.primaryColor.withOpacity(0.1),
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
            const SizedBox(width: 16),
            
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
                    product.brand?.name ?? 'No Brand',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.shortDescription ?? 'No description available',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      if (product.comparePrice != null && product.comparePrice! > product.price) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₹${product.comparePrice!.toStringAsFixed(0)}',
                          style: AppTheme.bodySmall.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                      if (product.discountPercentage > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${product.discountPercentage.toInt()}% OFF',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (product.averageRating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          product.averageRating.toStringAsFixed(1),
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount})',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Action Buttons
            Column(
              children: [
                GestureDetector(
                  onTap: () => _toggleFavorite(product, productProvider),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      productProvider.isInWishlist(product.id) ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: productProvider.isInWishlist(product.id) ? AppTheme.accentColor : AppTheme.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _addToCart(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(80, 32),
                  ),
                  child: Text(
                    'Add to Cart',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(Product product) {
    NavigationHelper.goToProductDetails(product: product);
  }

  void _showSortOptions(ProductProvider productProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 16),
            _buildSortOption('Price: Low to High', 'price', productProvider),
            _buildSortOption('Price: High to Low', '-price', productProvider),
            _buildSortOption('Customer Rating', '-average_rating', productProvider),
            _buildSortOption('Newest First', '-created_at', productProvider),
            _buildSortOption('Name A-Z', 'name', productProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, String value, ProductProvider productProvider) {
    return ListTile(
      title: Text(title),
      trailing: _sortBy == value ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        productProvider.setSortBy(value);
        Navigator.pop(context);
      },
    );
  }

  void _toggleFavorite(Product product, ProductProvider productProvider) {
    productProvider.toggleWishlist(product.id);
  }

  void _addToCart(Product product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addToCart(product, quantity: 1);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// ProductCard widget implementation
class _ProductCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String? originalPrice;
  final double rating;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _ProductCard({
    required this.imageUrl,
    required this.title,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey[100],
                child: Stack(
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(
                            Icons.image,
                            size: 40,
                            color: AppTheme.primaryColor,
                          ),
                        );
                      },
                    ),
                    // Favorite Button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFavorite ? AppTheme.accentColor : AppTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Product Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Price
                  Row(
                    children: [
                      Text(
                        price,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      if (originalPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          originalPrice!,
                          style: AppTheme.bodySmall.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  // Rating
                  if (rating > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
