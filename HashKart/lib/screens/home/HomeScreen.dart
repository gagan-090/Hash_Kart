import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../models/product_model.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final PageController _bannerController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  Timer? _refreshTimer;

  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  // Dynamic category icons mapping
  final Map<String, IconData> _categoryIcons = {
    'electronics': Icons.devices,
    'mobile': Icons.phone_android,
    'fashion': Icons.checkroom,
    'home': Icons.home_filled,
    'sports': Icons.sports_soccer,
    'books': Icons.menu_book,
    'beauty': Icons.face_retouching_natural,
    'toys': Icons.toys,
    'automotive': Icons.directions_car,
    'health': Icons.health_and_safety,
    'grocery': Icons.local_grocery_store,
    'jewelry': Icons.diamond,
    'default': Icons.category,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _startAutoRefresh();
    _loadInitialData();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _refreshTimer?.cancel();
    _headerAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _headerAnimationController, curve: Curves.easeInOut),
    );

    _headerAnimationController.forward();
  }

  void _setupScrollListener() {
    // Scroll listener can be used for other purposes if needed
  }

  void _startAutoRefresh() {
    // Auto-refresh data every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Load all necessary data
      productProvider.loadCategories();
      productProvider.loadFeaturedProducts();
      productProvider.loadProducts();

      // Load user-specific data if authenticated
      if (authProvider.isAuthenticated) {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        cartProvider.loadCart();
        productProvider.loadWishlist();
      }
    });
  }

  Future<void> _refreshData() async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Refresh all data
      await Future.wait([
        productProvider.loadCategories(),
        productProvider.loadFeaturedProducts(),
        productProvider.loadProducts(),
      ]);

      // Refresh user-specific data if authenticated
      if (authProvider.isAuthenticated) {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        await Future.wait([
          cartProvider.loadCart(),
          productProvider.loadWishlist(),
        ]);
      }
    } catch (e) {
      // Handle error silently or log it
      debugPrint('Failed to refresh data: ${e.toString()}');
    }
  }

  void _startBannerAutoScroll(int bannerCount) {
    _bannerTimer?.cancel();
    if (bannerCount > 1) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted && _bannerController.hasClients) {
          final nextPage = (_currentBannerIndex + 1) % bannerCount;
          _bannerController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildModernAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    _buildDynamicBanners(),
                    _buildQuickActions(),
                    _buildCategoriesSection(),
                    _buildFeaturedProducts(),
                    _buildRecentProducts(),
                    _buildPopularProducts(),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/product-details-demo');
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.preview, color: Colors.white),
        label: const Text(
          'Product Demo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      title: FadeTransition(
        opacity: _headerAnimation,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'HashKart',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined,
                      color: Color(0xFF1F2937), size: 24),
                  if (authProvider.isAuthenticated)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => NavigationHelper.goToNotificationSettings(),
            );
          },
        ),
        Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            return IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      color: Color(0xFF1F2937), size: 24),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          cartProvider.itemCount > 99
                              ? '99+'
                              : cartProvider.itemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => NavigationHelper.goToCart(),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => NavigationHelper.goToSearch(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[600], size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Search for products, brands and more...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.tune, color: Colors.grey[700], size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicBanners() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        // Use featured products as banners if no banner system exists
        final featuredProducts =
            productProvider.featuredProducts.take(3).toList();

        if (featuredProducts.isEmpty) {
          return _buildDefaultBanner();
        }

        // Start auto-scroll when banners are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startBannerAutoScroll(featuredProducts.length);
        });

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _bannerController,
                onPageChanged: (index) {
                  setState(() {
                    _currentBannerIndex = index;
                  });
                },
                itemCount: featuredProducts.length,
                itemBuilder: (context, index) {
                  final product = featuredProducts[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Image.network(
                            product.images.isNotEmpty
                                ? product.images.first.image
                                : '',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF667EEA),
                                      Color(0xFF764BA2)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF667EEA),
                                      Color(0xFF764BA2)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Icon(Icons.image,
                                      size: 50, color: Colors.white),
                                ),
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.black.withValues(alpha: 0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 24,
                            top: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Featured Product',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Text(
                                    '₹${product.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Color(0xFF667EEA),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (featuredProducts.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    featuredProducts.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentBannerIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentBannerIndex == index
                            ? const Color(0xFF667EEA)
                            : const Color(0xFF667EEA).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'HashKart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Discover amazing products',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Text(
                    'Shop Now',
                    style: TextStyle(
                      color: Color(0xFF667EEA),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickActionItem(
            'Categories',
            Icons.grid_view_rounded,
            const Color(0xFF667EEA),
            () => NavigationHelper.goToCategory(),
          ),
          _buildQuickActionItem(
            'Flash Sale',
            Icons.flash_on,
            const Color(0xFFEF4444),
            () => NavigationHelper.goToFlashSale(),
          ),
          _buildQuickActionItem(
            'Offers',
            Icons.local_offer,
            const Color(0xFF10B981),
            () => NavigationHelper.goToOffers(),
          ),
          _buildQuickActionItem(
            'Wishlist',
            Icons.favorite_outline,
            const Color(0xFFEC4899),
            () => NavigationHelper.goToWishlist(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 75,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shop by Category',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              TextButton(
                onPressed: () => NavigationHelper.goToCategory(),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF667EEA),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            final categories = productProvider.categories;

            if (productProvider.isLoading && categories.isEmpty) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (categories.isEmpty) {
              return Container(
                height: 120,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No categories available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final iconKey =
                      category.name.toLowerCase().replaceAll(' ', '');
                  final icon =
                      _categoryIcons[iconKey] ?? _categoryIcons['default']!;

                  return Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        NavigationHelper.goToProductListing(
                          category: category.name,
                          categoryId: category.id,
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: category.image != null &&
                                    category.image!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(
                                      category.image!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(
                                          icon,
                                          color: const Color(0xFF667EEA),
                                          size: 32,
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
                                    icon,
                                    color: const Color(0xFF667EEA),
                                    size: 32,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Featured Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              TextButton(
                onPressed: () => NavigationHelper.goToSearch(),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF667EEA),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            final featuredProducts = productProvider.featuredProducts;

            if (productProvider.isLoading && featuredProducts.isEmpty) {
              return const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (featuredProducts.isEmpty) {
              return Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No featured products available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: featuredProducts.length,
                itemBuilder: (context, index) {
                  final product = featuredProducts[index];
                  return _buildProductCard(product);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recently Added',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              TextButton(
                onPressed: () => NavigationHelper.goToSearch(),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF667EEA),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            final recentProducts = productProvider.products.take(10).toList();

            if (productProvider.isLoading && recentProducts.isEmpty) {
              return const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (recentProducts.isEmpty) {
              return Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.new_releases_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No recent products available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recentProducts.length,
                itemBuilder: (context, index) {
                  final product = recentProducts[index];
                  return _buildProductCard(product);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPopularProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              TextButton(
                onPressed: () => NavigationHelper.goToSearch(),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF667EEA),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            // Get popular products (you can implement rating-based sorting in provider)
            final popularProducts = productProvider.products
                .where((p) => p.averageRating >= 4.0)
                .take(10)
                .toList();

            if (productProvider.isLoading && popularProducts.isEmpty) {
              return const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (popularProducts.isEmpty) {
              return Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.trending_up_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No popular products available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: popularProducts.length,
                itemBuilder: (context, index) {
                  final product = popularProducts[index];
                  return _buildProductCard(product);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          // Navigate to product details using NavigationHelper
          NavigationHelper.goToProductDetails(product: product);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                color: Colors.grey[100],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      product.images.isNotEmpty
                          ? product.images.first.image
                          : '',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child:
                                Icon(Icons.image, size: 40, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  // Wishlist Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        // Toggle wishlist - implement this functionality in your ProductProvider
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Wishlist feature coming soon!')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_outline,
                          color: Colors.grey,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Discount Badge
                  if (product.comparePrice != null &&
                      product.comparePrice! > product.price)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(((product.comparePrice! - product.price) / product.comparePrice!) * 100).toInt()}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[600], size: 14),
                        const SizedBox(width: 2),
                        Text(
                          product.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF059669),
                          ),
                        ),
                        if (product.comparePrice != null &&
                            product.comparePrice! > product.price) ...[
                          const SizedBox(width: 6),
                          Text(
                            '₹${product.comparePrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
