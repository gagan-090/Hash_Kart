import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../core/services/razorpay_payment_service.dart';

class TestPaymentScreen extends StatefulWidget {
  const TestPaymentScreen({super.key});

  @override
  State<TestPaymentScreen> createState() => _TestPaymentScreenState();
}

class _TestPaymentScreenState extends State<TestPaymentScreen> {
  bool _isInitialized = false;
  String _lastError = '';
  String _lastResult = '';

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    try {
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      await paymentProvider.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _lastError = 'Initialization failed: $e';
      });
    }
  }

  Future<void> _testRazorpayPayment() async {
    try {
      setState(() {
        _lastError = '';
        _lastResult = 'Initiating payment...';
      });

      final result = await RazorpayPaymentService.processPayment(
        amount: 100.0, // ₹100 test amount
        currency: 'INR',
        customerEmail: 'test@example.com',
        customerPhone: '+919876543210',
        customerName: 'Test User',
        orderId: 'TEST${DateTime.now().millisecondsSinceEpoch}',
        notes: {
          'source': 'test_screen',
          'test_mode': 'true',
        },
        prefill: {
          'method': 'upi',
        },
      );

      setState(() {
        _lastResult = 'Payment result: ${result.message}';
      });
    } catch (e) {
      setState(() {
        _lastError = 'Payment failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Razorpay Payment'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Service Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          _isInitialized ? Icons.check_circle : Icons.error,
                          color: _isInitialized ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isInitialized ? 'Initialized' : 'Not Initialized',
                          style: TextStyle(
                            color: _isInitialized ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Test Payment Button
            ElevatedButton(
              onPressed: _isInitialized ? _testRazorpayPayment : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Test Razorpay Payment (₹100)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Results Display
            if (_lastResult.isNotEmpty) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Result:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_lastResult),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_lastError.isNotEmpty) ...[
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_lastError),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Instructions
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Test Instructions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Click "Test Razorpay Payment" to open Razorpay\n'
                      '• Use test UPI: success@razorpay\n'
                      '• Or use test card: 4111 1111 1111 1111\n'
                      '• Check console logs for debugging info',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
