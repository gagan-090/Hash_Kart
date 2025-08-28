import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/date_utils.dart' as date_utils;

class OrderSuccessScreen extends StatefulWidget {
  final String? paymentId;
  final double? amount;
  final String? orderId;
  final String? paymentMethod;
  final String? paymentStatus;
  
  const OrderSuccessScreen({
    super.key,
    this.paymentId,
    this.amount,
    this.orderId,
    this.paymentMethod,
    this.paymentStatus,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> with TickerProviderStateMixin {
  Order? _order;
  bool _isLoading = true;
  String? _error;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadOrderDetails();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    if (widget.orderId != null) {
      try {
        final orderProvider = context.read<OrderProvider>();
        await orderProvider.fetchOrderById(widget.orderId!);
        _order = orderProvider.selectedOrder;
      } catch (e) {
        setState(() {
          _error = 'Failed to load order details: $e';
        });
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorWidget()
              : _buildSuccessContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Order Success',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFF8B5CF6),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading order details...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Error Loading Order',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[400],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOrderDetails,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessContent() {
    final order = _order;
    final orderNumber = order?.orderNumber ?? widget.orderId ?? 'ORD${DateTime.now().millisecondsSinceEpoch}';
    final paymentMethod = _getPaymentMethod();
    final paymentStatus = _getPaymentStatus();
    final totalAmount = order?.totalAmount ?? widget.amount ?? 0.0;
    final orderStatus = _getOrderStatus();
    final orderDate = order?.createdAt ?? DateTime.now();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Success Header with Animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Order Placed Successfully!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Thank you for your purchase. We\'ll send you updates on your order status.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Order Details Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              color: Color(0xFF8B5CF6),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Order Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildDetailRow('Order Number', orderNumber, Icons.tag),
                      _buildDetailRow('Order Date', _formatDate(orderDate), Icons.calendar_today),
                      _buildDetailRow('Payment Method', _formatPaymentMethod(paymentMethod), Icons.payment),
                      
                      // Only show Payment Status for online payments
                      if (paymentMethod.toLowerCase() != 'cod') ...[
                        _buildDetailRow('Payment Status', _formatPaymentStatus(paymentStatus), Icons.account_balance_wallet),
                      ],
                      
                      _buildDetailRow('Order Status', _formatOrderStatus(orderStatus), Icons.local_shipping),
                      _buildDetailRow('Total Amount', '₹${totalAmount.toStringAsFixed(2)}', Icons.attach_money),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Next Steps Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.info,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'What\'s Next?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getNextStepsMessage(paymentMethod, paymentStatus),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF374151),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6),
                          width: 2,
                        ),
                      ),
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/orders'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: Colors.transparent,
                          foregroundColor: const Color(0xFF8B5CF6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide.none,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.list_alt, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'View All Orders',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_bag, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Continue Shopping',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethod() {
    // Priority: Order data > Widget parameter > Default
    if (_order?.paymentMethod != null) {
      return _order!.paymentMethod!;
    }
    if (widget.paymentMethod != null) {
      return widget.paymentMethod!;
    }
    // Default based on payment ID presence
    return widget.paymentId != null ? 'razorpay' : 'cod';
  }

  String _getPaymentStatus() {
    final paymentMethod = _getPaymentMethod();
    
    // For COD, no payment status
    if (paymentMethod.toLowerCase() == 'cod') {
      return 'not_applicable';
    }
    
    // For online payments, check if payment was successful
    if (widget.paymentId != null && widget.paymentId!.isNotEmpty) {
      return 'completed';
    }
    
    // Default to pending for online payments
    return 'pending';
  }

  String _getOrderStatus() {
    final paymentMethod = _getPaymentMethod();
    final paymentStatus = _getPaymentStatus();
    
    // For COD, order is confirmed
    if (paymentMethod.toLowerCase() == 'cod') {
      return 'confirmed';
    }
    
    // For online payments, check payment status
    if (paymentStatus == 'completed') {
      return 'confirmed';
    } else if (paymentStatus == 'pending') {
      return 'pending_payment';
    }
    
    return 'pending';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cod':
        return 'Cash on Delivery';
      case 'razorpay':
        return 'Online Payment (Razorpay)';
      case 'card':
        return 'Credit/Debit Card';
      case 'upi':
        return 'UPI Payment';
      case 'netbanking':
        return 'Net Banking';
      case 'wallet':
        return 'Digital Wallet';
      default:
        return method;
    }
  }

  String _formatPaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Payment Successful';
      case 'pending':
        return 'Payment Pending';
      case 'failed':
        return 'Payment Failed';
      case 'refunded':
        return 'Payment Refunded';
      case 'not_applicable':
        return 'N/A';
      default:
        return status;
    }
  }

  String _formatOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Order Confirmed';
      case 'pending_payment':
        return 'Awaiting Payment';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Order Confirmed';
    }
  }

  String _getNextStepsMessage(String paymentMethod, String paymentStatus) {
    if (paymentMethod.toLowerCase() == 'cod') {
      return 'Your order has been confirmed and is being processed. You\'ll receive updates on your order status. Payment will be collected upon delivery.';
    } else if (paymentMethod.toLowerCase() == 'razorpay') {
      if (paymentStatus.toLowerCase() == 'completed') {
        return 'Payment completed successfully! Your order is being processed and you\'ll receive updates on shipping.';
      } else if (paymentStatus.toLowerCase() == 'pending') {
        return 'Your payment is being processed. You\'ll receive confirmation once the payment is completed.';
      } else {
        return 'Payment verification in progress. You\'ll receive updates on your order status.';
      }
    }
    return 'Your order is being processed. You\'ll receive updates on your order status.';
  }
}
