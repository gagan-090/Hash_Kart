import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/navigation_helper.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _promoController = TextEditingController();
  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      debugPrint('CartScreen initState - User authenticated: ${authProvider.isAuthenticated}');
      debugPrint('CartScreen initState - Access token: ${authProvider.accessToken != null ? 'Present' : 'Missing'}');
      
      if (authProvider.isAuthenticated && authProvider.accessToken != null) {
        debugPrint('User is authenticated, initializing cart with auth...');
        cartProvider.initializeWithAuth(authProvider.accessToken);
      } else {
        debugPrint('User not authenticated, cart will be empty');
        cartProvider.initializeCart();
      }
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CartProvider, AuthProvider>(
      builder: (context, cartProvider, authProvider, child) {
        // Check if user is authenticated
        if (!authProvider.isAuthenticated) {
          return _buildUnauthenticatedScreen();
        }
        
        // Show loading state
        if (cartProvider.isLoading) {
          return _buildLoadingScreen();
        }

        // Show error state
        if (cartProvider.error != null && cartProvider.isEmpty) {
          return _buildErrorScreen(cartProvider, authProvider);
        }

        // Show empty cart
        if (cartProvider.isEmpty) {
          return _buildEmptyCartScreen();
        }

        // Show cart with items
        return _buildCartScreen(cartProvider, authProvider);
      },
    );
  }

  Widget _buildUnauthenticatedScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar('My Cart', showBackButton: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.login_rounded,
                size: 50,
                color: Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Login Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please login to view your cart items',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF718096),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildPrimaryButton('Login Now', () => NavigationHelper.goToLogin()),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar('My Cart', showBackButton: true),
      body: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildErrorScreen(CartProvider cartProvider, AuthProvider authProvider) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar('My Cart', showBackButton: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 50,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                cartProvider.error!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF718096),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildPrimaryButton('Try Again', () {
                cartProvider.clearError();
                if (authProvider.isAuthenticated && authProvider.accessToken != null) {
                  cartProvider.initializeWithAuth(authProvider.accessToken);
                } else {
                  cartProvider.fetchCart();
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCartScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar('My Cart', showBackButton: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add some delicious items to get started',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF718096),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildPrimaryButton('Start Shopping', () => NavigationHelper.goToHome()),
          ],
        ),
      ),
    );
  }

  Widget _buildCartScreen(CartProvider cartProvider, AuthProvider authProvider) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar('My Cart', showBackButton: true),
      body: RefreshIndicator(
        onRefresh: () async {
          if (authProvider.isAuthenticated && authProvider.accessToken != null) {
            await cartProvider.initializeWithAuth(authProvider.accessToken);
          } else {
            await cartProvider.fetchCart();
          }
        },
        color: const Color(0xFFFF6B35),
        child: Column(
          children: [
            // Cart Items List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: cartProvider.cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartProvider.cartItems[index];
                  return _buildCartItemCard(cartProvider, item, index);
                },
              ),
            ),

            // Promo Code Section
            _buildPromoCodeSection(cartProvider),

            // Order Summary and Checkout
            _buildBottomSection(cartProvider),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String title, {bool showBackButton = false}) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFF2D3748),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF2D3748),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.more_horiz,
            color: Color(0xFF2D3748),
          ),
          onPressed: () {
            // Handle menu action
          },
        ),
      ],
    );
  }

  Widget _buildCartItemCard(CartProvider cartProvider, CartItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.product?.primaryImageUrl?.isNotEmpty == true
                    ? item.product!.primaryImageUrl!
                    : 'https://via.placeholder.com/70',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      color: Color(0xFFFF6B35),
                      size: 30,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.product?.name ?? 'Unknown Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showRemoveDialog(cartProvider, item),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Weight/Description (you may need to add this field to your model)
                
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\₹${(item.product?.price ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    _buildQuantityControls(cartProvider, item),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls(CartProvider cartProvider, CartItem item) {
    return Row(
      children: [
        GestureDetector(
          onTap: item.quantity > 1
              ? () => cartProvider.updateCartItem(item.product?.id ?? '', item.quantity - 1)
              : null,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.quantity > 1 ? const Color(0xFFF7FAFC) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: item.quantity > 1 ? const Color(0xFFE2E8F0) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              Icons.remove,
              size: 16,
              color: item.quantity > 1 ? const Color(0xFF4A5568) : const Color(0xFFA0AEC0),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            item.quantity.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => cartProvider.updateCartItem(item.product?.id ?? '', item.quantity + 1),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCodeSection(CartProvider cartProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_offer_outlined,
              color: Color(0xFFFF6B35),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Apply a promo code',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF4A5568),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Apply',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(CartProvider cartProvider) {
    final subtotal = cartProvider.subtotal;
    final total = subtotal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary rows
          _buildSummaryRow('Subtotal', subtotal),
          const SizedBox(height: 12),
          // Removed delivery charges row
          const SizedBox(height: 16),
          
          // Divider
          Container(
            height: 1,
            color: const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 16),
          
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Cost',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              Text(
                '\₹${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 255, 53, 53),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Checkout Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: cartProvider.isLoading ? null : () {
                debugPrint('CartScreen: Checkout button pressed');
                NavigationHelper.goToCheckout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.6),
              ),
              child: cartProvider.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Checkout Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF718096),
          ),
        ),
        Text(
          '\₹${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showRemoveDialog(CartProvider cartProvider, CartItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Remove Item',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          content: Text(
            'Are you sure you want to remove "${item.product?.name ?? 'this item'}" from your cart?',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF718096),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await cartProvider.removeFromCart(item.product?.id ?? '');
              },
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}