import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import '../../models/payment_model.dart';
import '../../theme/app_theme.dart';
import '../../core/constants/api_constants.dart';

class PaymentDemoScreen extends StatefulWidget {
  const PaymentDemoScreen({super.key});

  @override
  State<PaymentDemoScreen> createState() => _PaymentDemoScreenState();
}

class _PaymentDemoScreenState extends State<PaymentDemoScreen> {
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _statusMessage = '';
  List<PaymentMethod> _paymentMethods = [];
  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    try {
      final isAuth = await _authService.isAuthenticated();
      final userData = await _authService.getUserData();

      setState(() {
        _isAuthenticated = isAuth;
        _currentUser = userData;
      });

      if (isAuth) {
        _initializePayment();
      } else {
        setState(() {
          _statusMessage = '🔒 Please login to test payments';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking authentication: $e';
      });
    }
  }

  Future<String> _createDemoOrder() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/orders/checkout/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'shipping_address_line_1': '123 Demo Street',
          'shipping_city': 'Mumbai',
          'shipping_state': 'Maharashtra',
          'shipping_postal_code': '400001',
          'shipping_country': 'India',
          'shipping_method': 'standard',
          'payment_method': 'razorpay',
          'customer_notes': 'Demo order for payment testing',
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return data['data']['id'];
      } else {
        throw Exception(data['message'] ?? 'Failed to create demo order');
      }
    } catch (e) {
      throw Exception('Error creating demo order: $e');
    }
  }

  void _initializePayment() {
    try {
      debugPrint('Initializing payment service...');
      _paymentService.initializeRazorpay();
      _loadPaymentMethods();

      // Set up payment callbacks
      _paymentService.setPaymentCallbacks(
        onSuccess: (Map<String, dynamic> response) {
          debugPrint('Payment success callback: $response');
          if (!mounted) return;
          setState(() {
            _statusMessage =
                '✅ Payment Successful!\nPayment ID: ${response['razorpay_payment_id']}\nOrder ID: ${response['razorpay_order_id']}';
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Payment successful: ${response['razorpay_payment_id']}'),
                backgroundColor: AppTheme.successColor,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        onError: (Map<String, dynamic> response) {
          debugPrint('Payment error callback: $response');
          if (!mounted) return;
          setState(() {
            _statusMessage =
                '❌ Payment Failed!\nError Code: ${response['code']}\nDescription: ${response['description']}';
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment failed: ${response['description']}'),
                backgroundColor: AppTheme.errorColor,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        onExternalWallet: (Map<String, dynamic> response) {
          debugPrint('External wallet callback: $response');
          if (!mounted) return;
          setState(() {
            _statusMessage = '💳 External Wallet Selected: ${response['external_wallet']}';
            _isLoading = false;
          });
        },
      );
      
      setState(() {
        _statusMessage = '🔧 Payment service initialized successfully';
      });
    } catch (e) {
      debugPrint('Error initializing payment: $e');
      setState(() {
        _statusMessage = '❌ Failed to initialize payment service: $e';
      });
    }
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = _paymentService.getPaymentMethods();
      setState(() {
        _paymentMethods =
            methods.map((method) => PaymentMethod.fromJson(method)).toList();
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading payment methods: $e';
      });
    }
  }

  Future<void> _testRazorpayPayment() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing Razorpay payment...';
    });

    try {
      // Initialize Razorpay first
      _paymentService.initializeRazorpay();
      
      setState(() {
        _statusMessage = 'Creating demo order...';
      });

      // First create a demo order via API
      final demoOrderId = await _createDemoOrder();

      setState(() {
        _statusMessage = 'Creating payment order...';
      });

      // Create payment order
      final paymentOrder = await _paymentService.createPaymentOrder(
        amount: 100.0, // Demo amount ₹100
        currency: 'INR',
        receipt: demoOrderId,
        notes: {
          'order_id': demoOrderId,
          'customer_name': _currentUser?['first_name'] ?? 'Test User',
          'test_payment': 'true',
        },
      );

      if (paymentOrder == null) {
        throw Exception('Failed to create payment order from backend');
      }

      setState(() {
        _statusMessage = 'Opening Razorpay checkout interface...';
      });

      // Process payment with proper error handling
      final success = await _paymentService.processPayment(
        paymentOrder: paymentOrder,
        onComplete: (success, message) {
          if (mounted) {
            setState(() {
              _statusMessage = success 
                ? '✅ Payment completed successfully!' 
                : '❌ Payment failed: ${message ?? 'Unknown error'}';
              _isLoading = false;
            });
          }
        },
      );

      if (!success) {
        throw Exception('Failed to open Razorpay checkout');
      }

    } catch (e) {
      debugPrint('Payment test error: $e');
      setState(() {
        _statusMessage = '❌ Payment Error: $e';
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _testDirectRazorpay() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing direct Razorpay integration...';
    });

    try {
      // Initialize Razorpay
      _paymentService.initializeRazorpay();
      
      // Create a mock payment order for testing
      final mockPaymentOrder = PaymentOrder(
        paymentId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        gatewayOrderId: 'order_test_${DateTime.now().millisecondsSinceEpoch}',
        amount: 10000, // ₹100 in paise
        currency: 'INR',
        orderNumber: 'TEST_ORDER_${DateTime.now().millisecondsSinceEpoch}',
        customerName: _currentUser?['first_name'] ?? 'Test User',
        customerEmail: _currentUser?['email'] ?? 'test@example.com',
        customerPhone: '9876543210',
        paymentMethod: 'razorpay',
      );

      setState(() {
        _statusMessage = 'Opening Razorpay checkout (Direct Test)...';
      });

      // Process payment directly
      final success = await _paymentService.processPayment(
        paymentOrder: mockPaymentOrder,
        onComplete: (success, message) {
          if (mounted) {
            setState(() {
              _statusMessage = success 
                ? '✅ Direct Razorpay test successful!' 
                : '❌ Direct Razorpay test failed: ${message ?? 'Unknown error'}';
              _isLoading = false;
            });
          }
        },
      );

      if (!success) {
        throw Exception('Failed to open Razorpay checkout interface');
      }

    } catch (e) {
      debugPrint('Direct Razorpay test error: $e');
      setState(() {
        _statusMessage = '❌ Direct Test Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testCODPayment() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Processing COD order...';
    });

    try {
      // Create a demo order first
      final demoOrderId = await _createDemoOrder();

      final success = await _paymentService.processCODOrder(demoOrderId);

      setState(() {
        _statusMessage = success
            ? '✅ COD Order placed successfully!'
            : '❌ COD Order failed!';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'COD order placed!' : 'COD order failed!'),
            backgroundColor:
                success ? AppTheme.successColor : AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'COD Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Payment Demo'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isAuthenticated)
            IconButton(
              onPressed: () async {
                await _authService.logout();
                setState(() {
                  _isAuthenticated = false;
                  _currentUser = null;
                  _statusMessage =
                      '🔒 Logged out. Please login to test payments.';
                });
              },
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
        ],
      ),
      body: !_isAuthenticated
          ? _buildLoginRequiredState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Info
                  _buildUserInfoCard(),

                  const SizedBox(height: 16),
                  // Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Status',
                            style: AppTheme.heading3.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _statusMessage.isEmpty
                                ? 'Ready to test payments'
                                : _statusMessage,
                            style: AppTheme.bodyMedium,
                          ),
                          if (_isLoading) ...[
                            const SizedBox(height: 16),
                            const LinearProgressIndicator(),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Methods
                  Text(
                    'Available Payment Methods',
                    style: AppTheme.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_paymentMethods.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Loading payment methods...'),
                      ),
                    )
                  else
                    ..._paymentMethods.map((method) => Card(
                          child: ListTile(
                            leading: Icon(
                              method.id == 'cod'
                                  ? Icons.money
                                  : Icons.credit_card,
                              color: AppTheme.primaryColor,
                            ),
                            title: Text(method.name),
                            subtitle: Text(method.description),
                            trailing: method.enabled
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : const Icon(Icons.cancel, color: Colors.red),
                          ),
                        )),

                  const SizedBox(height: 32),

                  // Test Buttons
                  Text(
                    'Test Payments',
                    style: AppTheme.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Direct Razorpay Test Button (without backend)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testDirectRazorpay,
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Test Direct Razorpay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Razorpay Test Button (with backend)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testRazorpayPayment,
                    icon: const Icon(Icons.payment),
                    label: const Text('Test Razorpay Payment (Full Flow)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // COD Test Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testCODPayment,
                    icon: const Icon(Icons.money),
                    label: const Text('Test COD Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Test Instructions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Test Instructions',
                            style: AppTheme.heading3.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('For Razorpay Testing:'),
                          const SizedBox(height: 8),
                          _buildTestInfo('Card Number', '4111 1111 1111 1111'),
                          _buildTestInfo('CVV', '123'),
                          _buildTestInfo('Expiry', '12/25'),
                          _buildTestInfo('Name', 'Test User'),
                          const SizedBox(height: 12),
                          const Text('For UPI Testing:'),
                          const SizedBox(height: 8),
                          _buildTestInfo('Success UPI', 'success@razorpay'),
                          _buildTestInfo('Failure UPI', 'failure@razorpay'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoginRequiredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Login Required',
              style: AppTheme.heading2.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please login to test payment functionality',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                icon: const Icon(Icons.login),
                label: const Text('Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                icon: const Icon(Icons.person_add),
                label: const Text('Sign Up'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    if (_currentUser == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logged in as',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentUser!['first_name']} ${_currentUser!['last_name']}',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _currentUser!['email'],
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.verified_user,
              color: AppTheme.successColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodySmall.copyWith(
                fontFamily: 'monospace',
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
