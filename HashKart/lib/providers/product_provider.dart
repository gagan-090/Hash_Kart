import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../models/category_model.dart' as cat_model;
import '../models/review_model.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Products
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Product> _vendorProducts = [];
  Product? _selectedProduct;
  
  // Categories
  List<cat_model.Category> _categories = [];
  List<cat_model.Category> _categoryTree = [];
  cat_model.Category? _selectedCategory;
  
  // Reviews
  List<Review> _productReviews = [];
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalProducts = 0;
  int _pageSize = 20;
  
  // Loading states
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingProduct = false;
  bool _isLoadingCategories = false;
  bool _isLoadingReviews = false;
  
  // Error handling
  String? _error;
  
  // Search and filters
  String? _searchQuery;
  String? _selectedBrand;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  String _sortBy = 'created_at';
  bool _sortDescending = true;
  
  // Wishlist
  List<String> _wishlistProductIds = [];
  
  // Getters
  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get vendorProducts => _vendorProducts;
  Product? get selectedProduct => _selectedProduct;
  List<cat_model.Category> get categories => _categories;
  List<cat_model.Category> get categoryTree => _categoryTree;
  cat_model.Category? get selectedCategory => _selectedCategory;
  List<Review> get productReviews => _productReviews;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingProduct => _isLoadingProduct;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingReviews => _isLoadingReviews;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalProducts => _totalProducts;
  List<String> get wishlistProductIds => _wishlistProductIds;
  
  // ========== PRODUCT METHODS ==========
  
  Future<void> fetchProducts({
    bool refresh = false,
    String? categoryId,
    String? vendorId,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _products.clear();
    }
    
    _setLoading(true);
    _error = null;
    
    try {
      final params = <String, String>{
        'page': _currentPage.toString(),
        'page_size': _pageSize.toString(),
        'ordering': '${_sortDescending ? '-' : ''}$_sortBy',
      };
      
      if (categoryId != null) params['category'] = categoryId;
      if (vendorId != null) params['vendor'] = vendorId;
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        params['search'] = _searchQuery!;
      }
      if (_selectedBrand != null) params['brand'] = _selectedBrand!;
      if (_minPrice != null) params['min_price'] = _minPrice.toString();
      if (_maxPrice != null) params['max_price'] = _maxPrice.toString();
      if (_minRating != null) params['min_rating'] = _minRating.toString();
      
      final response = await _apiService.getProductsMap(params);
      
      final List<dynamic> results = response['results'] ?? [];
      final List<Product> newProducts = results
          .map((json) => Product.fromJson(json))
          .toList();
      
      if (refresh) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }
      
      _totalProducts = response['count'] ?? 0;
      _totalPages = ((response['count'] ?? 0) / _pageSize).ceil();
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> fetchFeaturedProducts() async {
    try {
      final params = {
        'is_featured': 'true',
        'page_size': '10',
        'ordering': '-created_at',
      };
      
      final response = await _apiService.getProductsMap(params);
      final List<dynamic> results = response['results'] ?? [];
      _featuredProducts = results
          .map((json) => Product.fromJson(json))
          .toList();
      
      notifyListeners();
    } catch (e) {
      print('Error fetching featured products: $e');
    }
  }
  
  Future<void> fetchProductById(String productId) async {
    _isLoadingProduct = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getProductById(productId);
      _selectedProduct = Product.fromJson(response);
      
      // Fetch reviews for the product
      await fetchProductReviews(productId);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoadingProduct = false;
      notifyListeners();
    }
  }
  
  Future<void> loadMore() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    _currentPage++;
    await fetchProducts();
    
    _isLoadingMore = false;
    notifyListeners();
  }
  
  // ========== CATEGORY METHODS ==========
  
  Future<void> fetchCategories() async {
    _isLoadingCategories = true;
    notifyListeners();
    
    try {
      final response = await _apiService.getCategoriesMap();
      final List<dynamic> results = response['results'] ?? response;
      _categories = results
          .map((json) => cat_model.Category.fromJson(json))
          .toList();
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchCategoryTree() async {
    try {
      final response = await _apiService.getCategoryTree();
      final List<dynamic> results = response['results'] ?? response;
      _categoryTree = results
          .map((json) => cat_model.Category.fromJson(json))
          .toList();
      
      notifyListeners();
    } catch (e) {
      print('Error fetching category tree: $e');
    }
  }
  
  void selectCategory(cat_model.Category? category) {
    _selectedCategory = category;
    notifyListeners();
    
    if (category != null) {
      fetchProducts(refresh: true, categoryId: category.id);
    } else {
      fetchProducts(refresh: true);
    }
  }
  
  // ========== REVIEW METHODS ==========
  
  Future<void> fetchProductReviews(String productId) async {
    _isLoadingReviews = true;
    notifyListeners();
    
    try {
      final results = await _apiService.getProductReviews(productId, page: 1);
      _productReviews = results
          .map((json) => Review.fromJson(json))
          .toList();
      
      notifyListeners();
    } catch (e) {
      print('Error fetching reviews: $e');
    } finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }
  
  Future<bool> addProductReview(String productId, Map<String, dynamic> reviewData) async {
    try {
      reviewData['product'] = productId;
      await _apiService.addProductReview(productId, reviewData);
      await fetchProductReviews(productId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<void> markReviewHelpful(String reviewId) async {
    try {
      await _apiService.markReviewHelpful(reviewId);
      // Update the review in the list
      final index = _productReviews.indexWhere((r) => r.id == reviewId);
      if (index != -1) {
        _productReviews[index] = _productReviews[index].copyWith(
          helpfulCount: _productReviews[index].helpfulCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error marking review helpful: $e');
    }
  }
  
  // ========== WISHLIST METHODS ==========
  
  Future<void> fetchWishlist() async {
    try {
      final response = await _apiService.getWishlistMap();
      final List<dynamic> results = response['results'] ?? response;
      _wishlistProductIds = results
          .map((item) => item['product']['id'].toString())
          .toList();
      
      notifyListeners();
    } catch (e) {
      print('Error fetching wishlist: $e');
    }
  }
  
  Future<bool> toggleWishlist(String productId) async {
    try {
      final isInWishlist = _wishlistProductIds.contains(productId);
      
      if (isInWishlist) {
        await _apiService.removeFromWishlistMap(productId);
        _wishlistProductIds.remove(productId);
      } else {
        await _apiService.addToWishlistMap(productId);
        _wishlistProductIds.add(productId);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  bool isInWishlist(String productId) {
    return _wishlistProductIds.contains(productId);
  }
  
  // ========== SEARCH AND FILTER METHODS ==========
  
  void setSearchQuery(String? query) {
    _searchQuery = query;
    fetchProducts(refresh: true);
  }
  
  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    fetchProducts(refresh: true);
  }
  
  void setMinRating(double? rating) {
    _minRating = rating;
    fetchProducts(refresh: true);
  }
  
  void setBrand(String? brand) {
    _selectedBrand = brand;
    fetchProducts(refresh: true);
  }
  
  void setSortBy(String sortField, {bool descending = true}) {
    _sortBy = sortField;
    _sortDescending = descending;
    fetchProducts(refresh: true);
  }
  
  void clearFilters() {
    _searchQuery = null;
    _selectedBrand = null;
    _minPrice = null;
    _maxPrice = null;
    _minRating = null;
    _selectedCategory = null;
    _sortBy = 'created_at';
    _sortDescending = true;
    fetchProducts(refresh: true);
  }
  
  // ========== VENDOR PRODUCT METHODS ==========
  
  Future<void> fetchVendorProducts(String vendorId) async {
    try {
      final response = await _apiService.getVendorProducts(vendorId);
      final List<dynamic> results = response['results'] ?? response;
      _vendorProducts = results
          .map((json) => Product.fromJson(json))
          .toList();
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<bool> createProduct(Map<String, dynamic> productData) async {
    try {
      await _apiService.createProduct(productData);
      await fetchProducts(refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      await _apiService.updateProduct(productId, updates);
      await fetchProductById(productId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> deleteProduct(String productId) async {
    try {
      await _apiService.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // ========== HELPER METHODS ==========
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  void clearSelectedProduct() {
    _selectedProduct = null;
    _productReviews.clear();
    notifyListeners();
  }

  // Legacy methods for backward compatibility
  Future<void> loadCategories() => fetchCategories();
  Future<void> loadFeaturedProducts() => fetchFeaturedProducts();
  Future<void> loadProducts() => fetchProducts(refresh: true);
  Future<void> loadCategoryProducts(String categoryId) => fetchProducts(refresh: true, categoryId: categoryId);
  Future<void> loadWishlist() => fetchWishlist();
  Future<void> loadMoreProducts() => loadMore();
  
  List<Product> get searchResults => _products;
  bool get hasMoreProducts => _currentPage < _totalPages;
  List<Product> get wishlistItems => _products.where((p) => isInWishlist(p.id)).toList();
  
  Future<void> searchProducts(String query) async => setSearchQuery(query);
  void clearSearchResults() => clearFilters();
}
