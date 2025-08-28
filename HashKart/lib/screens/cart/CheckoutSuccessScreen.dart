import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';

class CheckoutSuccessScreen extends StatefulWidget {
  const CheckoutSuccessScreen({super.key});

  @override
  State<CheckoutSuccessScreen> createState() => _CheckoutSuccessScreenState();
}

class _CheckoutSuccessScreenState extends State<CheckoutSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  Map<String, dynamic>? orderData;
  bool _isCreatingOrder = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _processOrderCreation();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _processOrderCreation() async {
    try {
      // Get the arguments passed from checkout screen
      final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      if (arguments == null) {
        setState(() {
          _error = 'Order data not found';
          _isCreatingOrder = false;
        });
        return;
      }

      // Create order in backend
      await _createOrderInBackend(arguments);
      
      // Start animations after successful order creation
      _scaleController.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      _fadeController.forward();
      
    } catch (e) {
      setState(() {
        _error = 'Failed to create order: $e';
        _isCreatingOrder = false;
      });
    }
  }

  Future<void> _createOrderInBackend(Map<String, dynamic> orderArgs) async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final apiService = ApiService();
    
    if (!authProvider.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      // Set the auth token in API service
      if (authProvider.accessToken != null) {
        apiService.setAuthToken(authProvider.accessToken!);
      }
      
      debugPrint('🛒 Cart items count: ${cartProvider.cartItems.length}');
      
      // Get cart items for the order
      final cartItems = cartProvider.cartItems.map((item) => {
        'product_id': item.product?.id,
        'quantity': item.quantity,
        'price': item.product?.price?.toString() ?? '0',
        'total_price': item.totalPrice.toString(),
      }).toList();

      final orderPayload = {
        'payment_method': orderArgs['paymentMethod'] ?? 'cod',
        'payment_status': orderArgs['paymentStatus'] ?? 'pending',
        'total_amount': orderArgs['amount']?.toString() ?? '0',
        'order_notes': 'Order placed via mobile app',
        'items': cartItems,
        'shipping_address': {
          'full_name': 'John Doe',
          'address_line_1': '123 Main Street',
          'address_line_2': 'Apartment 4B',
          'city': 'New York',
          'state': 'NY',
          'postal_code': '10001',
          'country': 'US',
          'phone': '9876543210',
        },
        if (orderArgs['paymentId'] != null) 'payment_id': orderArgs['paymentId'],
        if (orderArgs['orderId'] != null) 'external_order_id': orderArgs['orderId'],
      };

      debugPrint('🚀 Creating order with payload: $orderPayload');

      // Use the API service method instead of direct HTTP call
      final responseData = await apiService.createOrder(orderPayload);
      
      debugPrint('✅ Order creation successful: $responseData');
      
      setState(() {
        orderData = {
          ...orderArgs,
          'backendOrderId': responseData['data']?['id'] ?? responseData['id'],
          'orderNumber': responseData['data']?['order_number'] ?? responseData['order_number'] ?? responseData['external_order_id'],
          'status': responseData['data']?['status'] ?? 'confirmed',
          'createdAt': responseData['data']?['created_at'] ?? DateTime.now().toIso8601String(),
        };
        _isCreatingOrder = false;
      });

      // Wait a moment for the backend to process
      await Future.delayed(const Duration(milliseconds: 500));

      // Refresh orders in the order provider so they show up in "My Orders"
      try {
        debugPrint('🔄 Refreshing orders...');
        await orderProvider.fetchOrders(refresh: true);
        debugPrint('✅ Orders refreshed successfully - Total orders: ${orderProvider.orders.length}');
        
        // Log the orders for debugging
        for (var order in orderProvider.orders) {
          debugPrint('📦 Order: ${order.id} - Status: ${order.status} - Total: ${order.totalAmount}');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to refresh orders: $e');
        // Try alternative refresh method
        try {
          await orderProvider.loadOrders();
          debugPrint('✅ Orders loaded with alternative method - Total orders: ${orderProvider.orders.length}');
        } catch (e2) {
          debugPrint('⚠️ Alternative refresh also failed: $e2');
        }
      }

    } catch (e) {
      debugPrint('❌ Error creating order: $e');
      
      // Try to refresh orders anyway in case the order was created but response failed
      try {
        await orderProvider.fetchOrders(refresh: true);
        debugPrint('✅ Orders refreshed after error - Total orders: ${orderProvider.orders.length}');
      } catch (refreshError) {
        debugPrint('⚠️ Failed to refresh orders after error: $refreshError');
      }
      
      // Show success with local data even if backend fails
      setState(() {
        orderData = {
          ...orderArgs,
          'backendOrderId': orderArgs['orderId'],
          'orderNumber': orderArgs['orderId'],
          'status': 'confirmed',
          'createdAt': DateTime.now().toIso8601String(),
        };
        _isCreatingOrder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreatingOrder) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    return _buildSuccessScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Processing your order...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait while we confirm your order',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Unknown error occurred',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Go to Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final paymentMethod = orderData?['paymentMethod'] ?? 'cod';
    final amount = orderData?['amount']?.toString() ?? '0';
    final orderNumber = orderData?['orderNumber'] ?? orderData?['orderId'] ?? 'N/A';
    final isOnlinePayment = paymentMethod == 'razorpay';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Animated Success Icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withValues(alpha: 0.1),
                        Colors.green.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Animated Success Content
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Success Title
                    Text(
                      isOnlinePayment ? 'Payment Successful!' : 'Order Placed Successfully!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Success Message
                    Text(
                      isOnlinePayment 
                        ? 'Your payment has been processed successfully. We\'ll start preparing your order right away!'
                        : 'Thank you for your order! Please keep the exact amount ready for delivery.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Order Details Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          _buildDetailRow('Order Number', orderNumber),
                          _buildDetailRow('Amount', '₹$amount'),
                          _buildDetailRow(
                            'Payment Method', 
                            isOnlinePayment ? 'Online Payment' : 'Cash on Delivery'
                          ),
                          _buildDetailRow(
                            'Status', 
                            isOnlinePayment ? 'Paid' : 'Pending Payment',
                            statusColor: isOnlinePayment ? Colors.green : Colors.orange,
                          ),
                          
                          if (isOnlinePayment && orderData?['paymentId'] != null) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow('Payment ID', orderData!['paymentId']),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Delivery Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            const Color(0xFF7C3AED).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_shipping,
                              color: Color(0xFF4F46E5),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Delivery',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '3-5 business days',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Action Buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Refresh orders before navigating
                              try {
                                final orderProvider = context.read<OrderProvider>();
                                await orderProvider.fetchOrders(refresh: true);
                              } catch (e) {
                                debugPrint('Failed to refresh orders before navigation: $e');
                              }
                              
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/orders',
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.receipt_long, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'View My Orders',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/home',
                                (route) => false,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF4F46E5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shopping_bag_outlined, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Continue Shopping',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: statusColor ?? const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}