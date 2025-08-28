import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/vendor_model.dart';
import '../models/product_model.dart';
import 'dart:io';

class VendorProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Vendor data
  Vendor? _currentVendor;
  List<Vendor> _vendors = [];
  Vendor? _selectedVendor;
  
  // Vendor products
  List<Product> _vendorProducts = [];
  Map<String, dynamic> _productStats = {};
  
  // Analytics
  Map<String, dynamic> _vendorAnalytics = {
    'total_revenue': 0.0,
    'total_orders': 0,
    'total_products': 0,
    'total_customers': 0,
    'pending_orders': 0,
    'average_rating': 0.0,
    'sales_trend': [],
    'top_products': [],
    'recent_orders': [],
  };
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalVendors = 0;
  int _pageSize = 20;
  
  // Loading states
  bool _isLoading = false;
  bool _isLoadingProducts = false;
  bool _isLoadingAnalytics = false;
  bool _isProcessing = false;
  
  // Error handling
  String? _error;
  
  // Filters
  String? _searchQuery;
  bool? _isVerified;
  double? _minRating;
  String _sortBy = 'created_at';
  bool _sortDescending = true;
  
  // Getters
  Vendor? get currentVendor => _currentVendor;
  List<Vendor> get vendors => _vendors;
  Vendor? get selectedVendor => _selectedVendor;
  List<Product> get vendorProducts => _vendorProducts;
  Map<String, dynamic> get productStats => _productStats;
  Map<String, dynamic> get vendorAnalytics => _vendorAnalytics;
  bool get isLoading => _isLoading;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingAnalytics => _isLoadingAnalytics;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalVendors => _totalVendors;
  bool get isVendor => _currentVendor != null;
  
  // ========== VENDOR INITIALIZATION ==========
  
  Future<void> initializeVendor() async {
    await fetchCurrentVendor();
    if (_currentVendor != null) {
      await Future.wait([
        fetchVendorProducts(),
        fetchVendorAnalytics(),
      ]);
    }
  }
  
  // ========== VENDOR CRUD OPERATIONS ==========
  
  Future<void> fetchCurrentVendor() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getCurrentVendor();
      _currentVendor = Vendor.fromJson(response);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _currentVendor = null;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> registerAsVendor(Map<String, dynamic> vendorData) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.registerVendor(vendorData);
      _currentVendor = Vendor.fromJson(response);
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
  
  Future<bool> updateVendorProfile(Map<String, dynamic> updates) async {
    if (_currentVendor == null) return false;
    
    _isProcessing = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.updateVendor(_currentVendor!.id, updates);
      _currentVendor = Vendor.fromJson(response);
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
  
  Future<bool> uploadVendorLogo(File logoFile) async {
    if (_currentVendor == null) return false;
    
    _isProcessing = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.uploadVendorLogo(
        _currentVendor!.id,
        logoFile,
      );
      _currentVendor = Vendor.fromJson(response);
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
  
  // ========== VENDOR LISTING ==========
  
  Future<void> fetchVendors({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _vendors.clear();
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
      
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        params['search'] = _searchQuery!;
      }
      if (_isVerified != null) {
        params['is_verified'] = _isVerified.toString();
      }
      if (_minRating != null) {
        params['min_rating'] = _minRating.toString();
      }
      
      final response = await _apiService.getVendorsMap(params);
      
      final List<dynamic> results = response['results'] ?? [];
      final List<Vendor> newVendors = results
          .map((json) => Vendor.fromJson(json))
          .toList();
      
      if (refresh) {
        _vendors = newVendors;
      } else {
        _vendors.addAll(newVendors);
      }
      
      _totalVendors = response['count'] ?? 0;
      _totalPages = ((response['count'] ?? 0) / _pageSize).ceil();
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchVendorById(String vendorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getVendorById(vendorId);
      _selectedVendor = Vendor.fromJson(response);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // ========== VENDOR PRODUCTS ==========
  
  Future<void> fetchVendorProducts({String? vendorId}) async {
    _isLoadingProducts = true;
    _error = null;
    notifyListeners();
    
    try {
      final id = vendorId ?? _currentVendor?.id;
      if (id == null) {
        throw Exception('No vendor ID available');
      }
      
      final response = await _apiService.getVendorProducts(id);
      final List<dynamic> results = response['results'] ?? response;
      _vendorProducts = results
          .map((json) => Product.fromJson(json))
          .toList();
      
      // Update product stats
      _updateProductStats();
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }
  
  Future<bool> createProduct(Map<String, dynamic> productData) async {
    if (_currentVendor == null) return false;
    
    _isProcessing = true;
    _error = null;
    notifyListeners();
    
    try {
      productData['vendor'] = _currentVendor!.id;
      await _apiService.createProduct(productData);
      await fetchVendorProducts();
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
  
  Future<bool> updateProduct(String productId, Map<String, dynamic> updates) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();
    
    try {
      await _apiService.updateProduct(productId, updates);
      await fetchVendorProducts();
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
  
  Future<bool> deleteProduct(String productId) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();
    
    try {
      await _apiService.deleteProduct(productId);
      _vendorProducts.removeWhere((p) => p.id == productId);
      _updateProductStats();
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
  
  Future<bool> uploadProductImages(String productId, List<File> images) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();
    
    try {
      await _apiService.uploadProductImages(productId, images);
      await fetchVendorProducts();
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
  
  Future<bool> bulkUpdateProducts(List<Map<String, dynamic>> updates) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();
    
    try {
      await _apiService.bulkUpdateProducts(updates);
      await fetchVendorProducts();
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
  
  // ========== VENDOR ANALYTICS ==========
  
  Future<void> fetchVendorAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_currentVendor == null) return;
    
    _isLoadingAnalytics = true;
    _error = null;
    notifyListeners();
    
    try {
      final params = <String, String>{};
      
      if (startDate != null) {
        params['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        params['end_date'] = endDate.toIso8601String();
      }
      
      final response = await _apiService.getVendorAnalytics(
        _currentVendor!.id,
        params,
      );
      
      _vendorAnalytics = {
        'total_revenue': response['total_revenue'] ?? 0.0,
        'total_orders': response['total_orders'] ?? 0,
        'total_products': response['total_products'] ?? _vendorProducts.length,
        'total_customers': response['total_customers'] ?? 0,
        'pending_orders': response['pending_orders'] ?? 0,
        'average_rating': response['average_rating'] ?? 0.0,
        'sales_trend': response['sales_trend'] ?? [],
        'top_products': response['top_products'] ?? [],
        'recent_orders': response['recent_orders'] ?? [],
      };
      
      notifyListeners();
    } catch (e) {
      print('Error fetching vendor analytics: $e');
    } finally {
      _isLoadingAnalytics = false;
      notifyListeners();
    }
  }
  
  Future<Map<String, dynamic>> fetchSalesReport({
    required DateTime startDate,
    required DateTime endDate,
    String groupBy = 'day',
  }) async {
    if (_currentVendor == null) return {};
    
    try {
      final params = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'group_by': groupBy,
      };
      
      final response = await _apiService.getVendorSalesReport(
        _currentVendor!.id,
        params,
      );
      
      return response;
    } catch (e) {
      print('Error fetching sales report: $e');
      return {};
    }
  }
  
  // ========== VENDOR ORDERS ==========
  
  Future<List<Map<String, dynamic>>> fetchVendorOrders({
    String? status,
    int page = 1,
  }) async {
    if (_currentVendor == null) return [];
    
    try {
      final params = <String, String>{
        'page': page.toString(),
        'page_size': '20',
      };
      
      if (status != null) {
        params['status'] = status;
      }
      
      final response = await _apiService.getVendorOrders(params);
      return List<Map<String, dynamic>>.from(response['results'] ?? response);
    } catch (e) {
      print('Error fetching vendor orders: $e');
      return [];
    }
  }
  
  // ========== HELPER METHODS ==========
  
  void _updateProductStats() {
    _productStats = {
      'total_products': _vendorProducts.length,
      'active_products': _vendorProducts.where((p) => p.isActive).length,
      'out_of_stock': _vendorProducts.where((p) => p.stock == 0).length,
      'low_stock': _vendorProducts.where((p) => p.stock > 0 && p.stock < 10).length,
      'featured': _vendorProducts.where((p) => p.isFeatured).length,
      'average_rating': _vendorProducts.isEmpty
          ? 0.0
          : _vendorProducts.fold(0.0, (sum, p) => sum + p.rating) / 
            _vendorProducts.length,
    };
  }
  
  void setSearchQuery(String? query) {
    _searchQuery = query;
    fetchVendors(refresh: true);
  }
  
  void setVerifiedFilter(bool? verified) {
    _isVerified = verified;
    fetchVendors(refresh: true);
  }
  
  void setMinRating(double? rating) {
    _minRating = rating;
    fetchVendors(refresh: true);
  }
  
  void setSortBy(String sortField, {bool descending = true}) {
    _sortBy = sortField;
    _sortDescending = descending;
    fetchVendors(refresh: true);
  }
  
  void clearFilters() {
    _searchQuery = null;
    _isVerified = null;
    _minRating = null;
    _sortBy = 'created_at';
    _sortDescending = true;
    fetchVendors(refresh: true);
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  void clearSelectedVendor() {
    _selectedVendor = null;
    notifyListeners();
  }
  
  Future<void> loadMore() async {
    if (_currentPage >= _totalPages) return;
    
    _currentPage++;
    await fetchVendors();
  }
}
