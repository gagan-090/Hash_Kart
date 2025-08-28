import 'package:flutter/material.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({super.key});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final String _orderNumber = 'ORD-123456789';
  final String _trackingNumber = 'TRK-987654321';
  final double _orderTotal = 51997.00;
  final String _estimatedDelivery = 'Dec 28, 2024';
  
  final List<TrackingStep> _trackingSteps = [
    TrackingStep(
      title: 'Order Placed',
      description: 'Your order has been placed successfully',
      time: 'Dec 20, 2024 - 2:30 PM',
      isCompleted: true,
      isActive: false,
      icon: Icons.shopping_cart,
    ),
    TrackingStep(
      title: 'Order Confirmed',
      description: 'Seller has confirmed your order',
      time: 'Dec 20, 2024 - 3:15 PM',
      isCompleted: true,
      isActive: false,
      icon: Icons.check_circle,
    ),
    TrackingStep(
      title: 'Processing',
      description: 'Your order is being prepared for shipment',
      time: 'Dec 21, 2024 - 10:00 AM',
      isCompleted: true,
      isActive: false,
      icon: Icons.inventory,
    ),
    TrackingStep(
      title: 'Shipped',
      description: 'Your order has been shipped',
      time: 'Dec 22, 2024 - 4:45 PM',
      isCompleted: true,
      isActive: true,
      icon: Icons.local_shipping,
    ),
    TrackingStep(
      title: 'Out for Delivery',
      description: 'Your order is out for delivery',
      time: 'Expected: Dec 28, 2024',
      isCompleted: false,
      isActive: false,
      icon: Icons.delivery_dining,
    ),
    TrackingStep(
      title: 'Delivered',
      description: 'Your order has been delivered',
      time: 'Expected: Dec 28, 2024',
      isCompleted: false,
      isActive: false,
      icon: Icons.home,
    ),
  ];

  final List<OrderItem> _orderItems = [
    OrderItem(
      name: 'Wireless Headphones',
      brand: 'Sony',
      quantity: 1,
      price: 7999.00,
      imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=300',
    ),
    OrderItem(
      name: 'Smart Watch',
      brand: 'Apple',
      quantity: 2,
      price: 15999.00,
      imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=300',
    ),
    OrderItem(
      name: 'Laptop Backpack',
      brand: 'Targus',
      quantity: 1,
      price: 3999.00,
      imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=300',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Track Order',
          style: AppTheme.heading3.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.textPrimary),
            onPressed: () {
              // Share tracking details
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Order Info Card
            _buildOrderInfoCard(),
            
            // Current Status Card
            _buildCurrentStatusCard(),
            
            // Tracking Timeline
            _buildTrackingTimeline(),
            
            // Order Items
            _buildOrderItems(),
            
            // Delivery Address
            _buildDeliveryAddress(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Number',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _orderNumber,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Amount',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs.${_orderTotal.toStringAsFixed(2)}',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tracking Number',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _trackingNumber,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Expected Delivery',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _estimatedDelivery,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    final currentStep = _trackingSteps.firstWhere((step) => step.isActive);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              currentStep.icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Status',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentStep.title,
                  style: AppTheme.heading3.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentStep.description,
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Timeline',
            style: AppTheme.heading3.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ...List.generate(_trackingSteps.length, (index) {
            final step = _trackingSteps[index];
            final isLast = index == _trackingSteps.length - 1;
            
            return _buildTimelineStep(step, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(TrackingStep step, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: step.isCompleted 
                    ? AppTheme.primaryColor 
                    : step.isActive 
                        ? AppTheme.secondaryColor 
                        : AppTheme.borderColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                step.icon,
                color: step.isCompleted || step.isActive 
                    ? Colors.white 
                    : AppTheme.textLight,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: step.isCompleted 
                    ? AppTheme.primaryColor 
                    : AppTheme.borderColor,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: step.isCompleted || step.isActive 
                        ? AppTheme.textPrimary 
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.time,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textLight,
                  ),
                ),
                if (!isLast) const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItems() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items (${_orderItems.length})',
            style: AppTheme.heading3.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ...List.generate(_orderItems.length, (index) {
            final item = _orderItems[index];
            return _buildOrderItemCard(item);
          }),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.grey[100],
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.image, color: AppTheme.primaryColor),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.brand,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Rs.${item.price.toStringAsFixed(2)}',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Qty: ${item.quantity}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Address',
            style: AppTheme.heading3.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rajesh Kumar',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+91 98765 43210',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '123 MG Road, Sector 15, Mumbai, Maharashtra 400001',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Contact Seller',
                onPressed: () => NavigationHelper.goToCustomerService(),
                isOutlined: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Order Details',
                onPressed: () => NavigationHelper.goToOrderDetails(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data Models
class TrackingStep {
  final String title;
  final String description;
  final String time;
  final bool isCompleted;
  final bool isActive;
  final IconData icon;

  TrackingStep({
    required this.title,
    required this.description,
    required this.time,
    required this.isCompleted,
    required this.isActive,
    required this.icon,
  });
}

class OrderItem {
  final String name;
  final String brand;
  final int quantity;
  final double price;
  final String imageUrl;

  OrderItem({
    required this.name,
    required this.brand,
    required this.quantity,
    required this.price,
    required this.imageUrl,
  });
}
