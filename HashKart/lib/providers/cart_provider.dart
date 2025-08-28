import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _cartItems = [];

  // Loading states
  bool _isLoading = false;
  bool _isUpdating = false;
  final bool _isCheckingOut = false;

  // Error handling
  String? _error;

  // Getters
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get itemCount => _cartItems.length;
  double get subtotal =>
      _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  bool get isCheckingOut => _isCheckingOut;
  String? get error => _error;
  bool get isEmpty => _cartItems.isEmpty;

  // For compatibility with existing screens
  List<CartItem> get cart => cartItems;

  // Initialize cart (for compatibility with existing code)
  Future<void> initializeCart() async {
    // This method is called by existing screens but we don't need to fetch from API
    // Just ensure the cart is ready
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Initialize cart with authentication context
  Future<void> initializeWithAuth(String? authToken) async {
    if (authToken != null) {
      final apiService = _getApiService();
      apiService.setAuthToken(authToken);
      await fetchCart();
    } else {
      _cartItems.clear();
      _isLoading = false;
      _error = null;
      notifyListeners();
    }
  }

  // Load cart (for compatibility with existing code)
  Future<void> loadCart() async {
    await initializeCart();
  }

  // Fetch cart from backend
  Future<void> fetchCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiService = _getApiService();

      debugPrint('🛒 Fetching cart from backend...');

      final response = await apiService.getCart();

      debugPrint('🛒 FetchCart response: $response');

      // Handle different response structures
      List<dynamic> items = [];

      if (response is Map<String, dynamic>) {
        final responseMap = response as Map<String, dynamic>;
        if (responseMap['success'] == true && responseMap['data'] != null) {
          final cartData = responseMap['data'];
          if (cartData is Map<String, dynamic> && cartData['items'] != null) {
            final itemsData = cartData['items'];
            if (itemsData is List) {
              items = List<dynamic>.from(itemsData);
            }
          } else if (cartData is List) {
            items = List<dynamic>.from(cartData);
          }
        } else if (responseMap['results'] != null) {
          final resultsData = responseMap['results'];
          if (resultsData is List) {
            items = List<dynamic>.from(resultsData);
          }
        } else if (responseMap['items'] != null) {
          final itemsData = responseMap['items'];
          if (itemsData is List) {
            items = List<dynamic>.from(itemsData);
          }
        }
      } else if (response is List) {
        items = List<dynamic>.from(response as List);
      }

      debugPrint('🛒 Cart items from backend: $items');

      _cartItems.clear();
      for (final itemData in items) {
        try {
          final productData = itemData['product'];
          if (productData != null) {
            final product = Product.fromJson(productData);
            final cartItem = CartItem(
              id: itemData['id']?.toString() ?? '',
              cartId: itemData['cart']?.toString() ?? '',
              productId: productData['id']?.toString() ?? '',
              variationId: itemData['variation']?.toString(),
              quantity: itemData['quantity'] ?? 1,
              unitPrice:
                  double.tryParse(itemData['unit_price']?.toString() ?? '0') ??
                      0.0,
              createdAt:
                  DateTime.tryParse(itemData['created_at']?.toString() ?? '') ??
                      DateTime.now(),
              updatedAt:
                  DateTime.tryParse(itemData['updated_at']?.toString() ?? '') ??
                      DateTime.now(),
              product: product,
              variation: null,
            );
            _cartItems.add(cartItem);
            debugPrint(
                '✅ Added cart item: ${product.name} x ${itemData['quantity']}');
          } else {
            debugPrint('⚠️ Product data is null for cart item: $itemData');
          }
        } catch (e) {
          debugPrint('❌ Error parsing cart item: $e');
          debugPrint('Item data: $itemData');
        }
      }

      debugPrint('🛒 Total cart items after fetch: ${_cartItems.length}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('❌ Error fetching cart: $e');

      // If there's an authentication error, clear the cart
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('401')) {
        _cartItems.clear();
        debugPrint('🔐 Authentication error - cart cleared');
      }

      notifyListeners();
    }
  }

  // Helper method to get ApiService with proper authentication
  ApiService _getApiService() {
    final apiService = ApiService();
    // The API service should automatically handle authentication
    // through the singleton pattern and stored tokens
    return apiService;
  }

  // Add item to cart
  Future<void> addToCart(Product product, {int quantity = 1}) async {
    try {
      final apiService = _getApiService();

      debugPrint('🛒 Adding to cart: ${product.name} x $quantity');

      final response = await apiService.addToCart(product.id, quantity);

      debugPrint('🛒 Add to cart response: $response');

      if (response['success'] == true) {
        // Refresh cart from backend
        await fetchCart();
        debugPrint('✅ Item added to cart successfully');
      } else {
        _error = response['message'] ?? 'Failed to add item to cart';
        debugPrint('❌ Failed to add to cart: $_error');
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error adding to cart: $e');
      notifyListeners();
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String productId) async {
    try {
      // Find the cart item by product ID first
      final cartItem = getCartItem(productId);
      if (cartItem == null) {
        _error = 'Item not found in cart';
        notifyListeners();
        return;
      }

      final apiService = _getApiService();
      final response = await apiService.removeFromCart(cartItem.id);

      if (response['success'] == true) {
        // Refresh cart from backend
        await fetchCart();
      } else {
        _error = response['message'] ?? 'Failed to remove item from cart';
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update item quantity
  Future<void> updateQuantity(String productId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(productId);
      return;
    }

    try {
      // Find the cart item by product ID first
      final cartItem = getCartItem(productId);
      if (cartItem == null) {
        _error = 'Item not found in cart';
        notifyListeners();
        return;
      }

      final apiService = _getApiService();
      final response =
          await apiService.updateCartItem(cartItem.id, newQuantity);

      if (response['success'] == true) {
        // Refresh cart from backend
        await fetchCart();
      } else {
        _error = response['message'] ?? 'Failed to update item quantity';
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update cart item (for compatibility with existing code)
  Future<bool> updateCartItem(String itemId, int quantity) async {
    if (quantity < 1) {
      await removeFromCart(itemId);
      return true;
    }

    _isUpdating = true;
    _error = null;
    notifyListeners();

    try {
      // If itemId is actually a productId, use updateQuantity
      // If itemId is actually a cart item ID, call API directly
      try {
        // Try to find cart item by ID first (assuming itemId is cart item ID)
        final cartItem = _cartItems.firstWhere((item) => item.id == itemId);
        final apiService = _getApiService();
        final response = await apiService.updateCartItem(cartItem.id, quantity);

        if (response['success'] == true) {
          await fetchCart();
          return true;
        } else {
          _error = response['message'] ?? 'Failed to update item quantity';
          notifyListeners();
          return false;
        }
      } catch (e) {
        // If not found by ID, assume it's a product ID and use updateQuantity
        await updateQuantity(itemId, quantity);
        return true;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      final apiService = _getApiService();
      await apiService.clearCart();

      // Clear local cart items
      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Check if product is in cart
  bool isInCart(String productId) {
    return _cartItems.any((item) => item.product?.id == productId);
  }

  // Get cart item by product ID
  CartItem? getCartItem(String productId) {
    try {
      return _cartItems.firstWhere((item) => item.product?.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Get total items count (sum of all quantities)
  int get totalItemsCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // Clear error (for compatibility with existing code)
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get product quantity (for compatibility with existing code)
  int getProductQuantity(String productId) {
    final item = getCartItem(productId);
    return item?.quantity ?? 0;
  }

  // Check if product is in cart (for compatibility with existing code)
  bool isProductInCart(String productId) {
    return isInCart(productId);
  }

  // Add to cart with product ID (for compatibility with existing code)
  Future<void> addToCartById(String productId, {int quantity = 1}) async {
    try {
      final apiService = _getApiService();
      final response = await apiService.addToCart(productId, quantity);

      if (response['success'] == true) {
        // Refresh cart from backend
        await fetchCart();
      } else {
        _error = response['message'] ?? 'Failed to add item to cart';
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Remove from cart with product ID (for compatibility with existing code)
  Future<void> removeFromCartById(String productId) async {
    await removeFromCart(productId);
  }

  // Update quantity with product ID (for compatibility with existing code)
  Future<void> updateQuantityById(String productId, int quantity) async {
    await updateQuantity(productId, quantity);
  }

  // Add demo item for testing (bypasses API)
  Future<void> addDemoItem(CartItem cartItem) async {
    _cartItems.add(cartItem);
    notifyListeners();
  }

  // Create demo cart for testing payments
  Future<void> createDemoCart() async {
    try {
      // Clear existing items
      _cartItems.clear();

      // Create demo product
      final demoProduct = Product(
        id: 'demo_product_1',
        vendorId: 'demo_vendor_1',
        name: 'Demo Product for Payment Test',
        slug: 'demo-product-payment-test',
        description: 'This is a demo product for testing payment functionality',
        price: 79.99,
        comparePrice: 99.99,
        stockQuantity: 10,
        averageRating: 4.5,
        reviewCount: 25,
        status: 'active',
        isFeatured: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create demo cart item
      final demoCartItem = CartItem(
        id: 'demo_cart_item_1',
        cartId: 'demo_cart',
        productId: demoProduct.id,
        quantity: 2,
        unitPrice: demoProduct.price, // Use the actual price
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        product: demoProduct,
      );

      _cartItems.add(demoCartItem);
      notifyListeners();

      debugPrint(
          'Demo cart created with $itemCount items, subtotal: ₹$subtotal');
    } catch (e) {
      debugPrint('Error creating demo cart: $e');
    }
  }

  // Test cart loading with debug info
  Future<void> testCartLoading() async {
    debugPrint('🧪 Testing cart loading...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiService = _getApiService();
      debugPrint('🧪 API Service created');

      final response = await apiService.getCart();
      debugPrint('🧪 Cart API Response: $response');

      // Simulate successful loading for testing
      await Future.delayed(const Duration(seconds: 1));

      _isLoading = false;
      notifyListeners();
      debugPrint('🧪 Cart loading test completed');
    } catch (e) {
      _error = 'Test Error: $e';
      _isLoading = false;
      debugPrint('🧪 Cart loading test failed: $e');
      notifyListeners();
    }
  }
}
