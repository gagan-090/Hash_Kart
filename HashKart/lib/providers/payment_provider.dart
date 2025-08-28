import 'package:flutter/material.dart';
import '../core/services/razorpay_payment_service.dart';
import '../core/models/payment_method.dart';

class PaymentProvider extends ChangeNotifier {
  List<PaymentMethod> _savedPaymentMethods = [];
  PaymentMethod? _selectedPaymentMethod;
  bool _isProcessing = false;
  bool _isInitialized = false;
  String? _lastError;
  PaymentResult? _lastPaymentResult;

  // Getters
  List<PaymentMethod> get savedPaymentMethods => _savedPaymentMethods;
  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod;
  bool get isProcessing => _isProcessing;
  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;
  PaymentResult? get lastPaymentResult => _lastPaymentResult;

  // Initialize payment provider
  Future<void> initialize() async {
    try {
      await RazorpayPaymentService.initialize();
      await _loadSavedPaymentMethods();
      _setupPaymentCallbacks();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to initialize payment service: $e';
      _isInitialized = false;
      notifyListeners();
    }
  }

  // Setup payment callbacks
  void _setupPaymentCallbacks() {
    RazorpayPaymentService.setPaymentResultCallback((result) {
      _lastPaymentResult = result;
      _isProcessing = false;
      
      if (result.success) {
        _lastError = null;
      } else {
        _lastError = result.message;
      }
      
      notifyListeners();
    });
  }

  // Load saved payment methods
  Future<void> _loadSavedPaymentMethods() async {
    try {
      // For now, we'll use mock data since Razorpay doesn't store payment methods
      // In a real app, you'd store these in your backend
      _savedPaymentMethods = [
        PaymentMethod(
          id: '1',
          type: 'upi',
          last4: '1234',
          brand: 'Google Pay',
          holderName: 'John Doe',
          expiryMonth: '',
          expiryYear: '',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        PaymentMethod(
          id: '2',
          type: 'card',
          last4: '5678',
          brand: 'Visa',
          holderName: 'John Doe',
          expiryMonth: '12',
          expiryYear: '25',
          isDefault: false,
          createdAt: DateTime.now(),
        ),
      ];
      
      if (_savedPaymentMethods.isNotEmpty && _selectedPaymentMethod == null) {
        _selectedPaymentMethod = _savedPaymentMethods.firstWhere(
          (method) => method.isDefault,
          orElse: () => _savedPaymentMethods.first,
        );
      }
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to load payment methods: $e';
      notifyListeners();
    }
  }

  // Select payment method
  void selectPaymentMethod(PaymentMethod paymentMethod) {
    _selectedPaymentMethod = paymentMethod;
    notifyListeners();
  }

  // Process payment
  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required String customerEmail,
    required String customerPhone,
    required String customerName,
    required String orderId,
    Map<String, dynamic>? notes,
    Map<String, dynamic>? prefill,
  }) async {
    _isProcessing = true;
    _lastError = null;
    _lastPaymentResult = null;
    notifyListeners();

    try {
      // Validate inputs before processing
      if (amount <= 0) {
        throw Exception('Invalid amount: Amount must be greater than 0');
      }
      
      if (customerEmail.isEmpty || customerPhone.isEmpty || customerName.isEmpty) {
        throw Exception('Invalid customer details: Email, phone, and name are required');
      }
      
      if (orderId.isEmpty) {
        throw Exception('Invalid order ID');
      }

      final result = await RazorpayPaymentService.processPayment(
        amount: amount,
        currency: currency,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        customerName: customerName,
        orderId: orderId,
        notes: notes,
        prefill: prefill,
      );

      return result;
    } catch (e) {
      _lastError = 'Payment failed: $e';
      _isProcessing = false;
      notifyListeners();
      
      print('❌ Payment error in PaymentProvider: $e');
      
      return PaymentResult(
        success: false,
        message: _lastError!,
        status: PaymentStatus.failed,
      );
    }
  }

  // Save new payment method
  Future<bool> savePaymentMethod({
    required String type,
    required String brand,
    required String holderName,
    String? last4,
    String? expiryMonth,
    String? expiryYear,
  }) async {
    try {
      final newPaymentMethod = PaymentMethod(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        last4: last4 ?? '',
        brand: brand,
        holderName: holderName,
        expiryMonth: expiryMonth ?? '',
        expiryYear: expiryYear ?? '',
        isDefault: _savedPaymentMethods.isEmpty,
        createdAt: DateTime.now(),
      );

      _savedPaymentMethods.add(newPaymentMethod);
      
      if (newPaymentMethod.isDefault) {
        _selectedPaymentMethod = newPaymentMethod;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to save payment method: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete payment method
  Future<bool> deletePaymentMethod(String paymentMethodId) async {
    try {
      _savedPaymentMethods.removeWhere((method) => method.id == paymentMethodId);
      
      if (_selectedPaymentMethod?.id == paymentMethodId) {
        _selectedPaymentMethod = _savedPaymentMethods.isNotEmpty 
          ? _savedPaymentMethods.first 
          : null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to delete payment method: $e';
      notifyListeners();
      return false;
    }
  }

  // Set default payment method
  Future<void> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      // Update all methods to not default
      for (int i = 0; i < _savedPaymentMethods.length; i++) {
        _savedPaymentMethods[i] = _savedPaymentMethods[i].copyWith(isDefault: false);
      }

      // Set the selected method as default
      final index = _savedPaymentMethods.indexWhere((method) => method.id == paymentMethodId);
      if (index != -1) {
        _savedPaymentMethods[index] = _savedPaymentMethods[index].copyWith(isDefault: true);
        _selectedPaymentMethod = _savedPaymentMethods[index];
      }

      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to set default payment method: $e';
      notifyListeners();
    }
  }

  // Get supported payment methods
  List<String> getSupportedPaymentMethods() {
    return RazorpayPaymentService.getSupportedPaymentMethods();
  }

  // Get supported UPI apps
  List<String> getSupportedUpiApps() {
    return RazorpayPaymentService.getSupportedUpiApps();
  }

  // Get supported wallets
  List<String> getSupportedWallets() {
    return RazorpayPaymentService.getSupportedWallets();
  }

  // Get supported banks
  List<String> getSupportedBanks() {
    return RazorpayPaymentService.getSupportedNetBankingBanks();
  }

  // Get supported card networks
  List<String> getSupportedCardNetworks() {
    return RazorpayPaymentService.getSupportedCardNetworks();
  }

  // Clear error
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // Clear payment result
  void clearPaymentResult() {
    _lastPaymentResult = null;
    notifyListeners();
  }

  // Dispose resources
  @override
  void dispose() {
    RazorpayPaymentService.dispose();
    super.dispose();
  }
}
