import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String? orderId;
  const OrderDetailsScreen({super.key, this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      String? orderId = widget.orderId;

      if (orderId == null && args is Map) {
        orderId = args['orderId']?.toString();
      }

      if (orderId == null && args is Map && args['order'] is Map) {
        orderId = (args['order'] as Map)['id']?.toString();
        _order = Map<String, dynamic>.from(args['order'] as Map);
      }

      if (orderId == null) {
        setState(() {
          _loading = false;
          _error = 'No order reference provided.';
        });
        return;
      }

      if (_order == null) {
        final api = ApiService();
        final res = await api.getOrderDetails(orderId);
        _order = (res['data'] is Map)
            ? Map<String, dynamic>.from(res['data'])
            : Map<String, dynamic>.from(res);
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () => _showMoreOptions(),
          ),
        ],
      ),
      body: _loading
          ? _buildLoadingState()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _init,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final order = _order!;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Order Status Header
          _buildOrderStatusHeader(order),
          
          const SizedBox(height: 16),
          
          // Order Status Timeline
          _buildOrderStatusTimeline(order),
          
          const SizedBox(height: 24),
          
          // Content Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Product Section
                _buildProductCard(order),
                const SizedBox(height: 16),
                
                // Delivery Details
                _buildDeliveryCard(order),
                const SizedBox(height: 16),
                
                // Payment Information
                _buildPaymentCard(order),
                const SizedBox(height: 16),
                
                // Order Breakdown
                _buildOrderBreakdownCard(order),
                const SizedBox(height: 24),
                
                // Action Buttons
                _buildActionButtons(order),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getOrderId(Map<String, dynamic> order) {
    return (order['order_number'] ??
            order['orderNumber'] ??
            order['id'] ??
            'ORD123456789')
        .toString();
  }

  String _formatOrderDate(Map<String, dynamic> order) {
    try {
      final dateStr = order['created_at'] ?? order['order_date'] ?? '';
      if (dateStr.isEmpty) return '14 Aug 2024, 10:45 PM';

      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return '14 Aug 2024, 10:45 PM';
    }
  }

  String _getPaymentStatus(Map<String, dynamic> order) {
    final paymentMethod =
        (order['payment_method'] ?? order['paymentMethod'] ?? 'UPI').toString();
    return 'Paid via $paymentMethod';
  }

  Widget _buildProductSection(Map<String, dynamic> order) {
    final items = (order['items'] is List)
        ? List<Map<String, dynamic>>.from(order['items'])
        : <Map<String, dynamic>>[];

    return Column(
      children: [
        if (items.isNotEmpty)
          ...items.map((item) => _buildProductItem(item))
        else
          _buildSampleProduct(),
      ],
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    final name = (item['product_name'] ??
            item['name'] ??
            'Samsung 55-inch 4K Android TV')
        .toString();
    final quantity = (item['quantity'] ?? 1);
    final price = _parseNumber(item['unit_price'] ?? item['price'] ?? 42990.00);

    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.tv, color: Colors.grey),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Quantity: $quantity',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSampleProduct() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.tv, color: Colors.grey),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Samsung 55-inch 4K Android TV',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Quantity: 1',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '₹42,990.00',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliverySection(Map<String, dynamic> order) {
    final address = _getDeliveryAddress(order);
    final deliveryType =
        (order['delivery_type'] ?? 'Standard Delivery').toString();
    final estimatedDelivery = _getEstimatedDelivery(order);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _editDeliveryAddress(order),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.local_shipping_outlined, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              deliveryType,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.schedule_outlined, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              estimatedDelivery,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentSection(Map<String, dynamic> order) {
    final paymentMethod =
        (order['payment_method'] ?? order['paymentMethod'] ?? 'UPI').toString();
    final paymentStatus =
        (order['payment_status'] ?? order['paymentStatus'] ?? 'Paid')
            .toString();
    final transactionId =
        (order['transaction_id'] ?? order['transactionId'] ?? 'TXN23456789')
            .toString();

    return Column(
      children: [
        _buildInfoRowWithIcon(Icons.payment, 'Payment Method', paymentMethod),
        const SizedBox(height: 12),
        _buildInfoRowWithIcon(Icons.check_circle_outline, 'Payment Status', paymentStatus),
        const SizedBox(height: 12),
        _buildInfoRowWithIcon(Icons.receipt, 'Transaction ID', transactionId),
      ],
    );
  }

  Widget _buildOrderBreakdown(Map<String, dynamic> order) {
    final subtotal =
        _parseNumber(order['subtotal'] ?? order['item_total'] ?? 42990.00);
    final tax = _parseNumber(order['tax'] ?? order['tax_amount'] ?? 3509.10);
    final total = subtotal + tax;

    return Column(
      children: [
        _buildInfoRow('Item Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
        const SizedBox(height: 12),
        _buildInfoRow('Taxes & GST', '₹${tax.toStringAsFixed(2)}'),
        const SizedBox(height: 12),
        const Divider(thickness: 1),
        const SizedBox(height: 12),
        _buildInfoRow('Total Amount', '₹${total.toStringAsFixed(2)}', isBold: true),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowWithIcon(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getDeliveryAddress(Map<String, dynamic> order) {
    final address = order['delivery_address'] ?? order['shipping_address'];
    if (address is Map) {
      final street =
          address['street'] ?? address['address_line_1'] ?? '1234 Elm Street';
      final city = address['city'] ?? 'Springfield';
      final state = address['state'] ?? 'IL';
      final zip = address['zip'] ?? address['postal_code'] ?? '62704';
      return '$street, $city, $state $zip';
    }
    return '1234 Elm Street, Springfield, IL 62704';
  }

  String _getEstimatedDelivery(Map<String, dynamic> order) {
    try {
      final deliveryDate =
          order['estimated_delivery'] ?? order['delivery_date'];
      if (deliveryDate != null) {
        final date = DateTime.parse(deliveryDate.toString());
        return 'Estimated by ${DateFormat('dd MMM, hh:mm a').format(date)} - ${DateFormat('hh:mm a').format(date.add(const Duration(hours: 4)))}';
      }
    } catch (_) {}
    return 'Estimated by 18 Aug, 10:00 AM - 2:00 PM';
  }

  double _parseNumber(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }

  void _trackOrder(Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening order tracking...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 16),
          Text(
            'Loading order details...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusHeader(Map<String, dynamic> order) {
    final status = _getOrderStatus(order);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          
          // Status Message
          Text(
            _getStatusMessage(status),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Order ID with copy functionality
          GestureDetector(
            onTap: () => _copyToClipboard(_getOrderId(order)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Order ID: ${_getOrderId(order)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.copy, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          
          // Order Date
          Text(
            _formatOrderDate(order),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          
          // Payment Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              _getPaymentStatus(order),
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusTimeline(Map<String, dynamic> order) {
    final status = _getOrderStatus(order);
    final steps = _getOrderSteps();
    final currentStepIndex = _getCurrentStepIndex(status);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isCompleted = index <= currentStepIndex;
            final isCurrent = index == currentStepIndex;
            final isLast = index == steps.length - 1;
            
            return _buildTimelineStep(
              step['title']!,
              step['subtitle']!,
              step['icon'] as IconData,
              isCompleted,
              isCurrent,
              isLast,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String title, String subtitle, IconData icon, 
      bool isCompleted, bool isCurrent, bool isLast) {
    final color = isCompleted ? Colors.green : Colors.grey.shade300;
    final textColor = isCompleted ? Colors.black87 : Colors.grey.shade600;
    
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent ? Colors.blue : color,
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: isCompleted ? Colors.white : Colors.grey.shade600,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green.shade200 : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> order) {
    return _buildCard(
      title: 'Product Details',
      child: _buildProductSection(order),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> order) {
    return _buildCard(
      title: 'Delivery Details',
      child: _buildDeliverySection(order),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> order) {
    return _buildCard(
      title: 'Payment Information',
      child: _buildPaymentSection(order),
    );
  }

  Widget _buildOrderBreakdownCard(Map<String, dynamic> order) {
    return _buildCard(
      title: 'Order Summary',
      child: _buildOrderBreakdown(order),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> order) {
    final status = _getOrderStatus(order);
    final canCancel = ['pending', 'confirmed', 'processing'].contains(status.toLowerCase());
    
    return Column(
      children: [
        // Primary Action Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _trackOrder(order),
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('Track Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Secondary Actions Row
        Row(
          children: [
            // Cancel Order Button (if applicable)
            if (canCancel)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelOrderDialog(order),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (canCancel) const SizedBox(width: 12),
            
            // Reorder Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _reorderItems(order),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reorder'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods for order status
  String _getOrderStatus(Map<String, dynamic> order) {
    return (order['status'] ?? 'pending').toString().toLowerCase();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'processing':
        return Colors.blue;
      case 'shipped':
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
      case 'processing':
        return Icons.inventory_2;
      case 'shipped':
      case 'in_transit':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Order Placed Successfully!';
      case 'confirmed':
        return 'Order Confirmed!';
      case 'processing':
        return 'Order is Being Processed';
      case 'shipped':
        return 'Order Shipped!';
      case 'in_transit':
        return 'Order is On the Way';
      case 'delivered':
        return 'Order Delivered!';
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return 'Order Placed Successfully!';
    }
  }

  List<Map<String, dynamic>> _getOrderSteps() {
    return [
      {
        'title': 'Order Placed',
        'subtitle': 'We have received your order',
        'icon': Icons.receipt_long,
      },
      {
        'title': 'Order Confirmed',
        'subtitle': 'Your order has been confirmed',
        'icon': Icons.check_circle_outline,
      },
      {
        'title': 'Processing',
        'subtitle': 'We are preparing your order',
        'icon': Icons.inventory_2_outlined,
      },
      {
        'title': 'Shipped',
        'subtitle': 'Your order is on the way',
        'icon': Icons.local_shipping_outlined,
      },
      {
        'title': 'Delivered',
        'subtitle': 'Order delivered successfully',
        'icon': Icons.home_outlined,
      },
    ];
  }

  int _getCurrentStepIndex(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'processing':
        return 2;
      case 'shipped':
      case 'in_transit':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 0;
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Download Invoice'),
              onTap: () {
                Navigator.pop(context);
                _downloadInvoice();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Order'),
              onTap: () {
                Navigator.pop(context);
                _shareOrder();
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Need Help?'),
              onTap: () {
                Navigator.pop(context);
                _contactSupport();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelOrderDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order?'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(Map<String, dynamic> order) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final orderId = order['id']?.toString() ?? widget.orderId;
      if (orderId == null) {
        throw Exception('Order ID not found');
      }

      // Make actual API call to cancel order
      final apiService = ApiService();
      await apiService.cancelOrder(orderId, {
        'reason': 'Customer requested cancellation',
        'cancelled_by': 'customer'
      });
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Refresh order data from backend to get updated status
        await _init();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _reorderItems(Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Items added to cart!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _downloadInvoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading invoice...')),
    );
  }

  void _shareOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing order details...')),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening support chat...')),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $text'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _editDeliveryAddress(Map<String, dynamic> order) async {
    final currentAddress = order['delivery_address'] ?? order['shipping_address'] ?? {};
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddressEditDialog(currentAddress: currentAddress),
    );

    if (result != null) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        final orderId = order['id']?.toString() ?? widget.orderId;
        if (orderId == null) {
          throw Exception('Order ID not found');
        }

        final apiService = ApiService();
        await apiService.updateOrderShippingAddress(orderId, result);
        
        if (mounted) {
          Navigator.pop(context); // Close loading
          await _init(); // Refresh order data
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery address updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update address: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _AddressEditDialog extends StatefulWidget {
  final Map<String, dynamic> currentAddress;

  const _AddressEditDialog({required this.currentAddress});

  @override
  State<_AddressEditDialog> createState() => _AddressEditDialogState();
}

class _AddressEditDialogState extends State<_AddressEditDialog> {
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _streetController = TextEditingController(
      text: widget.currentAddress['street'] ?? 
            widget.currentAddress['address_line_1'] ?? '',
    );
    _cityController = TextEditingController(
      text: widget.currentAddress['city'] ?? '',
    );
    _stateController = TextEditingController(
      text: widget.currentAddress['state'] ?? '',
    );
    _zipController = TextEditingController(
      text: widget.currentAddress['zip'] ?? 
            widget.currentAddress['postal_code'] ?? '',
    );
    _nameController = TextEditingController(
      text: widget.currentAddress['name'] ?? 
            widget.currentAddress['recipient_name'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.currentAddress['phone'] ?? 
            widget.currentAddress['phone_number'] ?? '',
    );
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Delivery Address'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Recipient Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _zipController,
              decoration: const InputDecoration(
                labelText: 'ZIP/Postal Code',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedAddress = {
              'name': _nameController.text.trim(),
              'phone': _phoneController.text.trim(),
              'street': _streetController.text.trim(),
              'city': _cityController.text.trim(),
              'state': _stateController.text.trim(),
              'zip': _zipController.text.trim(),
            };
            Navigator.pop(context, updatedAddress);
          },
          child: const Text('Update Address'),
        ),
      ],
    );
  }
}
