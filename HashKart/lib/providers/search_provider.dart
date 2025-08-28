import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../models/vendor_model.dart';
import '../models/category_model.dart' as cat_model;
import 'dart:async';

class SearchProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Search results
  List<Product> _productResults = [];
  List<Vendor> _vendorResults = [];
  List<cat_model.Category> _categoryResults = [];
  List<String> _searchSuggestions = [];
  List<String> _searchHistory = [];
  List<String> _trendingSearches = [];
  
  // Current search
  String _currentQuery = '';
  String _searchType = 'all'; // all, products, vendors, categories
  
  // Filters
  Map<String, dynamic> _activeFilters = {
    'categories': <String>[],
    'brands': <String>[],
    'price_min': null,
    'price_max': null,
    'rating_min': null,
    'discount_min': null,
    'in_stock': null,
    'is_featured': null,
    'vendor_verified': null,
    'shipping_free': null,
    'attributes': <String, dynamic>{},
  };
  
  // Sort options
  String _sortBy = 'relevance';
  bool _sortDescending = true;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalResults = 0;
  int _pageSize = 20;
  
  // Loading states
  bool _isSearching = false;
  bool _isLoadingMore = false;
  bool _isLoadingSuggestions = false;
  
  // Error handling
  String? _error;
  
  // Debouncing
  Timer? _debounceTimer;
  
  // Getters
  List<Product> get productResults => _productResults;
  List<Vendor> get vendorResults => _vendorResults;
  List<cat_model.Category> get categoryResults => _categoryResults;
  List<String> get searchSuggestions => _searchSuggestions;
  List<String> get searchHistory => _searchHistory;
  List<String> get trendingSearches => _trendingSearches;
  String get currentQuery => _currentQuery;
  String get searchType => _searchType;
  Map<String, dynamic> get activeFilters => _activeFilters;
  String get sortBy => _sortBy;
  bool get sortDescending => _sortDescending;
  bool get isSearching => _isSearching;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  String? get error => _error;
  int get totalResults => _totalResults;
  int get totalPages => _totalPages;
  bool get hasResults => _productResults.isNotEmpty || 
                          _vendorResults.isNotEmpty || 
                          _categoryResults.isNotEmpty;
  bool get hasActiveFilters => _activeFilters.values.any((value) {
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return value != null;
  });
  
  // ========== INITIALIZATION ==========
  
  Future<void> initialize() async {
    await Future.wait([
      _loadSearchHistory(),
      fetchTrendingSearches(),
    ]);
  }
  
  // ========== SEARCH METHODS ==========
  
  Future<void> search(String query, {bool refresh = false}) async {
    if (query.isEmpty) {
      clearResults();
      return;
    }
    
    if (refresh) {
      _currentPage = 1;
      clearResults();
    }
    
    _currentQuery = query;
    _isSearching = true;
    _error = null;
    notifyListeners();
    
    // Add to search history
    _addToSearchHistory(query);
    
    try {
      final params = _buildSearchParams();
      
      if (_searchType == 'all' || _searchType == 'products') {
        await _searchProducts(params);
      }
      
      if (_searchType == 'all' || _searchType == 'vendors') {
        await _searchVendors(params);
      }
      
      if (_searchType == 'all' || _searchType == 'categories') {
        await _searchCategories(params);
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
  
  Future<void> _searchProducts(Map<String, String> baseParams) async {
    final params = Map<String, String>.from(baseParams);
    params['search'] = _currentQuery;
    
    // Apply filters
    if (_activeFilters['categories']?.isNotEmpty ?? false) {
      params['categories'] = (_activeFilters['categories'] as List).join(',');
    }
    if (_activeFilters['brands']?.isNotEmpty ?? false) {
      params['brands'] = (_activeFilters['brands'] as List).join(',');
    }
    if (_activeFilters['price_min'] != null) {
      params['price_min'] = _activeFilters['price_min'].toString();
    }
    if (_activeFilters['price_max'] != null) {
      params['price_max'] = _activeFilters['price_max'].toString();
    }
    if (_activeFilters['rating_min'] != null) {
      params['rating_min'] = _activeFilters['rating_min'].toString();
    }
    if (_activeFilters['discount_min'] != null) {
      params['discount_min'] = _activeFilters['discount_min'].toString();
    }
    if (_activeFilters['in_stock'] != null) {
      params['in_stock'] = _activeFilters['in_stock'].toString();
    }
    if (_activeFilters['is_featured'] != null) {
      params['is_featured'] = _activeFilters['is_featured'].toString();
    }
    
    final response = await _apiService.searchProductsMap(params);
    
    final List<dynamic> results = response['results'] ?? [];
    final List<Product> products = results
        .map((json) => Product.fromJson(json))
        .toList();
    
    if (_currentPage == 1) {
      _productResults = products;
    } else {
      _productResults.addAll(products);
    }
    
    _totalResults = response['count'] ?? 0;
    _totalPages = ((_totalResults) / _pageSize).ceil();
  }
  
  Future<void> _searchVendors(Map<String, String> baseParams) async {
    final params = Map<String, String>.from(baseParams);
    params['search'] = _currentQuery;
    
    if (_activeFilters['vendor_verified'] != null) {
      params['is_verified'] = _activeFilters['vendor_verified'].toString();
    }
    
    final response = await _apiService.searchVendors(params);
    
    final List<dynamic> results = response['results'] ?? [];
    _vendorResults = results
        .map((json) => Vendor.fromJson(json))
        .toList();
  }
  
  Future<void> _searchCategories(Map<String, String> baseParams) async {
    final params = Map<String, String>.from(baseParams);
    params['search'] = _currentQuery;
    
    final response = await _apiService.searchCategories(params);
    
    final List<dynamic> results = response['results'] ?? [];
    _categoryResults = results
        .map((json) => cat_model.Category.fromJson(json))
        .toList();
  }
  
  // ========== SEARCH SUGGESTIONS ==========
  
  void fetchSuggestionsDebounced(String query) {
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      _searchSuggestions.clear();
      notifyListeners();
      return;
    }
    
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      fetchSuggestions(query);
    });
  }
  
  Future<void> fetchSuggestions(String query) async {
    if (query.isEmpty) return;
    
    _isLoadingSuggestions = true;
    notifyListeners();
    
    try {
      final response = await _apiService.getSearchSuggestions(query);
      _searchSuggestions = List<String>.from(response['suggestions'] ?? []);
      notifyListeners();
    } catch (e) {
      print('Error fetching suggestions: $e');
    } finally {
      _isLoadingSuggestions = false;
      notifyListeners();
    }
  }
  
  // ========== TRENDING & HISTORY ==========
  
  Future<void> fetchTrendingSearches() async {
    try {
      final response = await _apiService.getTrendingSearches();
      _trendingSearches = List<String>.from(response['trending'] ?? []);
      notifyListeners();
    } catch (e) {
      print('Error fetching trending searches: $e');
    }
  }
  
  Future<void> _loadSearchHistory() async {
    try {
      // Load from local storage or API
      final response = await _apiService.getSearchHistory();
      _searchHistory = List<String>.from(response['history'] ?? []);
      notifyListeners();
    } catch (e) {
      print('Error loading search history: $e');
    }
  }
  
  void _addToSearchHistory(String query) {
    if (query.isEmpty) return;
    
    // Remove if already exists
    _searchHistory.remove(query);
    
    // Add to beginning
    _searchHistory.insert(0, query);
    
    // Keep only last 10 searches
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }
    
    // Save to storage/API
    _saveSearchHistory();
    
    notifyListeners();
  }
  
  Future<void> _saveSearchHistory() async {
    try {
      await _apiService.saveSearchHistory(_searchHistory);
    } catch (e) {
      print('Error saving search history: $e');
    }
  }
  
  void clearSearchHistory() {
    _searchHistory.clear();
    _saveSearchHistory();
    notifyListeners();
  }
  
  // ========== FILTERS ==========
  
  void setFilter(String key, dynamic value) {
    _activeFilters[key] = value;
    notifyListeners();
    
    // Re-search with new filters
    if (_currentQuery.isNotEmpty) {
      search(_currentQuery, refresh: true);
    }
  }
  
  void removeFilter(String key) {
    _activeFilters[key] = null;
    notifyListeners();
    
    // Re-search without filter
    if (_currentQuery.isNotEmpty) {
      search(_currentQuery, refresh: true);
    }
  }
  
  void clearAllFilters() {
    _activeFilters = {
      'categories': <String>[],
      'brands': <String>[],
      'price_min': null,
      'price_max': null,
      'rating_min': null,
      'discount_min': null,
      'in_stock': null,
      'is_featured': null,
      'vendor_verified': null,
      'shipping_free': null,
      'attributes': <String, dynamic>{},
    };
    notifyListeners();
    
    // Re-search without filters
    if (_currentQuery.isNotEmpty) {
      search(_currentQuery, refresh: true);
    }
  }
  
  void setPriceRange(double? min, double? max) {
    _activeFilters['price_min'] = min;
    _activeFilters['price_max'] = max;
    notifyListeners();
    
    if (_currentQuery.isNotEmpty) {
      search(_currentQuery, refresh: true);
    }
  }
  
  void toggleCategory(String categoryId) {
    final categories = List<String>.from(_activeFilters['categories'] ?? []);
    
    if (categories.contains(categoryId)) {
      categories.remove(categoryId);
    } else {
      categories.add(categoryId);
    }
    
    _activeFilters['categories'] = categories;
    notifyListeners();
    
    if (_currentQuery.isNotEmpty) {
      search(_currentQuery, refresh: true);
    }
  }
  
  void toggleBrand(String brand) {
    final brands = List<String>.from(_activeFilters['brands'] ?? []);
    
    if (brands.contains(brand)) {
      brands.remove(brand);
    } else {
      brands.add(brand);
    }
    
    _activeFilters['brands'] = brands;
    notifyListeners();
    
    if (_currentQuery.isNotEmpty) {
      search(_currentQuery, refresh: true);
    }
  }
  
  // ========== SORTING ==========
  
  void setSortBy(String sortField, {bool descending = true}) {
    _sortBy = sortField;
    _sortDescending = descending;
    notifyListeners();
    
    if (_currentQuery.isNotEmpty) {
      search(_currentQuery, refresh: true);
    }
  }
  
  List<Map<String, dynamic>> getSortOptions() {
    return [
      {'value': 'relevance', 'label': 'Relevance'},
      {'value': 'price_low', 'label': 'Price: Low to High'},
      {'value': 'price_high', 'label': 'Price: High to Low'},
      {'value': 'rating', 'label': 'Customer Rating'},
      {'value': 'newest', 'label': 'Newest First'},
      {'value': 'discount', 'label': 'Discount'},
      {'value': 'popularity', 'label': 'Popularity'},
    ];
  }
  
  // ========== SEARCH TYPE ==========
  
  void setSearchType(String type) {
    _searchType = type;
    notifyListeners();
    
    if (_currentQuery.isNotEmpty) {
      search(_currentQuery, refresh: true);
    }
  }
  
  // ========== HELPER METHODS ==========
  
  Map<String, String> _buildSearchParams() {
    final params = <String, String>{
      'page': _currentPage.toString(),
      'page_size': _pageSize.toString(),
    };
    
    // Add sorting
    switch (_sortBy) {
      case 'price_low':
        params['ordering'] = 'price';
        break;
      case 'price_high':
        params['ordering'] = '-price';
        break;
      case 'rating':
        params['ordering'] = '-rating';
        break;
      case 'newest':
        params['ordering'] = '-created_at';
        break;
      case 'discount':
        params['ordering'] = '-discount_percentage';
        break;
      case 'popularity':
        params['ordering'] = '-order_count';
        break;
      default:
        // Relevance is handled by search backend
        break;
    }
    
    return params;
  }
  
  Future<void> loadMore() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    _currentPage++;
    await search(_currentQuery);
    
    _isLoadingMore = false;
    notifyListeners();
  }
  
  void clearResults() {
    _productResults.clear();
    _vendorResults.clear();
    _categoryResults.clear();
    _currentQuery = '';
    _currentPage = 1;
    _totalPages = 1;
    _totalResults = 0;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
