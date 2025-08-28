import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/payment/indian_payment_form.dart';
import '../../core/services/razorpay_payment_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'online';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Initialize payment provider when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      paymentProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.cartItems.isEmpty) {
            return const Center(
              child: Text('Your cart is empty'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Order Summary
                _buildOrderSummary(cartProvider),
                const SizedBox(height: 24),

                // Payment Method Selection
                _buildPaymentMethodSelection(),
                const SizedBox(height: 24),

                // Payment Form (if online payment selected)
                if (_selectedPaymentMethod == 'online') ...[
                  _buildPaymentForm(cartProvider),
                  const SizedBox(height: 24),
                ],

                // Place Order Button
                _buildPlaceOrderButton(cartProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    final subtotal = cartProvider.subtotal;
    final tax = subtotal * 0.18; // 18% GST
    final deliveryCharge = 50.0; // Fixed delivery charge
    final total = subtotal + tax + deliveryCharge;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Items count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('Items (${cartProvider.cartItems.length})'),
                ),
                Text('₹${subtotal.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            
            // Tax
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Text('GST (18%)')),
                Text('₹${tax.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            
            // Delivery charge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Text('Delivery Charge')),
                Text('₹${deliveryCharge.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Total',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Online Payment Option
            RadioListTile<String>(
              value: 'online',
              groupValue: _selectedPaymentMethod,
              onChanged: (String? value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              title: const Row(
                children: [
                  Icon(Icons.payment, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(child: Text('Online Payment')),
                ],
              ),
              subtitle: const Text('Credit/Debit Cards, UPI, Net Banking, Wallets'),
            ),
            
            // Cash on Delivery Option
            RadioListTile<String>(
              value: 'cod',
              groupValue: _selectedPaymentMethod,
              onChanged: (String? value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              title: const Row(
                children: [
                  Icon(Icons.money, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(child: Text('Cash on Delivery')),
                ],
              ),
              subtitle: const Text('Pay when you receive your order'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm(CartProvider cartProvider) {
    final total = cartProvider.subtotal + (cartProvider.subtotal * 0.18) + 50.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            IndianPaymentForm(
              amount: total,
              currency: 'INR',
              customerEmail: 'customer@example.com', // Replace with actual user email
              customerPhone: '+919876543210', // Replace with actual user phone
              customerName: 'John Doe', // Replace with actual user name
              orderId: 'ORD${DateTime.now().millisecondsSinceEpoch}',
              onPaymentComplete: (result) {
                _handlePaymentComplete(result);
              },
              notes: {
                'source': 'mobile_app',
                'cart_items_count': cartProvider.cartItems.length.toString(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceOrderButton(CartProvider cartProvider) {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _placeOrder,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      child: _isProcessing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_checkout, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _selectedPaymentMethod == 'online' 
                      ? 'Proceed to Payment'
                      : 'Place Order',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _placeOrder() async {
    if (_selectedPaymentMethod == 'cod') {
      // Handle Cash on Delivery order
      _processCODOrder();
    } else {
      // For online payment, the payment form will handle the flow
      // Just show a message that payment is required
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the payment to place your order'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _processCODOrder() {
    setState(() {
      _isProcessing = true;
    });

    // Simulate order processing
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isProcessing = false;
      });

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order Placed Successfully!'),
          content: const Text(
            'Your order has been placed successfully. You will receive a confirmation email shortly. Pay when you receive your order.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to order confirmation or home
                Navigator.of(context).pushReplacementNamed('/home');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  void _handlePaymentComplete(PaymentResult result) {
    if (result.success) {
      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Successful!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your payment has been processed successfully.'),
              if (result.transactionId != null) ...[
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    'Transaction ID: ${result.transactionId}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text('Your order will be processed and shipped soon.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to order confirmation or home
                Navigator.of(context).pushReplacementNamed('/home');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Show error dialog with better error handling
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Failed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message),
              const SizedBox(height: 8),
              const Text(
                'Please check your payment details and try again. If the problem persists, contact support.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Retry payment
                _retryPayment();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  void _retryPayment() {
    // Reset payment state and allow retry
    setState(() {
      _isProcessing = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please try the payment again'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
