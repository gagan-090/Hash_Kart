import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../models/payment_model.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final ApiService _apiService = ApiService();
  Razorpay? _razorpay;

  // Callback functions
  Function(Map<String, dynamic>)? _onPaymentSuccess;
  Function(Map<String, dynamic>)? _onPaymentError;
  Function(Map<String, dynamic>)? _onExternalWallet;

  // Variables to store pending payment completion
  Function(bool, String?)? _pendingPaymentCompletion;
  PaymentOrder? _pendingPaymentOrder;
  bool _isPaymentInterfaceOpen = false;

  // Payment status tracking
  final StreamController<PaymentStatus> _paymentStatusController =
      StreamController<PaymentStatus>.broadcast();
  Stream<PaymentStatus> get paymentStatusStream =>
      _paymentStatusController.stream;

  void initializeRazorpay() {
    try {
      // Check if we're running on web platform
      bool isWeb = kIsWeb;

      if (isWeb) {
        debugPrint('Running on web platform - Razorpay web integration will be used');
        return;
      }

      debugPrint('Initializing Razorpay plugin for mobile platform');
      debugPrint('Using Razorpay Key ID: ${ApiConstants.razorpayKeyId}');

      // Validate Razorpay configuration
      if (ApiConstants.razorpayKeyId.isEmpty || ApiConstants.razorpayKeyId == 'rzp_test_your_key_id') {
        debugPrint('WARNING: Invalid Razorpay key ID detected');
        throw Exception('Invalid Razorpay configuration. Please set proper credentials.');
      }

      // For mobile platforms, initialize Razorpay plugin
      _razorpay = Razorpay();
      
      // Set up event listeners
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

      debugPrint('Razorpay plugin initialized successfully with key: ${ApiConstants.razorpayKeyId.substring(0, 12)}...');
    } catch (e) {
      debugPrint('Error initializing Razorpay: $e');
      _razorpay = null;
      throw Exception('Failed to initialize Razorpay: $e');
    }
  }

  // Platform detection helper
  bool _isWebPlatform() {
    return kIsWeb;
  }

  void dispose() {
    try {
      // Clean up payment forms
      _cleanupPaymentForms();

      // Close payment status stream
      _paymentStatusController.close();

      // Check if we're running on web platform
      bool isWeb = _isWebPlatform();

      if (isWeb) {
        debugPrint('Running on web platform - no Razorpay plugin to dispose');
        return;
      }

      // For mobile platforms, dispose Razorpay plugin
      _razorpay?.clear();
    } catch (e) {
      debugPrint('Error disposing Razorpay: $e');
    }
  }

  // Set callback functions
  void setPaymentCallbacks({
    Function(Map<String, dynamic>)? onSuccess,
    Function(Map<String, dynamic>)? onError,
    Function(Map<String, dynamic>)? onExternalWallet,
  }) {
    _onPaymentSuccess = onSuccess;
    _onPaymentError = onError;
    _onExternalWallet = onExternalWallet;
  }

  // Handle Razorpay events
  void _handlePaymentSuccess(Map<String, dynamic> response) {
    debugPrint('Payment successful: ${response['razorpay_payment_id']}');

    // Call the success callback if set
    _onPaymentSuccess?.call(response);

    // Complete pending payment if exists
    if (_pendingPaymentCompletion != null) {
      _pendingPaymentCompletion!(true, response['razorpay_payment_id']);

      // Clear pending data
      _pendingPaymentCompletion = null;
      _pendingPaymentOrder = null;
      _isPaymentInterfaceOpen = false;
    }
  }

  void _handlePaymentError(Map<String, dynamic> response) {
    debugPrint('Payment failed: ${response['description']}');

    // Call the error callback if set
    _onPaymentError?.call(response);

    // Complete pending payment with error if exists
    if (_pendingPaymentCompletion != null) {
      _pendingPaymentCompletion!(false, response['description']);

      // Clear pending data
      _pendingPaymentCompletion = null;
      _pendingPaymentOrder = null;
      _isPaymentInterfaceOpen = false;
    }
  }

  void _handleExternalWallet(Map<String, dynamic> response) {
    debugPrint('External wallet selected: ${response['external_wallet']}');

    // Call the external wallet callback if set
    _onExternalWallet?.call(response);
  }

  // Create payment order
  Future<PaymentOrder?> createPaymentOrder({
    required double amount,
    required String currency,
    required String receipt,
    Map<String, dynamic>? notes,
  }) async {
    try {
      debugPrint('Creating payment order...');

      final response = await _apiService.post(
        '/payments/orders/create/',
        {
          'amount': (amount * 100)
              .round(), // Convert to paise (smallest currency unit)
          'currency': currency,
          'receipt': receipt,
          if (notes != null) 'notes': notes,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        final paymentOrder = PaymentOrder.fromJson(response['data']);
        debugPrint('Payment order created successfully: ${paymentOrder.id}');
        return paymentOrder;
      } else {
        debugPrint(
            'Failed to create payment order: ${response['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating payment order: $e');
      return null;
    }
  }

  // Process payment with improved error handling and status tracking
  Future<bool> processPayment({
    required PaymentOrder paymentOrder,
    required Function(bool success, String? message) onComplete,
  }) async {
    try {
      debugPrint('Processing payment for order: ${paymentOrder.id}');
      _paymentStatusController.add(PaymentStatus.processing);

      // Store pending payment completion callback
      _pendingPaymentCompletion = onComplete;
      _pendingPaymentOrder = paymentOrder;

      // Validate payment order
      if (!_validatePaymentOrder(paymentOrder)) {
        throw Exception('Invalid payment order data');
      }

      // Check platform and handle accordingly
      if (_isWebPlatform()) {
        debugPrint('Web platform detected - using web payment flow');
        return await _processWebPaymentImproved(paymentOrder);
      } else {
        debugPrint('Mobile platform detected - using Razorpay plugin');
        return await _processMobilePaymentImproved(paymentOrder);
      }
    } catch (e) {
      debugPrint('Error processing payment: $e');
      _paymentStatusController.add(PaymentStatus.failed);

      // Log error
      debugPrint('Payment failed: ${e.toString()}');

      // Call completion callback with error
      onComplete(false, 'Payment processing failed: $e');

      // Clear pending data
      _pendingPaymentCompletion = null;
      _pendingPaymentOrder = null;

      return false;
    }
  }

  // Verify payment
  Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      debugPrint('Verifying payment...');

      final response = await _apiService.post(
        '/payments/verify-payment/',
        {
          'payment_id': paymentId,
          'order_id': orderId,
          'signature': signature,
        },
      );

      final isValid = response['is_valid'] ?? false;
      debugPrint('Payment verification result: $isValid');
      return isValid;
    } catch (e) {
      debugPrint('Error verifying payment: $e');
      return false;
    }
  }

  // Get payment status
  Future<String?> getPaymentStatus(String paymentId) async {
    try {
      debugPrint('Getting payment status for: $paymentId');

      final response = await _apiService.get('/payments/status/$paymentId/');

      final status = response['status'];
      debugPrint('Payment status: $status');
      return status;
    } catch (e) {
      debugPrint('Error getting payment status: $e');
      return null;
    }
  }

  // Refund payment
  Future<bool> refundPayment({
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    try {
      debugPrint('Processing refund for payment: $paymentId');

      final response = await _apiService.post(
        '/payments/refund/',
        {
          'payment_id': paymentId,
          'amount': (amount * 100).round(), // Convert to paise
          if (reason != null) 'reason': reason,
        },
      );

      final success = response['success'] ?? false;
      debugPrint('Refund processed: $success');
      return success;
    } catch (e) {
      debugPrint('Error processing refund: $e');
      return false;
    }
  }

  // Clean up payment forms (web-specific cleanup removed)
  void _cleanupPaymentForms() {
    try {
      debugPrint('Cleaning up payment forms...');

      // For mobile platforms, reset payment interface state
      if (_isPaymentInterfaceOpen && _razorpay != null) {
        try {
          // Note: Razorpay 1.4.0+ doesn't have close() method
          // The payment interface closes automatically after completion
          _isPaymentInterfaceOpen = false;
          debugPrint('Payment interface state reset');
        } catch (e) {
          debugPrint('Error resetting payment interface: $e');
        }
      }

      debugPrint('Payment forms cleanup completed');
    } catch (e) {
      debugPrint('Error during payment forms cleanup: $e');
    }
  }

  // Get payment methods
  List<Map<String, dynamic>> getPaymentMethods() {
    return [
      {
        'id': 'card',
        'name': 'Credit/Debit Card',
        'icon': '💳',
        'description': 'Pay with your credit or debit card',
      },
      {
        'id': 'upi',
        'name': 'UPI',
        'icon': '📱',
        'description': 'Pay using UPI apps like Google Pay, PhonePe',
      },
      {
        'id': 'netbanking',
        'name': 'Net Banking',
        'icon': '🏦',
        'description': 'Pay using your bank\'s net banking service',
      },
      {
        'id': 'wallet',
        'name': 'Digital Wallet',
        'icon': '👛',
        'description': 'Pay using digital wallets like Paytm, Amazon Pay',
      },
    ];
  }

  // Check if payment is in progress
  bool get isPaymentInProgress => _isPaymentInterfaceOpen;

  // Get pending payment order
  PaymentOrder? get pendingPaymentOrder => _pendingPaymentOrder;

  // Validation helper
  bool _validatePaymentOrder(PaymentOrder paymentOrder) {
    if (paymentOrder.amount == null || paymentOrder.amount! <= 0) {
      debugPrint('Invalid payment amount');
      return false;
    }
    if (paymentOrder.currency == null || paymentOrder.currency!.isEmpty) {
      debugPrint('Invalid currency');
      return false;
    }
    return true;
  }



  // Mobile payment processing
  Future<bool> _processMobilePaymentImproved(PaymentOrder paymentOrder) async {
    try {
      if (_razorpay == null) {
        debugPrint('Razorpay not initialized, initializing now...');
        initializeRazorpay();
        if (_razorpay == null) {
          throw Exception('Failed to initialize Razorpay plugin');
        }
      }

      // Validate Razorpay key
      if (ApiConstants.razorpayKeyId.isEmpty || ApiConstants.razorpayKeyId == 'rzp_test_your_key_id') {
        throw Exception('Invalid Razorpay key ID. Please configure proper Razorpay credentials.');
      }

      final options = {
        'key': ApiConstants.razorpayKeyId,
        'amount': paymentOrder.amount,
        'currency': paymentOrder.currency ?? 'INR',
        'name': ApiConstants.companyName,
        'description': 'Payment for order ${paymentOrder.receipt ?? paymentOrder.id}',
        'order_id': paymentOrder.gatewayOrderId ?? paymentOrder.id,
        'prefill': {
          'contact': paymentOrder.contact ?? '9876543210',
          'email': paymentOrder.email ?? 'test@example.com',
          'name': paymentOrder.name ?? 'Test User',
        },
        'theme': {
          'color': '#3399cc'
        },
        'notes': {
          'order_id': paymentOrder.id,
          'customer_name': paymentOrder.name ?? 'Test User',
        },
        'retry': {
          'enabled': true, 
          'max_count': 3
        },
        'send_sms_hash': true,
        'remember_customer': false,
        'timeout': 300, // 5 minutes
        'modal': {
          'backdropclose': false,
          'escape': true,
          'handleback': true,
          'confirm_close': true,
          'ondismiss': () {
            debugPrint('Razorpay checkout dismissed');
            _isPaymentInterfaceOpen = false;
          }
        }
      };

      debugPrint('Opening Razorpay checkout with key: ${ApiConstants.razorpayKeyId}');
      debugPrint('Payment amount: ${paymentOrder.amount}');
      debugPrint('Order ID: ${paymentOrder.gatewayOrderId ?? paymentOrder.id}');
      
      _isPaymentInterfaceOpen = true;
      _paymentStatusController.add(PaymentStatus.processing);
      
      // Open Razorpay checkout
      _razorpay!.open(options);
      
      debugPrint('Razorpay checkout opened successfully');
      return true;
    } catch (e) {
      debugPrint('Error in mobile payment processing: $e');
      _paymentStatusController.add(PaymentStatus.failed);
      _isPaymentInterfaceOpen = false;
      return false;
    }
  }

  // Web payment processing
  Future<bool> _processWebPaymentImproved(PaymentOrder paymentOrder) async {
    try {
      // For web, we'll redirect to a payment page or use Razorpay web integration
      debugPrint('Processing web payment for order: ${paymentOrder.id}');

      // This is a placeholder - implement actual web payment logic
      debugPrint('Web payment processing not fully implemented yet');

      // Simulate payment success for demo
      await Future.delayed(const Duration(seconds: 2));
      _handlePaymentSuccess({
        'razorpay_payment_id':
            'web_payment_${DateTime.now().millisecondsSinceEpoch}',
        'razorpay_order_id': paymentOrder.gatewayOrderId ?? paymentOrder.id,
        'razorpay_signature': 'web_payment_signature',
      });

      return true;
    } catch (e) {
      debugPrint('Error in web payment processing: $e');
      _paymentStatusController.add(PaymentStatus.failed);
      return false;
    }
  }

  // Additional methods for compatibility
  Future<void> openRazorpayCheckout(PaymentOrder paymentOrder) async {
    await processPayment(
      paymentOrder: paymentOrder,
      onComplete: (success, message) {
        debugPrint('Payment completed: success=$success, message=$message');
        debugPrint(message ?? (success ? 'Payment successful!' : 'Payment failed!'));
      },
    );
  }

  Future<bool> processCODOrder(String orderId) async {
    try {
      _paymentStatusController.add(PaymentStatus.processing);

      final response = await _apiService.post('/payments/cod/', {
        'order_id': orderId,
        'payment_method': 'cod',
      });

      if (response['success'] == true) {
        debugPrint('COD order processed successfully');
        _paymentStatusController.add(PaymentStatus.success);
        debugPrint('COD order placed successfully!');
        return true;
      } else {
        debugPrint('COD order processing failed: ${response['message']}');
        _paymentStatusController.add(PaymentStatus.failed);
        debugPrint('COD order failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('Error processing COD order: $e');
      _paymentStatusController.add(PaymentStatus.failed);
      debugPrint('Error processing COD order: $e');
      return false;
    }
  }
}
