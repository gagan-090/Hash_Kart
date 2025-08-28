import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/order_provider.dart';
import '../../routes/navigation_helper.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with TickerProviderStateMixin {
  Timer? _refreshTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedFilter = 'all';
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _filterOptions = [
    {
      'key': 'all',
      'label': 'All Orders',
      'icon': Icons.list_alt,
      'color': const Color(0xFF6B7280)
    },
    {
      'key': 'pending',
      'label': 'Pending',
      'icon': Icons.schedule,
      'color': const Color(0xFF8B5CF6)
    },
    {
      'key': 'confirmed',
      'label': 'Confirmed',
      'icon': Icons.check_circle_outline,
      'color': const Color(0xFF06B6D4)
    },
    {
      'key': 'processing',
      'label': 'Processing',
      'icon': Icons.hourglass_empty,
      'color': const Color(0xFFF59E0B)
    },
    {
      'key': 'shipped',
      'label': 'Shipped',
      'icon': Icons.local_shipping,
      'color': const Color(0xFF3B82F6)
    },
    {
      'key': 'delivered',
      'label': 'Delivered',
      'icon': Icons.check_circle,
      'color': const Color(0xFF22C55E)
    },
    {
      'key': 'cancelled',
      'label': 'Cancelled',
      'icon': Icons.cancel,
      'color': const Color(0xFFEF4444)
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OrderProvider>();
      provider.fetchOrders(refresh: true);
      _animationController.forward();
      _startAutoRefresh();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        context.read<OrderProvider>().fetchOrders(refresh: true);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<OrderProvider>().loadMore();
    }
  }

  Future<void> _refresh() async {
    await context.read<OrderProvider>().fetchOrders(refresh: true);
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    final provider = context.read<OrderProvider>();
    // Clear existing orders and apply filter
    provider.setStatusFilter(filter == 'all' ? null : filter);
  }

  List<dynamic> _getFilteredOrders(List<dynamic> orders) {
    if (_selectedFilter == 'all') {
      return orders;
    }
    return orders
        .where((order) =>
            order.status.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  int _getFilterCount(String filterKey, List<dynamic> orders) {
    if (filterKey == 'all') {
      return orders.length;
    }
    return orders
        .where((order) => order.status.toLowerCase() == filterKey.toLowerCase())
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildModernAppBar(),
          SliverToBoxAdapter(child: _buildFilterChips()),
          SliverToBoxAdapter(child: _buildOrderStats()),
          _buildOrdersList(),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1F2937),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6B7280)),
            onPressed: _refresh,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 60,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filterOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final filter = _filterOptions[index];
              final isSelected = _selectedFilter == filter['key'];
              final count = _getFilterCount(filter['key'], provider.orders);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter['icon'],
                        size: 16,
                        color: isSelected ? Colors.white : filter['color'],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        filter['label'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : filter['color'],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.2)
                                : filter['color'].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : filter['color'],
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onSelected: (_) => _applyFilter(filter['key']),
                  backgroundColor: Colors.white,
                  selectedColor: filter['color'],
                  checkmarkColor: Colors.white,
                  elevation: isSelected ? 4 : 1,
                  shadowColor: filter['color'].withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? filter['color']
                          : const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderStats() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        final allOrders = provider.orders;
        final filteredOrders = _getFilteredOrders(allOrders);

        // Calculate dynamic stats based on current filter
        final stats = {
          'total_orders': filteredOrders.length,
          'pending_orders': allOrders
              .where((o) => o.status.toLowerCase() == 'pending')
              .length,
          'processing_orders': allOrders
              .where((o) => o.status.toLowerCase() == 'processing')
              .length,
          'shipped_orders': allOrders
              .where((o) => o.status.toLowerCase() == 'shipped')
              .length,
          'delivered_orders': allOrders
              .where((o) => o.status.toLowerCase() == 'delivered')
              .length,
          'cancelled_orders': allOrders
              .where((o) => o.status.toLowerCase() == 'cancelled')
              .length,
          'total_revenue': allOrders
              .where((o) => o.status.toLowerCase() == 'delivered')
              .fold(0.0, (sum, order) => sum + order.totalAmount),
        };

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFDF7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: Color(0xFF059669),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedFilter == 'all'
                        ? 'Order Summary'
                        : '${_formatStatus(_selectedFilter)} Orders',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      _selectedFilter == 'all' ? 'Total Orders' : 'Filtered',
                      stats['total_orders'].toString(),
                      Icons.receipt_long,
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Delivered',
                      stats['delivered_orders'].toString(),
                      Icons.check_circle,
                      const Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFF0284C7),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Total Spent: ₹${(stats['total_revenue'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF0284C7),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.orders.isEmpty) {
          return SliverToBoxAdapter(
            child: SizedBox(
              height: 300,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading your orders...',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (provider.error != null && provider.orders.isEmpty) {
          return SliverToBoxAdapter(child: _buildErrorState(provider.error!));
        }

        // Apply client-side filtering
        final filteredOrders = _getFilteredOrders(provider.orders);

        if (filteredOrders.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= filteredOrders.length) {
                return provider.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink();
              }

              final order = filteredOrders[index];
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _buildModernOrderCard(order),
                ),
              );
            },
            childCount: filteredOrders.length + (provider.isLoading ? 1 : 0),
          ),
        );
      },
    );
  }

  Widget _buildModernOrderCard(order) {
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);

    // Get product names from order items
    String getProductSummary() {
      if (order.items.isEmpty) return 'No items';

      if (order.items.length == 1) {
        return order.items.first.productName;
      } else if (order.items.length <= 3) {
        return order.items.map((item) => item.productName).join(', ');
      } else {
        final firstTwo =
            order.items.take(2).map((item) => item.productName).join(', ');
        return '$firstTwo and ${order.items.length - 2} more';
      }
    }

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/order-details',
          arguments: {'orderId': order.id},
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: statusColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getProductSummary(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order #${order.orderNumber}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy • hh:mm a')
                            .format(order.createdAt),
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _formatStatus(order.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF6B7280),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${order.totalItems} item${order.totalItems == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (order.trackingNumber?.isNotEmpty == true) ...[
                    const Icon(
                      Icons.local_shipping_outlined,
                      color: Color(0xFF3B82F6),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Tracking Available',
                      style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_shouldShowProgressBar(order.status)) ...[
              const SizedBox(height: 12),
              _buildProgressIndicator(order.status),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(String status) {
    final progress = _getStatusProgress(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Order Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: const Color(0xFFE5E7EB),
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(status)),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _selectedFilter != 'all';

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isFiltered ? Icons.filter_list_off : Icons.shopping_bag_outlined,
              size: 48,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isFiltered
                ? 'No ${_formatStatus(_selectedFilter).toLowerCase()} orders'
                : 'No orders yet',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try selecting a different filter or check back later'
                : 'Start shopping to see your orders here',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          if (isFiltered)
            ElevatedButton.icon(
              onPressed: () => _applyFilter('all'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B7280),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.clear_all, size: 20),
              label: const Text('Clear Filter'),
            )
          else
            ElevatedButton.icon(
              onPressed: () => NavigationHelper.goToHome(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.shopping_cart, size: 20),
              label: const Text('Start Shopping'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF8B5CF6);
      case 'confirmed':
        return const Color(0xFF06B6D4);
      case 'processing':
        return const Color(0xFFF59E0B);
      case 'packed':
        return const Color(0xFF10B981);
      case 'shipped':
      case 'in_transit':
        return const Color(0xFF3B82F6);
      case 'out_for_delivery':
        return const Color(0xFF059669);
      case 'delivered':
        return const Color(0xFF22C55E);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'returned':
        return const Color(0xFFF97316);
      case 'refunded':
        return const Color(0xFF84CC16);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.hourglass_empty;
      case 'packed':
        return Icons.inventory_2;
      case 'shipped':
      case 'in_transit':
        return Icons.local_shipping;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'returned':
        return Icons.keyboard_return;
      case 'refunded':
        return Icons.account_balance_wallet;
      default:
        return Icons.receipt_long;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Processing';
      case 'packed':
        return 'Packed';
      case 'shipped':
        return 'Shipped';
      case 'in_transit':
        return 'In Transit';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'returned':
        return 'Returned';
      case 'refunded':
        return 'Refunded';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  bool _shouldShowProgressBar(String status) {
    return !['cancelled', 'returned', 'refunded', 'delivered']
        .contains(status.toLowerCase());
  }

  double _getStatusProgress(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0.2;
      case 'confirmed':
        return 0.4;
      case 'processing':
        return 0.6;
      case 'packed':
        return 0.7;
      case 'shipped':
      case 'in_transit':
        return 0.8;
      case 'out_for_delivery':
        return 0.9;
      case 'delivered':
        return 1.0;
      default:
        return 0.0;
    }
  }
}
