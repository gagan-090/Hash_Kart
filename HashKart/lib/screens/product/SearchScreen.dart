import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  final List<String> _searchHistory = [
    'Wireless headphones',
    'Smart watch',
    'iPhone case',
    'Laptop bag',
    'Running shoes',
  ];

  final List<String> _popularSearches = [
    'Electronics',
    'Fashion',
    'Home decor',
    'Sports',
    'Books',
    'Beauty',
    'Toys',
    'Automotive',
  ];

  final List<Product> _searchResults = [];


  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
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
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textLight, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.textLight, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _isSearching = false;
                          _searchResults.clear();
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onChanged: _onSearchChanged,
            onSubmitted: _onSearchSubmitted,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.textPrimary),
            onPressed: () => NavigationHelper.goToFilter(),
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          return _isSearching 
              ? _buildSearchResults(productProvider) 
              : _buildSearchSuggestions();
        },
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: AppTheme.heading3.copyWith(fontSize: 18),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchHistory.clear();
                    });
                  },
                  child: Text(
                    'Clear All',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_searchHistory.length, (index) {
              final search = _searchHistory[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(Icons.history, color: AppTheme.textLight),
                  title: Text(
                    search,
                    style: AppTheme.bodyMedium,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textLight, size: 20),
                    onPressed: () {
                      setState(() {
                        _searchHistory.removeAt(index);
                      });
                    },
                  ),
                  onTap: () {
                    _searchController.text = search;
                    _onSearchSubmitted(search);
                  },
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Popular Searches
          Text(
            'Popular Searches',
            style: AppTheme.heading3.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSearches.map((search) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = search;
                  _onSearchSubmitted(search);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    search,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Categories
          Text(
            'Browse Categories',
            style: AppTheme.heading3.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3,
            children: [
              _buildCategoryTile('Electronics', Icons.devices),
              _buildCategoryTile('Fashion', Icons.checkroom),
              _buildCategoryTile('Home & Garden', Icons.home),
              _buildCategoryTile('Sports', Icons.sports_soccer),
              _buildCategoryTile('Books', Icons.menu_book),
              _buildCategoryTile('Beauty', Icons.face_retouching_natural),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String title, IconData icon) {
    return GestureDetector(
      onTap: () => NavigationHelper.goToCategory(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(ProductProvider productProvider) {
    // Show loading state
    if (productProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Searching...',
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    // Show error state
    if (productProvider.error != null) {
      return Center(
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
              'Search Error',
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
                if (_searchController.text.isNotEmpty) {
                  _onSearchChanged(_searchController.text);
                }
              },
              child: const Text('Retry Search'),
            ),
          ],
        ),
      );
    }

    // Show empty results
    if (productProvider.searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppTheme.textLight,
            ),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: AppTheme.heading3,
            ),
            SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${productProvider.searchResults.length} results found',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.view_list, color: AppTheme.textSecondary),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.grid_view, color: AppTheme.primaryColor),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Results grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: productProvider.searchResults.length,
            itemBuilder: (context, index) {
              final product = productProvider.searchResults[index];
              return ProductCard(
                imageUrl: product.imageUrls[0],
                title: product.name,
                price: '₹${product.price.toStringAsFixed(2)}',
                originalPrice: product.originalPrice != null ? '₹${product.originalPrice!.toStringAsFixed(2)}' : null,
                rating: product.rating,
                onTap: () =>
                    NavigationHelper.goToProductDetails(product: product),
                onFavorite: () {},
              );
            },
          ),
        ),
      ],
    );
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
      });
      // Clear search results in ProductProvider
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.clearSearchResults();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Use ProductProvider to search
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.searchProducts(query);
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;

    // Add to search history
    if (!_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      });
    }

    _onSearchChanged(query);
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
