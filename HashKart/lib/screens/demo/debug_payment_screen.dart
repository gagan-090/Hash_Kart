import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../core/services/razorpay_payment_service.dart';

class DebugPaymentScreen extends StatefulWidget {
  const DebugPaymentScreen({super.key});

  @override
  State<DebugPaymentScreen> createState() => _DebugPaymentScreenState();
}

class _DebugPaymentScreenState extends State<DebugPaymentScreen> {
  bool _isInitialized = false;
  String _status = 'Not started';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    try {
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      setState(() {
        _status = 'Checking initialization...';
      });
      
      await paymentProvider.initialize();
      
      setState(() {
        _isInitialized = true;
        _status = 'Payment service initialized successfully';
        _error = '';
      });
    } catch (e) {
      setState(() {
        _status = 'Initialization failed';
        _error = e.toString();
      });
    }
  }

  Future<void> _testSimplePayment() async {
    try {
      setState(() {
        _status = 'Testing simple payment...';
        _error = '';
      });

      // Test with minimal data
      final result = await RazorpayPaymentService.processPayment(
        amount: 1.0, // ₹1 test amount
        currency: 'INR',
        customerEmail: 'test@test.com',
        customerPhone: '+919876543210',
        customerName: 'Test User',
        orderId: 'DEBUG${DateTime.now().millisecondsSinceEpoch}',
        notes: {'test': 'true'},
        prefill: {'method': 'upi'},
      );

      setState(() {
        _status = 'Payment result: ${result.message}';
      });

      print('🔍 Debug payment result: $result');
    } catch (e) {
      setState(() {
        _status = 'Payment test failed';
        _error = e.toString();
      });
      print('❌ Debug payment error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Payment'),
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
                    Row(
                      children: [
                        Icon(
                          _isInitialized ? Icons.check_circle : Icons.error,
                          color: _isInitialized ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Service Status',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Status: $_status'),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Test Buttons
            ElevatedButton(
              onPressed: _isInitialized ? _testSimplePayment : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Test Simple Payment (₹1)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _checkInitialization,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Re-check Initialization',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),

            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Debug Instructions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Check if payment service initializes\n'
                      '2. Test with minimal payment data\n'
                      '3. Check console logs for detailed info\n'
                      '4. Use test UPI: success@razorpay',
                      style: TextStyle(color: Colors.blue.shade700),
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
