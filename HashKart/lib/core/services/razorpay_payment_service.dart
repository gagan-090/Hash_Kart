import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../constants/razorpay_constants.dart';

class RazorpayPaymentService {
  static Razorpay? _razorpay;
  
  // Initialize Razorpay
  static Future<void> initialize() async {
    try {
      if (_razorpay != null) {
        // Already initialized
        return;
      }
      
      _razorpay = Razorpay();
      _setupEventHandlers();
      
      // Test if Razorpay is working
      print('✅ Razorpay initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Razorpay: $e');
      rethrow;
    }
  }

  // Setup event handlers
  static void _setupEventHandlers() {
    if (_razorpay == null) return;
    
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  // Process payment
  static Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required String customerEmail,
    required String customerPhone,
    required String customerName,
    required String orderId,
    Map<String, dynamic>? notes,
    Map<String, dynamic>? prefill,
  }) async {
    try {
      // Ensure Razorpay is initialized
      if (_razorpay == null) {
        await initialize();
      }
      
      // Validate inputs
      if (amount <= 0) {
        throw Exception('Invalid amount: Amount must be greater than 0');
      }
      
      if (customerEmail.isEmpty || customerPhone.isEmpty || customerName.isEmpty) {
        throw Exception('Invalid customer details: Email, phone, and name are required');
      }
      
      final options = {
        'key': RazorpayConstants.keyId,
        'amount': (amount * 100).round(), // Convert to paise
        'currency': currency.toUpperCase(),
        'name': 'HashKart',
        'description': 'Payment for Order #$orderId',
        'timeout': 180, // 3 minutes
        'prefill': {
          'contact': customerPhone,
          'email': customerEmail,
          'name': customerName,
          ...?prefill,
        },
        'notes': {
          'order_id': orderId,
          'customer_email': customerEmail,
          'customer_phone': customerPhone,
          ...?notes,
        },
        'theme': {
          'color': '#3399cc',
        },
        'modal': {
          'ondismiss': () {
            print('Razorpay modal dismissed');
            // Handle modal dismiss
          },
        },
      };

      print('🚀 Opening Razorpay with options: $options');
      
      // Check if Razorpay instance is valid
      if (_razorpay == null) {
        throw Exception('Razorpay not initialized');
      }
      
      _razorpay!.open(options);
      
      // Return a pending result - actual result will come through event handlers
      return PaymentResult(
        success: false,
        message: 'Payment initiated',
        status: PaymentStatus.pending,
      );
    } catch (e) {
      print('❌ Failed to initiate Razorpay payment: $e');
      return PaymentResult(
        success: false,
        message: 'Failed to initiate payment: $e',
        status: PaymentStatus.failed,
      );
    }
  }

  // Handle payment success
  static void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final result = PaymentResult(
      success: true,
      transactionId: response.paymentId,
      message: 'Payment successful',
      status: PaymentStatus.success,
      data: {
        'paymentId': response.paymentId,
        'orderId': response.orderId,
        'signature': response.signature,
      },
    );
    
    // You can emit this result through a stream or callback
    _onPaymentResult?.call(result);
  }

  // Handle payment error
  static void _handlePaymentError(PaymentFailureResponse response) {
    final result = PaymentResult(
      success: false,
      message: 'Payment failed: ${response.message ?? 'Unknown error'}',
      status: PaymentStatus.failed,
      data: {
        'code': response.code,
        'message': response.message,
      },
    );
    
    _onPaymentResult?.call(result);
  }

  // Handle external wallet
  static void _handleExternalWallet(ExternalWalletResponse response) {
    final result = PaymentResult(
      success: false,
      message: 'External wallet selected: ${response.walletName}',
      status: PaymentStatus.pending,
      data: {
        'walletName': response.walletName,
      },
    );
    
    _onPaymentResult?.call(result);
  }

  // Callback for payment results
  static Function(PaymentResult)? _onPaymentResult;
  
  // Set payment result callback
  static void setPaymentResultCallback(Function(PaymentResult) callback) {
    _onPaymentResult = callback;
  }

  // Verify payment signature (for security)
  static bool verifyPaymentSignature({
    required String orderId,
    required String paymentId,
    required String signature,
  }) {
    try {
      // This should be done on your backend for security
      // For now, we'll return true (implement proper verification)
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get supported payment methods
  static List<String> getSupportedPaymentMethods() {
    return [
      'cards',
      'netbanking',
      'wallet',
      'upi',
      'emi',
      'paylater',
    ];
  }

  // Get supported card networks
  static List<String> getSupportedCardNetworks() {
    return [
      'visa',
      'mastercard',
      'rupay',
      'amex',
      'discover',
    ];
  }

  // Get supported UPI apps
  static List<String> getSupportedUpiApps() {
    return [
      'google_pay',
      'phonepe',
      'paytm',
      'bhim',
      'amazon_pay',
    ];
  }

  // Get supported wallets
  static List<String> getSupportedWallets() {
    return [
      'paytm',
      'phonepe',
      'amazon_pay',
      'mobikwik',
      'freecharge',
    ];
  }

  // Get supported net banking banks
  static List<String> getSupportedNetBankingBanks() {
    return [
      'HDFC',
      'ICICI',
      'SBI',
      'Axis',
      'Kotak',
      'Yes Bank',
      'Federal Bank',
      'IDBI',
      'PNB',
      'Canara Bank',
    ];
  }

  // Dispose resources
  static void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _onPaymentResult = null;
  }
}

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String message;
  final PaymentStatus status;
  final Map<String, dynamic>? data;

  PaymentResult({
    required this.success,
    this.transactionId,
    required this.message,
    required this.status,
    this.data,
  });
}

enum PaymentStatus {
  pending,
  success,
  failed,
  cancelled,
}
