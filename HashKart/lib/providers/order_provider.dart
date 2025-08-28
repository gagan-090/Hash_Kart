import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Orders
  List<Order> _orders = [];
  List<Order> _vendorOrders = [];
  Order? _selectedOrder;
  
  // Order statistics
  Map<String, dynamic> _orderStats = {
    'total_orders': 0,
    'pending_orders': 0,
    'processing_orders': 0,
    'shipped_orders': 0,
    'delivered_orders': 0,
    'cancelled_orders': 0,
    'total_revenue': 0.0,
  };
  
  // Returns
  List<Map<String, dynamic>> _returns = [];
  Map<String, dynamic>? _selectedReturn;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalOrders = 0;
  int _pageSize = 20;
  
  // Loading states
  bool _isLoading = false;
  bool _isLoadingOrder = false;
  bool _isProcessing = false;
  
  // Error handling
  String? _error;
  
  // Filters
  String? _statusFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'created_at';
  bool _sortDescending = true;

  // Getters
  List<Order> get orders => _orders;
  List<Order> get vendorOrders => _vendorOrders;
  Order? get selectedOrder => _selectedOrder;
  Map<String, dynamic> get orderStats => _orderStats;
  List<Map<String, dynamic>> get returns => _returns;
  Map<String, dynamic>? get selectedReturn => _selectedReturn;
  bool get isLoading => _isLoading;
  bool get isLoadingOrder => _isLoadingOrder;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalOrders => _totalOrders;
  
  // ========== ORDER FETCHING ==========
  
  Future<void> fetchOrders({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _orders.clear();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final params = <String, String>{
        'page': _currentPage.toString(),
        'page_size': _pageSize.toString(),
        'ordering': '${_sortDescending ? '-' : ''}$_sortBy',
      };
      
      if (_statusFilter != null) params['status'] = _statusFilter!;
      if (_startDate != null) {
        params['created_after'] = _startDate!.toIso8601String();
      }
      if (_endDate != null) {
        params['created_before'] = _endDate!.toIso8601String();
      }
      
      final response = await _apiService.getOrdersMap(params);
      
      final List<dynamic> results = response['results'] ?? [];
      final List<Order> newOrders = results
          .map((json) => Order.fromJson(json))
          .toList();

      if (refresh) {
        _orders = newOrders;
      } else {
        _orders.addAll(newOrders);
      }

      _totalOrders = response['count'] ?? 0;
      _totalPages = ((response['count'] ?? 0) / _pageSize).ceil();
      
      // Update statistics
      await _updateOrderStats();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchOrderById(String orderId) async {
    _isLoadingOrder = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getOrderById(orderId);
      _selectedOrder = Order.fromJson(response);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoadingOrder = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchVendorOrders({bool refresh = false}) async {
    if (refresh) {
      _vendorOrders.clear();
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getVendorOrders();
      final List<dynamic> results = response['results'] ?? response;
      _vendorOrders = results
          .map((json) => Order.fromJson(json))
          .toList();
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // ========== ORDER ACTIONS ==========
  
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();
    
    try {
      debugPrint('🔄 OrderProvider: Cancelling order $orderId...');
      
      final data = {'reason': reason ?? 'Customer requested cancellation'};
      final response = await _apiService.cancelOrder(orderId, data);
      
      debugPrint('🔍 OrderProvider: Cancel order response: $response');
      
      // Check if the response indicates success
      if (response['success'] == true || response['message']?.toString().toLowerCase().contains('cancelled') == true) {
        debugPrint('✅ OrderProvider: Order cancelled successfully');
        
        // Update order in list
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _orders[index] = _orders[index].copyWith(status: 'cancelled');
        }
        
        // Update selected order if it's the same
        if (_selectedOrder?.id == orderId) {
          _selectedOrder = _selectedOrder!.copyWith(status: 'cancelled');
        }
        
        // Refresh order stats
        await _updateOrderStats();
        
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to cancel order';
        debugPrint('❌ OrderProvider: Order cancellation failed: $_error');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ OrderProvider: Error cancelling order: $e');
      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateOrderStatus(String orderId, String status, {String? notes}) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = {
        'status': status,
        if (notes != null) 'notes': notes,
      };
      
      await _apiService.updateOrderStatus(orderId, data);
      
      // Update order in list
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: status);
      }
      
      // Update vendor orders
      final vendorIndex = _vendorOrders.indexWhere((o) => o.id == orderId);
      if (vendorIndex != -1) {
        _vendorOrders[vendorIndex] = _vendorOrders[vendorIndex].copyWith(status: status);
      }
      
      // Update selected order if it's the same
      if (_selectedOrder?.id == orderId) {
        _selectedOrder = _selectedOrder!.copyWith(status: status);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> trackOrder(String orderId) async {
    try {
      final response = await _apiService.trackOrder(orderId);
      return response;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ========== RETURNS MANAGEMENT ==========
  
  Future<void> fetchReturns() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getReturns();
      _returns = List<Map<String, dynamic>>.from(response['results'] ?? response);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> requestReturn(String orderId, Map<String, dynamic> returnData) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();
    
    try {
      returnData['order'] = orderId;
      await _apiService.requestReturn(returnData);
      
      // Refresh returns list
      await fetchReturns();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateReturnStatus(String returnId, String status, {String? notes}) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = {
        'status': status,
        if (notes != null) 'notes': notes,
      };
      
      await _apiService.updateReturnStatus(returnId, data);
      
      // Refresh returns list
      await fetchReturns();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  // ========== INVOICE GENERATION ==========
  
  Future<String?> generateInvoice(String orderId) async {
    try {
      final response = await _apiService.generateInvoice(orderId);
      return response['url'] ?? response['invoice_url'];
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  Future<bool> downloadInvoice(String orderId) async {
    try {
      await _apiService.downloadInvoice(orderId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // ========== FILTERS AND SORTING ==========
  
  void setStatusFilter(String? status) {
    _statusFilter = status;
    fetchOrders(refresh: true);
  }
  
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    fetchOrders(refresh: true);
  }
  
  void setSortBy(String sortField, {bool descending = true}) {
    _sortBy = sortField;
    _sortDescending = descending;
    fetchOrders(refresh: true);
  }
  
  void clearFilters() {
    _statusFilter = null;
    _startDate = null;
    _endDate = null;
    _sortBy = 'created_at';
    _sortDescending = true;
    fetchOrders(refresh: true);
  }
  
  // ========== STATISTICS ==========
  
  Future<void> _updateOrderStats() async {
    try {
      final stats = {
        'total_orders': _orders.length,
        'pending_orders': _orders.where((o) => o.status == 'pending').length,
        'processing_orders': _orders.where((o) => o.status == 'processing').length,
        'shipped_orders': _orders.where((o) => o.status == 'shipped').length,
        'delivered_orders': _orders.where((o) => o.status == 'delivered').length,
        'cancelled_orders': _orders.where((o) => o.status == 'cancelled').length,
        'total_revenue': _orders
            .where((o) => o.status == 'delivered')
            .fold(0.0, (sum, order) => sum + order.total),
      };
      
      _orderStats = stats;
      notifyListeners();
    } catch (e) {
      print('Error updating order stats: $e');
    }
  }
  
  Future<Map<String, dynamic>> fetchOrderAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, String>{};
      
      if (startDate != null) {
        params['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        params['end_date'] = endDate.toIso8601String();
      }
      
      final response = await _apiService.getOrderAnalytics(params);
      return response;
    } catch (e) {
      print('Error fetching order analytics: $e');
      return {};
    }
  }
  

  
  // ========== HELPER METHODS ==========
  
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_currentPage >= _totalPages) return;
    
    _currentPage++;
    await fetchOrders();
  }


  
  // Legacy methods for backward compatibility
  Future<void> loadOrders() => fetchOrders(refresh: true);
}

