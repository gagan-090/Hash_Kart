import 'package:flutter/material.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';

class MobileScreen extends StatefulWidget {
  const MobileScreen({super.key});

  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;

  // Brand data - exactly as shown in image
  final List<BrandItem> _brands = [
    BrandItem('iPhone', Icons.phone_iphone),
    BrandItem('Motorola', Icons.phone_android),
    BrandItem('Samsung', Icons.phone_android),
    BrandItem('Nothing', Icons.phone_android),
    BrandItem('Oppo', Icons.phone_android),
    BrandItem('Android', Icons.android),
    BrandItem('POCO', Icons.phone_android),
    BrandItem('realme', Icons.phone_android),
  ];

  // Top deals data - exactly as shown in image
  final List<TopDealProduct> _topDeals = [
    TopDealProduct(
      'moto g58 (8GB)',
      'From ₹20,999',
      '₹24,999',
      '16% off',
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=200',
    ),
    TopDealProduct(
      'vivo T4 Lite 5G',
      'From ₹18,999',
      '₹22,999',
      '17% off',
      'https://images.unsplash.com/photo-1574944985070-8f3ebc6b79d2?w=200',
    ),
    TopDealProduct(
      'Galaxy S4 FE',
      'From ₹54,999',
      '₹64,999',
      '15% off',
      'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=200',
    ),
    TopDealProduct(
      'iPhone 15',
      'From ₹79,900',
      '₹89,900',
      '11% off',
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=200',
    ),
    TopDealProduct(
      'OnePlus 12R',
      'From ₹39,999',
      '₹44,999',
      '11% off',
      'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=200',
    ),
    TopDealProduct(
      'Redmi Note 13',
      'From ₹16,999',
      '₹19,999',
      '15% off',
      'https://images.unsplash.com/photo-1574944985070-8f3ebc6b79d2?w=200',
    ),
  ];

  // Best sellers data - exactly as shown in image
  final List<BestSellerProduct> _bestSellers = [
    BestSellerProduct(
      'motorola g85 5G (128GB)',
      '4.4⭐',
      '3D Curved POLED Display',
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=200',
    ),
    BestSellerProduct(
      'Samsung Galaxy M35',
      '4.5⭐',
      'Super AMOLED Display',
      'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=200',
    ),
    BestSellerProduct(
      'iPhone 14 Plus',
      '4.6⭐',
      'Super Retina XDR Display',
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=200',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startBannerAutoScroll();
  }

  void _startBannerAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _bannerController.hasClients) {
        final nextPage = (_currentBannerIndex + 1) % 2; // 2 banners
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startBannerAutoScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mobile',
          style: AppTheme.heading3.copyWith(color: AppTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.textPrimary),
            onPressed: () => NavigationHelper.goToSearch(),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: AppTheme.textPrimary),
            onPressed: () => NavigationHelper.goToWishlist(),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.textPrimary),
            onPressed: () => NavigationHelper.goToCart(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Banner Carousel (Motorola & Freedom Sale)
            _buildMainBannerCarousel(),
            
            const SizedBox(height: 8),
            
            // Brand Navigation Row
            _buildBrandNavigationRow(),
            
            const SizedBox(height: 16),
            
            // Top Deals Section
            _buildTopDealsSection(),
            
            const SizedBox(height: 16),
            
            // Promotional Banners (New Year, No Cost EMI, Super Savings)
            _buildPromotionalBanners(),
            
            const SizedBox(height: 16),
            
            // Too Many Choices Section
            _buildTooManyChoicesSection(),
            
            const SizedBox(height: 16),
            
            // Best Sellers Section
            _buildBestSellersSection(),
            
            const SizedBox(height: 16),
            
            // Upcoming Sales Section
            _buildUpcomingSalesSection(),
            
            const SizedBox(height: 16),
            
            // Pulse Section
            _buildPulseSection(),
            
            const SizedBox(height: 16),
            
            // Upcoming Launches Section
            _buildUpcomingLaunchesSection(),
            
            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildMainBannerCarousel() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(8),
      child: PageView(
        controller: _bannerController,
        onPageChanged: (index) {
          setState(() {
            _currentBannerIndex = index;
          });
        },
        children: [
          // Motorola Banner
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.green[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 20,
                  top: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'motorola',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        'moto g⁵⁴',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Starting from',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        'Just ₹9,999',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Shop Now',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 20,
                  bottom: 20,
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.phone_android,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Freedom Sale Banner
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 20,
                  top: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'FREEDOM SALE',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Up to 70% Off',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Explore Now',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 20,
                  bottom: 20,
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_offer,
                      size: 40,
                      color: Colors.white,
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

  Widget _buildBrandNavigationRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _brands.length,
          itemBuilder: (context, index) {
            final brand = _brands[index];
            return Container(
              width: 80,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Icon(
                      brand.icon,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    brand.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopDealsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top deals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: _topDeals.length,
            itemBuilder: (context, index) {
              final product = _topDeals[index];
              return _buildTopDealCard(product);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopDealCard(TopDealProduct product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey[50],
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.phone_android,
                          size: 60,
                          color: Colors.grey,
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.discount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
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
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.price,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    product.originalPrice,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionalBanners() {
    return Column(
      children: [
        // New Year, New Week Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [Colors.purple[400]!, Colors.purple[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 16,
                top: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New Year, New Week',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Explore Now',
                        style: TextStyle(
                          color: Colors.purple[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // No Cost EMI Banner
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 16, right: 4),
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [Colors.pink[400]!, Colors.pink[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No Cost EMI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Explore Now',
                              style: TextStyle(
                                color: Colors.pink[600],
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Super Savings Banner
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 4, right: 16),
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [Colors.orange[400]!, Colors.orange[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Super Savings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Explore Now',
                              style: TextStyle(
                                color: Colors.orange[600],
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTooManyChoicesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Too Many Choices?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Find Your Ideal Smartphone',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Explore Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.phone_android,
              size: 40,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestSellersSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Best Sellers for you',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _bestSellers.length,
              itemBuilder: (context, index) {
                final product = _bestSellers[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildBestSellerCard(product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestSellerCard(BestSellerProduct product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
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
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Container(
                width: double.infinity,
                color: Colors.grey[50],
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.phone_android,
                      size: 60,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.rating,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.displayType,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSalesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Sales',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.blue[800]!, Colors.blue[900]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 20,
                  top: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buy any Samsung Galaxy F36 5G',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Get up to ₹5,000 off',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'No Questions Asked',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 20,
                  bottom: 20,
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.phone_android,
                      size: 40,
                      color: Colors.white,
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

  Widget _buildPulseSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pulse',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.orange[400]!, Colors.orange[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Stack(
              children: [
                Positioned(
                  left: 20,
                  top: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'realme 15 5G',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Up to ₹4,499',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 20,
                  bottom: 20,
                  child: Icon(
                    Icons.trending_up,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingLaunchesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Launches',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.purple[600]!, Colors.purple[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 20,
                  top: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Coming Soon',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Next Generation Smartphones',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Notify Me',
                          style: TextStyle(
                            color: Colors.purple[800],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  right: 20,
                  top: 20,
                  bottom: 20,
                  child: Icon(
                    Icons.notifications,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }
}

// Data models
class BrandItem {
  final String name;
  final IconData icon;

  BrandItem(this.name, this.icon);
}

class TopDealProduct {
  final String name;
  final String price;
  final String originalPrice;
  final String discount;
  final String imageUrl;

  TopDealProduct(
    this.name,
    this.price,
    this.originalPrice,
    this.discount,
    this.imageUrl,
  );
}

class BestSellerProduct {
  final String name;
  final String rating;
  final String displayType;
  final String imageUrl;

  BestSellerProduct(
    this.name,
    this.rating,
    this.displayType,
    this.imageUrl,
  );
}
