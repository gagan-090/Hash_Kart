import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/product_model.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/product/product_image_carousel.dart';
import '../../widgets/product/rating_stars.dart';
import '../../widgets/product/product_card.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TickerProviderStateMixin {
  int _quantity = 1;
  bool _isLoading = false;
  int _currentImageIndex = 0;
  String? _selectedVariationId;
  Product _currentProduct = Product.empty();
  bool _showFullDescription = false;
  bool _showFullSpecs = false;
  String _pincode = '';
  bool _pincodeChecked = false;
  String _deliveryInfo = '';

  late PageController _imagePageController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _imagePageController = PageController();

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _heartAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _buttonAnimationController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      _showLoginDialog();
      return;
    }

    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      cartProvider.addToCart(
        _currentProduct,
        quantity: _quantity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${_currentProduct.name} to cart!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add to cart'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _buyNow() async {
    await _addToCart();
    if (!_isLoading) {
      NavigationHelper.goToCart();
    }
  }

  void _shareProduct() {
    Share.share(
      'Check out ${_currentProduct.name} for ₹${_currentProduct.price.toStringAsFixed(2)}',
      subject: _currentProduct.name,
    );
  }

  void _toggleWishlist() {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    productProvider.toggleWishlist(_currentProduct.id);
    _heartAnimationController.forward().then((_) {
      _heartAnimationController.reverse();
    });
    HapticFeedback.lightImpact();
  }

  void _selectVariation(ProductVariation variation) {
    setState(() {
      _selectedVariationId = variation.id;
      _currentProduct = Product(
        id: _currentProduct.id,
        vendorId: _currentProduct.vendorId,
        name: _currentProduct.name,
        slug: _currentProduct.slug,
        description: _currentProduct.description,
        price: variation.price,
        comparePrice: variation.comparePrice,
        stockQuantity: variation.stockQuantity,
        createdAt: _currentProduct.createdAt,
        updatedAt: _currentProduct.updatedAt,
        images: _currentProduct.images,
        variations: _currentProduct.variations,
        reviews: _currentProduct.reviews,
        specifications: _currentProduct.specifications,
        averageRating: _currentProduct.averageRating,
        reviewCount: _currentProduct.reviewCount,
        category: _currentProduct.category,
        brand: _currentProduct.brand,
      );
    });
  }

  void _checkPincode() {
    if (_pincode.length == 6) {
      setState(() {
        _pincodeChecked = true;
        _deliveryInfo =
            'Delivery by ${DateTime.now().add(const Duration(days: 3)).day}/${DateTime.now().add(const Duration(days: 3)).month}';
      });
      HapticFeedback.selectionClick();
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Login Required'),
        content: const Text('Please log in to add items to your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NavigationHelper.goToLogin();
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  String _formatSpecificationValue(dynamic value) {
    if (value == null) return 'N/A';

    // If it's already a proper string without JSON formatting, return as is
    if (value is String &&
        !value.contains('{') &&
        !value.contains('[') &&
        !value.contains('"')) {
      return value;
    }

    String stringValue = value.toString();

    // Handle Map/Object values (from Django JSONField)
    if (value is Map) {
      List<String> formattedParts = [];
      value.forEach((key, val) {
        formattedParts.add('$key: ${_formatSpecificationValue(val)}');
      });
      return formattedParts.join(', ');
    }

    // Handle List/Array values
    if (value is List) {
      List<String> formattedItems = [];
      for (var item in value) {
        formattedItems.add(_formatSpecificationValue(item));
      }
      return formattedItems.join(', ');
    }

    // Handle JSON string representations
    if (stringValue.startsWith('{') && stringValue.endsWith('}')) {
      try {
        // Try to parse as JSON first
        var decoded = json.decode(stringValue);
        return _formatSpecificationValue(decoded);
      } catch (e) {
        // If JSON parsing fails, handle as string
        stringValue = stringValue.substring(1, stringValue.length - 1);

        List<String> parts = stringValue.split(',');
        List<String> formattedParts = [];

        for (String part in parts) {
          part = part.trim();
          if (part.contains(':')) {
            List<String> keyValue = part.split(':');
            if (keyValue.length >= 2) {
              String key = keyValue[0].trim().replaceAll('"', '');
              String val =
                  keyValue.sublist(1).join(':').trim().replaceAll('"', '');
              formattedParts.add('$key: $val');
            }
          } else {
            formattedParts.add(part.replaceAll('"', ''));
          }
        }

        return formattedParts.join(', ');
      }
    }

    // Handle array string representations
    if (stringValue.startsWith('[') && stringValue.endsWith(']')) {
      try {
        var decoded = json.decode(stringValue);
        return _formatSpecificationValue(decoded);
      } catch (e) {
        stringValue = stringValue.substring(1, stringValue.length - 1);
        return stringValue.replaceAll('"', '').replaceAll(',', ', ');
      }
    }

    // Clean up simple strings
    stringValue = stringValue.replaceAll('"', '');

    // Handle boolean values
    if (stringValue.toLowerCase() == 'true') return 'Yes';
    if (stringValue.toLowerCase() == 'false') return 'No';

    // Handle numeric values with units
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(stringValue)) {
      double? numValue = double.tryParse(stringValue);
      if (numValue != null) {
        if (numValue == numValue.toInt()) {
          return numValue.toInt().toString();
        } else {
          return numValue.toString();
        }
      }
    }

    return stringValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Sticky Header with Navigation
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: AppTheme.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.share,
                      color: AppTheme.textPrimary, size: 20),
                  onPressed: _shareProduct,
                ),
              ),
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  final isInWishlist =
                      productProvider.isInWishlist(_currentProduct.id);
                  return Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ScaleTransition(
                      scale: _heartScaleAnimation,
                      child: IconButton(
                        icon: Icon(
                          isInWishlist ? Icons.favorite : Icons.favorite_border,
                          color: isInWishlist
                              ? AppTheme.accentColor
                              : AppTheme.textPrimary,
                          size: 20,
                        ),
                        onPressed: _toggleWishlist,
                      ),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ProductImageCarousel(
                images: _currentProduct.images,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
              ),
            ),
          ),

          // Product Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductHeader(),
                  _buildPriceSection(),
                  _buildRatingSection(),
                  if (_currentProduct.variations.isNotEmpty)
                    _buildVariantsSection(),
                  _buildKeyFeatures(),
                  _buildDeliverySection(),
                  _buildOffersSection(),
                  _buildDescriptionSection(),
                  _buildSpecificationsSection(),
                  _buildReviewsSection(),
                  _buildRecommendedProducts(),
                  const SizedBox(height: 100), // Space for floating buttons
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildProductHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentProduct.brand != null)
            Text(
              _currentProduct.brand!.name,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            _currentProduct.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            '₹${_currentProduct.price.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          if (_currentProduct.comparePrice != null &&
              _currentProduct.comparePrice! > _currentProduct.price) ...[
            const SizedBox(width: 12),
            Text(
              '₹${_currentProduct.comparePrice!.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondary,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_currentProduct.discountPercentage.toStringAsFixed(0)}% OFF',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  _currentProduct.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_currentProduct.reviewCount} Reviews',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          RatingStars(
            rating: _currentProduct.averageRating,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildVariantsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentProduct.variations.map((variation) {
              final isSelected = _selectedVariationId == variation.id;
              return GestureDetector(
                onTap: () => _selectVariation(variation),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppTheme.primaryColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    variation.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildKeyFeatures() {
    if (_currentProduct.specifications.isEmpty) return const SizedBox.shrink();

    final features = _currentProduct.specifications.entries.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${feature.key}: ${_formatSpecificationValue(feature.value)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDeliverySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => _pincode = value,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      hintText: 'Enter Pincode',
                      counterText: '',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _checkPincode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Check', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (_pincodeChecked) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.local_shipping,
                      color: AppTheme.successColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _deliveryInfo,
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.money_off, color: AppTheme.successColor, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Free Delivery',
                    style: TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOffersSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Offers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildOfferItem('Bank Offer', '5% off with Axis Bank Credit Card'),
            _buildOfferItem('EMI', 'No-cost EMI available'),
            _buildOfferItem('Coupon', 'Extra ₹500 off with coupons'),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferItem(String type, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: Text(
              _currentProduct.description.length > 200
                  ? '${_currentProduct.description.substring(0, 200)}...'
                  : _currentProduct.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            secondChild: Text(
              _currentProduct.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            crossFadeState: _showFullDescription
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          if (_currentProduct.description.length > 200)
            TextButton(
              onPressed: () {
                setState(() {
                  _showFullDescription = !_showFullDescription;
                });
              },
              child: Text(
                _showFullDescription ? 'Read Less' : 'Read More',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSpecificationsSection() {
    if (_currentProduct.specifications.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _currentProduct.specifications.entries.map((spec) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          spec.key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatSpecificationValue(spec.value),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    if (_currentProduct.reviews.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customer Reviews',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all reviews
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._currentProduct.reviews
              .take(3)
              .map((review) => _buildReviewItem(review)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReviewItem(ProductReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        RatingStars(
                          rating: review.rating.toDouble(),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        if (review.isVerifiedPurchase)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedProducts() {
    // Mock recommended products for now
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You might also like',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                // Create mock products for demonstration
                final mockProduct = Product(
                  id: 'mock_$index',
                  vendorId: 'vendor_1',
                  name: 'Recommended Product ${index + 1}',
                  slug: 'product-${index + 1}',
                  description: 'This is a recommended product description.',
                  price: 999.0 + (index * 100),
                  comparePrice: 1299.0 + (index * 100),
                  averageRating: 4.0 + (index * 0.2),
                  reviewCount: 50 + (index * 10),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: ProductCard(
                    product: mockProduct,
                    width: 160,
                    height: 240,
                    onTap: () {
                      // Navigate to product details
                    },
                    onAddToCart: () {
                      // Add to cart
                    },
                    onToggleWishlist: () {
                      // Toggle wishlist
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quantity Selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _quantity > 1
                        ? () {
                            setState(() => _quantity--);
                            HapticFeedback.selectionClick();
                          }
                        : null,
                    icon: const Icon(Icons.remove, size: 18),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _quantity++);
                      HapticFeedback.selectionClick();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Add to Cart Button
            Expanded(
              child: ScaleTransition(
                scale: _buttonScaleAnimation,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Buy Now Button
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _buyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
