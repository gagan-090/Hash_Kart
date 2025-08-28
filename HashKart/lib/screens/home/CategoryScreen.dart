import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../models/category_model.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with TickerProviderStateMixin {
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  bool _isGridView = true;
  Timer? _refreshTimer;
  
  late AnimationController _slideAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Enhanced category icons with more variety
  final Map<String, Map<String, dynamic>> _categoryIcons = {
    'mobile': {
      'icon': Icons.smartphone,
      'gradient': [Color(0xFF667EEA), Color(0xFF764BA2)],
      'color': Color(0xFF667EEA),
    },
    'electronics': {
      'icon': Icons.devices,
      'gradient': [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      'color': Color(0xFF4FACFE),
    },
    'fashion': {
      'icon': Icons.checkroom,
      'gradient': [Color(0xFFFA709A), Color(0xFFFEE140)],
      'color': Color(0xFFFA709A),
    },
    'home': {
      'icon': Icons.home_filled,
      'gradient': [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
      'color': Color(0xFF10B981),
    },
    'sports': {
      'icon': Icons.sports_soccer,
      'gradient': [Color(0xFFFFB75E), Color(0xFFED8F03)],
      'color': Color(0xFFFFB75E),
    },
    'books': {
      'icon': Icons.menu_book,
      'gradient': [Color(0xFF667EEA), Color(0xFF764BA2)],
      'color': Color(0xFF8B5CF6),
    },
    'beauty': {
      'icon': Icons.face_retouching_natural,
      'gradient': [Color(0xFFF093FB), Color(0xFFF5576C)],
      'color': Color(0xFFEC4899),
    },
    'automotive': {
      'icon': Icons.directions_car,
      'gradient': [Color(0xFF4ECDC4), Color(0xFF44A08D)],
      'color': Color(0xFF06B6D4),
    },
    'health': {
      'icon': Icons.health_and_safety,
      'gradient': [Color(0xFF56AB2F), Color(0xFFA8E6CF)],
      'color': Color(0xFF10B981),
    },
    'toys': {
      'icon': Icons.toys,
      'gradient': [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
      'color': Color(0xFFEF4444),
    },
    'jewelry': {
      'icon': Icons.diamond,
      'gradient': [Color(0xFFFFD89B), Color(0xFF19547B)],
      'color': Color(0xFFF59E0B),
    },
    'grocery': {
      'icon': Icons.local_grocery_store,
      'gradient': [Color(0xFF74B9FF), Color(0xFF0984E3)],
      'color': Color(0xFF3B82F6),
    },
    'default': {
      'icon': Icons.category,
      'gradient': [Color(0xFF6B7280), Color(0xFF9CA3AF)],
      'color': Color(0xFF6B7280),
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCategories();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _slideAnimationController.dispose();
    _fadeAnimationController.dispose();
    _scaleAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimationController.forward();
    _slideAnimationController.forward();
    _scaleAnimationController.forward();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  void _loadCategories() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      if (productProvider.categories.isEmpty) {
        productProvider.loadCategories();
      }
    });
  }

  Future<void> _refreshData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.loadCategories();
  }

  Map<String, dynamic> _getCategoryData(String categoryName) {
    final key = categoryName.toLowerCase().replaceAll(' ', '');
    for (final iconKey in _categoryIcons.keys) {
      if (key.contains(iconKey)) {
        return _categoryIcons[iconKey]!;
      }
    }
    return _categoryIcons['default']!;
  }

  List<Category> _getFilteredCategories(List<Category> categories) {
    if (_searchQuery.isEmpty) return categories;
    return categories.where((category) =>
        category.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (category.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernAppBar(),
            _buildSearchAndFilter(),
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  if (productProvider.isLoading && productProvider.categories.isEmpty) {
                    return _buildLoadingState();
                  }

                  if (productProvider.error != null && productProvider.categories.isEmpty) {
                    return _buildErrorState(productProvider);
                  }

                  if (productProvider.categories.isEmpty) {
                    return _buildEmptyState();
                  }

                  final filteredCategories = _getFilteredCategories(productProvider.categories);

                  if (filteredCategories.isEmpty) {
                    return _buildNoSearchResults();
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshData,
                    child: _isGridView
                        ? _buildGridView(filteredCategories)
                        : _buildListView(filteredCategories),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF374151)),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    'Discover amazing products',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  _isGridView ? Icons.view_list : Icons.grid_view,
                  color: const Color(0xFF374151),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search categories...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey[600],
                size: 22,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(List<Category> categories) {
    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildModernCategoryCard(category, index);
          },
        ),
      ),
    );
  }

  Widget _buildListView(List<Category> categories) {
    return SlideTransition(
      position: _slideAnimation,
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildModernCategoryListItem(category, index);
        },
      ),
    );
  }

  Widget _buildModernCategoryCard(Category category, int index) {
    final categoryData = _getCategoryData(category.name);
    final gradient = categoryData['gradient'] as List<Color>;
    final color = categoryData['color'] as Color;
    final icon = categoryData['icon'] as IconData;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                NavigationHelper.goToProductListing(
                  category: category.name,
                  categoryId: category.id,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header with gradient
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Background pattern
                          Positioned.fill(
                            child: CustomPaint(
                              painter: PatternPainter(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                          ),
                          // Category image or icon
                          Center(
                            child: category.image != null && category.image!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      category.image!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Icon(
                                            icon,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (category.description?.isNotEmpty == true)
                              Text(
                                category.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const Spacer(),
                            Row(
                              children: [
                                Text(
                                  'Explore',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: color,
                                  size: 12,
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
          ),
        );
      },
    );
  }

  Widget _buildModernCategoryListItem(Category category, int index) {
    final categoryData = _getCategoryData(category.name);
    final gradient = categoryData['gradient'] as List<Color>;
    final color = categoryData['color'] as Color;
    final icon = categoryData['icon'] as IconData;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  NavigationHelper.goToProductListing(
                    category: category.name,
                    categoryId: category.id,
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon container
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradient,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: category.image != null && category.image!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  category.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      icon,
                                      color: Colors.white,
                                      size: 28,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                icon,
                                color: Colors.white,
                                size: 28,
                              ),
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (category.description?.isNotEmpty == true)
                              Text(
                                category.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      // Arrow
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: color,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading Categories...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discovering amazing products for you',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ProductProvider productProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              productProvider.error ?? 'Failed to load categories',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                productProvider.clearError();
                _refreshData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.category_outlined,
                size: 40,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Categories Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Categories will appear here once they are added',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.search_off,
                size: 40,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Results Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B7280),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.clear_all, size: 20),
              label: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for background patterns
class PatternPainter extends CustomPainter {
  final Color color;

  PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const spacing = 20.0;
    
    // Draw diagonal lines
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}