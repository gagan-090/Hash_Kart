import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../core/services/razorpay_payment_service.dart';

class IndianPaymentForm extends StatefulWidget {
  final double amount;
  final String currency;
  final String customerEmail;
  final String customerPhone;
  final String customerName;
  final String orderId;
  final Function(PaymentResult) onPaymentComplete;
  final Map<String, dynamic>? notes;

  const IndianPaymentForm({
    super.key,
    required this.amount,
    this.currency = 'INR',
    required this.customerEmail,
    required this.customerPhone,
    required this.customerName,
    required this.orderId,
    required this.onPaymentComplete,
    this.notes,
  });

  @override
  State<IndianPaymentForm> createState() => _IndianPaymentFormState();
}

class _IndianPaymentFormState extends State<IndianPaymentForm> {
  String _selectedPaymentMethod = 'upi';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Payment method selection
            _buildPaymentMethodSelection(),
            const SizedBox(height: 24),

            // Payment details
            _buildPaymentDetails(),
            const SizedBox(height: 24),

            // Payment button
            _buildPaymentButton(paymentProvider),
            
            // Error display
            if (paymentProvider.lastError != null) ...[
              const SizedBox(height: 16),
              _buildErrorDisplay(paymentProvider.lastError!),
            ],

            // Success display
            if (paymentProvider.lastPaymentResult?.success == true) ...[
              const SizedBox(height: 16),
              _buildSuccessDisplay(paymentProvider.lastPaymentResult!),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Payment Method',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // UPI Option
        _buildPaymentOption(
          value: 'upi',
          title: 'UPI',
          subtitle: 'Google Pay, PhonePe, Paytm, BHIM',
          icon: Icons.phone_android,
          color: Colors.green,
        ),
        
        // Cards Option
        _buildPaymentOption(
          value: 'cards',
          title: 'Credit/Debit Cards',
          subtitle: 'Visa, Mastercard, RuPay, American Express',
          icon: Icons.credit_card,
          color: Colors.blue,
        ),
        
        // Net Banking Option
        _buildPaymentOption(
          value: 'netbanking',
          title: 'Net Banking',
          subtitle: 'HDFC, ICICI, SBI, Axis and more',
          icon: Icons.account_balance,
          color: Colors.orange,
        ),
        
        // Wallets Option
        _buildPaymentOption(
          value: 'wallet',
          title: 'Digital Wallets',
          subtitle: 'Paytm, PhonePe, Amazon Pay, Mobikwik',
          icon: Icons.account_balance_wallet,
          color: Colors.purple,
        ),
        
        // EMI Option
        _buildPaymentOption(
          value: 'emi',
          title: 'EMI',
          subtitle: '3, 6, 9, 12, 18, 24 months',
          icon: Icons.schedule,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                color: color.withOpacity(0.1),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildPaymentDetails() {
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
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Text('Order ID:')),
                Flexible(
                  child: Text(
                    widget.orderId,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Text('Amount:')),
                Text(
                  '₹${widget.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Text('Currency:')),
                Text(
                  widget.currency,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Text('Customer:')),
                Flexible(
                  child: Text(
                    widget.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton(PaymentProvider paymentProvider) {
    return ElevatedButton(
      onPressed: paymentProvider.isProcessing ? null : _processPayment,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      child: paymentProvider.isProcessing
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
                const Icon(Icons.payment, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Pay ₹${widget.amount.toStringAsFixed(2)}',
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

  Widget _buildErrorDisplay(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessDisplay(PaymentResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Successful!',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (result.transactionId != null)
                  Flexible(
                    child: Text(
                      'Transaction ID: ${result.transactionId}',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    
    try {
      // Ensure payment provider is initialized
      if (!paymentProvider.isInitialized) {
        await paymentProvider.initialize();
      }
      
      final result = await paymentProvider.processPayment(
        amount: widget.amount,
        currency: widget.currency,
        customerEmail: widget.customerEmail,
        customerPhone: widget.customerPhone,
        customerName: widget.customerName,
        orderId: widget.orderId,
        notes: {
          'payment_method': _selectedPaymentMethod,
          'customer_phone': widget.customerPhone,
          ...?widget.notes,
        },
        prefill: {
          'method': _selectedPaymentMethod,
        },
      );

      widget.onPaymentComplete(result);
    } catch (e) {
      // Handle any errors
      widget.onPaymentComplete(PaymentResult(
        success: false,
        message: 'Payment failed: $e',
        status: PaymentStatus.failed,
      ));
    }
  }
}
