import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Razorpay _razorpay;
  bool _isLoading = false;
  bool _isProcessingPayment = false;
  String _selectedPaymentMethod = 'online';
  String? _currentOrderId; // Store the created order ID
  
  // Form controllers for address and customer info
  final _formKey = GlobalKey<FormState>();
  final _shippingAddressController = TextEditingController();
  final _shippingCityController = TextEditingController();
  final _shippingStateController = TextEditingController();
  final _shippingPostalCodeController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  
  // Test Razorpay Key (replace with your actual test key)
  static const String _razorpayTestKey = 'rzp_test_R7xVvdyoHrXAT3';

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _loadCartData();
    
    // Set default values for testing
    _customerNameController.text = 'Test Customer';
    _customerPhoneController.text = '9876543210';
    _customerEmailController.text = 'test@example.com';
    _shippingAddressController.text = '123 Test Street';
    _shippingCityController.text = 'Mumbai';
    _shippingStateController.text = 'Maharashtra';
    _shippingPostalCodeController.text = '400001';
  }

  @override
  void dispose() {
    _razorpay.clear();
    _shippingAddressController.dispose();
    _shippingCityController.dispose();
    _shippingStateController.dispose();
    _shippingPostalCodeController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    super.dispose();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _setupEventHandlers();
  }

  void _setupEventHandlers() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _loadCartData() async {
    setState(() => _isLoading = true);
    try {
      await context.read<CartProvider>().fetchCart();
    } catch (e) {
      debugPrint('Error loading cart: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() => _isProcessingPayment = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Payment Successful! Redirecting to order confirmation...',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    // Use the stored order ID from order creation
    final orderId = _currentOrderId;
    if (orderId == null) {
      _showErrorSnackBar('Missing order reference');
      return;
    }

    // Optionally call backend verify endpoint (if signature/orderId available)
    // Skipping here if plugin doesn't provide signature; backend can also verify by payment_id
    _navigateToOrderSuccess(response.paymentId!, orderId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessingPayment = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Payment Failed: ${response.message ?? 'Unknown error'}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'External Wallet Selected: ${response.walletName}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2196F3),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }



  Future<void> _createOrderAndProcessPayment() async {
    // Check authentication first
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showErrorSnackBar('Please login to place an order');
      return;
    }

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cartProvider = context.read<CartProvider>();
    final totalAmount = cartProvider.subtotal;
    
    if (totalAmount <= 0) {
      _showErrorSnackBar('Invalid amount for payment');
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      // Step 0: Fetch a real shipping method id
      final shippingMethods = await ApiService().getShippingMethods();
      final shippingMethodId = (shippingMethods.isNotEmpty
              ? shippingMethods.first['id']?.toString()
              : null) ?? '';
      if (shippingMethodId.isEmpty) {
        _showErrorSnackBar('No shipping methods available');
        setState(() => _isProcessingPayment = false);
        return;
      }

      // Step 1: Create order in backend
      final orderData = {
        'shipping_address_line_1': _shippingAddressController.text,
        'shipping_city': _shippingCityController.text,
        'shipping_state': _shippingStateController.text,
        'shipping_postal_code': _shippingPostalCodeController.text,
        'shipping_country': 'India',
        'billing_same_as_shipping': true,
        'shipping_method': shippingMethodId,
        'payment_method': _selectedPaymentMethod == 'online' ? 'razorpay' : 'cod',
        'customer_notes': '',
        'cart_items': cartProvider.cartItems.map((item) => {
          'product': item.productId,
          'quantity': item.quantity,
        }).toList(),
      };

      debugPrint('🛒 Creating order with data: $orderData');
      debugPrint('🔐 Auth token: ${authProvider.accessToken}');

      final apiService = ApiService();
      // Ensure the API service has the current auth token
      apiService.setAuthToken(authProvider.accessToken!);
      
      final orderResponse = await apiService.createOrder(orderData);

      if (orderResponse['success'] == true) {
        final orderId = orderResponse['data']['id'];
        _currentOrderId = orderId; // Store the order ID
        debugPrint('✅ Order created successfully: $orderId');

        // Step 2: Process payment based on method
        if (_selectedPaymentMethod == 'online') {
          // Create payment order on backend to get gateway order id
          final paymentOrder = await apiService.createPaymentOrder(orderId, 'razorpay');
          if (paymentOrder['success'] == true) {
            await _processRazorpayPayment(orderId, totalAmount, paymentOrder);
          } else {
            throw Exception(paymentOrder['error'] ?? 'Failed to start payment');
          }
        } else {
          await _processCODPayment(orderId, totalAmount);
        }
      } else {
        throw Exception(orderResponse['message'] ?? 'Failed to create order');
      }
    } catch (e) {
      debugPrint('❌ Error in order creation/payment: $e');
      setState(() => _isProcessingPayment = false);
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> _processRazorpayPayment(String orderId, double totalAmount, Map<String, dynamic> paymentOrder) async {
    try {
      final options = {
        'key': paymentOrder['key_id'] ?? _razorpayTestKey,
        'amount': paymentOrder['amount'] ?? (totalAmount * 100).round(),
        'currency': 'INR',
        'name': 'HashKart',
        'description': 'Payment for Order #$orderId',
        'order_id': paymentOrder['gateway_order_id'],
        'timeout': 180,
        'prefill': {
          'contact': _customerPhoneController.text,
          'email': _customerEmailController.text,
          'name': _customerNameController.text,
        },
        'notes': {
          'order_id': orderId,
          'cart_items_count': context.read<CartProvider>().itemCount.toString(),
        },
        'theme': {
          'color': '#4F46E5',
        },
      };

      debugPrint('🚀 Opening Razorpay with options: $options');
      _razorpay.open(options);

      Future.delayed(const Duration(seconds: 30), () {
        if (mounted && _isProcessingPayment) {
          setState(() => _isProcessingPayment = false);
        }
      });
    } catch (e) {
      debugPrint('❌ Error opening Razorpay: $e');
      setState(() => _isProcessingPayment = false);
      _showErrorSnackBar('Error opening payment: $e');
    }
  }

  Future<void> _processCODPayment(String orderId, double totalAmount) async {
    // For COD, order is already created, just navigate to success
    setState(() => _isProcessingPayment = false);
    _navigateToOrderSuccessCOD(orderId);
  }

  void _openRazorpayCheckout() async {
    // This method is now deprecated, use _createOrderAndProcessPayment instead
    await _createOrderAndProcessPayment();
  }

  void _navigateToOrderSuccess(String paymentId, String orderId) {
    context.read<CartProvider>().clearCart();
    
    Navigator.of(context).pushReplacementNamed(
      '/order-success',
      arguments: {
        'paymentId': paymentId,
        'amount': context.read<CartProvider>().subtotal,
        'orderId': orderId,
        'paymentMethod': _selectedPaymentMethod == 'online' ? 'razorpay' : 'cod',
        'paymentStatus': 'completed',
      },
    );
  }

  void _navigateToOrderSuccessCOD(String orderId) {
    context.read<CartProvider>().clearCart();
    
    Navigator.of(context).pushReplacementNamed(
      '/order-success',
      arguments: {
        'paymentId': null,
        'amount': context.read<CartProvider>().subtotal,
        'orderId': orderId,
        'paymentMethod': 'cod',
        'paymentStatus': 'not_applicable',
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
                if (cartProvider.isEmpty) {
                  return _buildEmptyCartState();
                }
                return _buildCheckoutContent(cartProvider);
              },
            ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isEmpty) return const SizedBox.shrink();
          return _buildBottomBar(cartProvider);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading checkout...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCartState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add some amazing products to your cart to continue with checkout',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text(
                'Go Back to Cart',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutContent(CartProvider cartProvider) {
    final authProvider = context.read<AuthProvider>();
    
    // Show login prompt if not authenticated
    if (!authProvider.isAuthenticated) {
      return _buildLoginPrompt();
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderSummary(cartProvider),
          const SizedBox(height: 20),
          _buildAddressForm(),
          const SizedBox(height: 20),
          _buildPaymentMethods(),
          const SizedBox(height: 20),
          _buildDemoCartButton(cartProvider),
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${cartProvider.itemCount} item${cartProvider.itemCount != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Order Items
            ...cartProvider.cartItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.product?.primaryImageUrl != null
                          ? Image.network(
                              item.product!.primaryImageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.image,
                                  color: Color(0xFF9CA3AF),
                                  size: 24,
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                                    ),
                                  ),
                                );
                              },
                            )
                          : const Icon(
                              Icons.image,
                              color: Color(0xFF9CA3AF),
                              size: 24,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product?.name ?? 'Product',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Qty: ${item.quantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ],
              ),
            )),
            
            const Divider(height: 24),
            
            // Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${cartProvider.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Shipping Address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Customer Information
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _customerPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _customerEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _shippingAddressController,
                decoration: const InputDecoration(
                  labelText: 'Address Line 1 *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _shippingCityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your city';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _shippingStateController,
                      decoration: const InputDecoration(
                        labelText: 'State *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.map),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your state';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _shippingPostalCodeController,
                decoration: const InputDecoration(
                  labelText: 'Postal Code *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin_drop),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your postal code';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                ),
                  child: const Icon(
                    Icons.payment,
                    color: Color(0xFF4F46E5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Online Payment Option
            _buildPaymentOption(
              value: 'online',
              title: 'Online Payment',
              subtitle: 'Credit/Debit Cards, UPI, Net Banking, Wallets',
              icon: Icons.credit_card,
              color: const Color(0xFF4F46E5),
              features: ['Secure', 'Instant', 'Multiple Options'],
            ),
            
            const SizedBox(height: 12),
            
            // Cash on Delivery Option
            _buildPaymentOption(
              value: 'cod',
              title: 'Cash on Delivery',
              subtitle: 'Pay when your order is delivered',
              icon: Icons.money,
              color: Colors.green,
              features: ['No Advance Payment', 'Pay on Delivery'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 64,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Login Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please login to your account to continue with checkout',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to login screen
                Navigator.of(context).pushNamed('/login');
              },
              icon: const Icon(Icons.login, size: 18),
              label: const Text(
                'Go to Login',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoCartButton(CartProvider cartProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.science,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Testing Tools',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            if (cartProvider.isEmpty)
              ElevatedButton.icon(
                onPressed: () async {
                  await cartProvider.createDemoCart();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demo cart created! Now you can test checkout.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Create Demo Cart for Testing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Cart has ${cartProvider.itemCount} items. Ready for checkout!',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> features,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? color.withValues(alpha: 0.05) : Colors.transparent,
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedPaymentMethod = newValue;
            });
          }
        },
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? color : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: features.map((feature) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        activeColor: color,
      ),
    );
  }

  Widget _buildBottomBar(CartProvider cartProvider) {
    final authProvider = context.read<AuthProvider>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessingPayment ? null : () {
              if (!authProvider.isAuthenticated) {
                _showErrorSnackBar('Please login to place an order');
                return;
              }
              
              if (_selectedPaymentMethod == 'online') {
                _openRazorpayCheckout();
              } else {
                _openRazorpayCheckout(); // This will create order first
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isProcessingPayment
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.security, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedPaymentMethod == 'online' 
                          ? 'Pay Now ₹${cartProvider.subtotal.toStringAsFixed(2)}'
                          : 'Place Order ₹${cartProvider.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}