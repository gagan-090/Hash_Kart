import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;
  String? _refreshToken;

  void setAuthToken(String token) => _authToken = token;
  void setRefreshToken(String token) => _refreshToken = token;
  void clearAuthToken() {
    _authToken = null;
    _refreshToken = null;
  }

  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && includeAuth) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Map<String, String> _getMultipartHeaders() {
    final headers = <String, String>{};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final responseData = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else if (response.statusCode == 401) {
      // Try to refresh token
      if (_refreshToken != null) {
        final refreshed = await _refreshAuthToken();
        if (refreshed) {
          throw Exception('Token refreshed, retry request');
        }
      }
      throw Exception('Unauthorized - Please login again');
    } else {
      final message = responseData['message'] ?? 
                     responseData['detail'] ?? 
                     responseData['error'] ?? 
                     'Request failed';
      throw Exception(message);
    }
  }

  Future<bool> _refreshAuthToken() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshToken}'),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({'refresh': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['access'];
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ========== GENERIC HTTP METHODS ==========
  
  Future<Map<String, dynamic>> get(String endpoint) async {
    final urls = [ApiConstants.baseUrl, ...ApiConstants.fallbackBaseUrls];
    Exception? lastError;
    for (final base in urls.toSet()) {
      try {
        final response = await http.get(
          Uri.parse('$base$endpoint'),
          headers: _getHeaders(),
        );
        return _handleResponse(response);
      } catch (e) {
        lastError = Exception(e.toString());
        continue;
      }
    }
    throw lastError ?? Exception('Network error');
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final urls = [ApiConstants.baseUrl, ...ApiConstants.fallbackBaseUrls];
    Exception? lastError;
    for (final base in urls.toSet()) {
      try {
        final response = await http.post(
          Uri.parse('$base$endpoint'),
          headers: _getHeaders(),
          body: jsonEncode(data),
        );
        return _handleResponse(response);
      } catch (e) {
        lastError = Exception(e.toString());
        continue;
      }
    }
    throw lastError ?? Exception('Network error');
  }

  // ========== AUTHENTICATION METHODS ==========
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}');
    final headers = _getHeaders(includeAuth: false);
    
    print('Registration URL: $url');
    print('Registration headers: $headers');
    print('Registration data: ${jsonEncode(userData)}');
    
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(userData),
    );
    
    print('Registration response status: ${response.statusCode}');
    print('Registration response body: ${response.body}');
    
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logout}'),
      headers: _getHeaders(),
      body: jsonEncode({'refresh_token': _refreshToken}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> logoutAllDevices() async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logoutAll}'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.forgotPassword}'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode({'email': email}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> confirmPasswordReset(String email, String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.confirmPasswordReset}'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode({
        'email': email,
        'token': token,
        'new_password': newPassword,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyEmail(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyEmail}'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode({'token': token}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> resendEmailVerification() async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.resendVerification}'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.requestOtp}'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode({'phone': phone}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyOtp}'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );
    return _handleResponse(response);
  }

  // ========== USER PROFILE METHODS ==========
  
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userProfile}'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> userData) async {
    // Use PATCH on the userProfile endpoint directly since updateProfile doesn't exist
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userProfile}'),
      headers: _getHeaders(),
      body: jsonEncode(userData),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getUserAddresses() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userAddresses}'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['results'] ?? data;
  }

  Future<Map<String, dynamic>> addUserAddress(Map<String, dynamic> addressData) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userAddresses}'),
      headers: _getHeaders(),
      body: jsonEncode(addressData),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateUserAddress(String addressId, Map<String, dynamic> addressData) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userAddresses}$addressId/'),
      headers: _getHeaders(),
      body: jsonEncode(addressData),
    );
    return _handleResponse(response);
  }

  Future<void> deleteUserAddress(String addressId) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userAddresses}$addressId/'),
      headers: _getHeaders(),
    );
    await _handleResponse(response);
  }

  // ========== PRODUCT METHODS ==========
  
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? brand,
    String? search,
    String? ordering,
    double? minPrice,
    double? maxPrice,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    
    if (category != null) queryParams['category'] = category;
    if (brand != null) queryParams['brand'] = brand;
    if (search != null) queryParams['search'] = search;
    if (ordering != null) queryParams['ordering'] = ordering;
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.products}')
        .replace(queryParameters: queryParams);
    
    print('GET Products URL: $uri');
    print('Headers: ${_getHeaders()}');
    
    final response = await http.get(uri, headers: _getHeaders());
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getProductDetails(String slug) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.productDetail}$slug/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> searchProducts(String query, {int page = 1}) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.searchProducts}?q=$query&page=$page'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['results'] ?? data;
  }

  Future<List<dynamic>> getCategories() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.categories}');
    print('GET Categories URL: $uri');
    print('Headers: ${_getHeaders()}');
    
    final response = await http.get(uri, headers: _getHeaders());
    print('Categories Response status: ${response.statusCode}');
    print('Categories Response body: ${response.body}');
    
    final data = await _handleResponse(response);
    return data['results'] ?? data;
  }

  Future<Map<String, dynamic>> getCategoryTree() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.categoryTree}'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getCategoryDetails(String slug) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.categories}$slug/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getBrands() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.brands}'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['results'] ?? data;
  }

  Future<Map<String, dynamic>> getBrandDetails(String slug) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.brands}$slug/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  // ========== PRODUCT REVIEWS METHODS ==========
  
  Future<List<dynamic>> getProductReviews(String productId, {int page = 1}) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/products/$productId${ApiConstants.productReviews}?page=$page'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['results'] ?? data;
  }

  Future<Map<String, dynamic>> addProductReview(String productId, Map<String, dynamic> reviewData) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/products/$productId${ApiConstants.productReviews}'),
      headers: _getHeaders(),
      body: jsonEncode(reviewData),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> markReviewHelpful(String reviewId) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.markReviewHelpful.replaceAll('{reviewId}', reviewId)}'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  // ========== WISHLIST METHODS ==========
  
  Future<List<dynamic>> getWishlist({int page = 1}) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.wishlist}?page=$page'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['results'] ?? data;
  }

  Future<Map<String, dynamic>> addToWishlist(String productId) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.addToWishlist}'),
      headers: _getHeaders(),
      body: jsonEncode({'product_id': productId}),
    );
    return _handleResponse(response);
  }

  Future<void> removeFromWishlist(String productId) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.removeFromWishlist.replaceAll('{productId}', productId)}'),
      headers: _getHeaders(),
    );
    await _handleResponse(response);
  }

  Future<Map<String, dynamic>> toggleWishlist(String productId) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.wishlistToggle}'),
      headers: _getHeaders(),
      body: jsonEncode({'product_id': productId}),
    );
    return _handleResponse(response);
  }

  // ========== CART METHODS ==========
  
  Future<Map<String, dynamic>> getCart() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cart}');
    final headers = _getHeaders();
    
    print('Get cart URL: $url');
    print('Get cart headers: $headers');
    
    final response = await http.get(url, headers: headers);
    
    print('Get cart response status: ${response.statusCode}');
    print('Get cart response body: ${response.body}');
    
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> addToCart(String productId, int quantity, {String? variationId}) async {
    final requestData = {
      'product': productId,  // Django expects 'product' not 'product_id'
      'quantity': quantity,
    };
    if (variationId != null) {
      requestData['variation'] = variationId;  // Django expects 'variation' not 'variation_id'
    }

    print('Add to cart URL: ${ApiConstants.baseUrl}${ApiConstants.addToCart}');
    print('Add to cart data: ${jsonEncode(requestData)}');
    print('Add to cart headers: ${_getHeaders()}');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.addToCart}'),
      headers: _getHeaders(),
      body: jsonEncode(requestData),
    );
    
    print('Add to cart response status: ${response.statusCode}');
    print('Add to cart response body: ${response.body}');
    
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateCartItem(String itemId, int quantity) async {
    print('Updating cart item: $itemId, quantity: $quantity');
    
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateCartItem}$itemId/update/'),
      headers: _getHeaders(),
      body: jsonEncode({'quantity': quantity}),
    );
    
    print('Update cart item response status: ${response.statusCode}');
    print('Update cart item response body: ${response.body}');
    
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> removeFromCart(String itemId) async {
    print('Removing from cart: $itemId');
    
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.removeFromCart}$itemId/remove/'),
      headers: _getHeaders(),
    );
    
    print('Remove from cart response status: ${response.statusCode}');
    print('Remove from cart response body: ${response.body}');
    
    return _handleResponse(response);
  }

  Future<void> clearCart() async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.clearCart}'),
      headers: _getHeaders(),
    );
    await _handleResponse(response);
  }

  // ========== ORDER METHODS ==========
  
  Future<Map<String, dynamic>> getOrders({int page = 1, String? status}) async {
    final queryParams = <String, String>{'page': page.toString()};
    if (status != null) queryParams['status'] = status;
    
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}')
        .replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orderDetails}$orderId/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createOrder}'),
      headers: _getHeaders(),
      body: jsonEncode(orderData),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createPaymentOrder(String orderId, String paymentMethod) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/payments/orders/create/'),
      headers: _getHeaders(),
      body: jsonEncode({
        'order_id': orderId,
        'payment_method': paymentMethod,
      }),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getShippingMethods() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.shippingMethods}');
    final headers = _getHeaders();
    
    print('GET Shipping Methods URL: $url');
    print('Headers: $headers');
    
    final response = await http.get(url, headers: headers);
    
    print('Shipping Methods Response status: ${response.statusCode}');
    print('Shipping Methods Response body: ${response.body}');
    
    final data = await _handleResponse(response);
    
    // Handle the response structure
    if (data['success'] == true && data['data'] is List) {
      return data['data'] as List<dynamic>;
    } else if (data['data'] is List) {
      return data['data'] as List<dynamic>;
    } else if (data['results'] is List) {
      return data['results'] as List<dynamic>;
    }
    
    return [];
  }

  Future<Map<String, dynamic>> validateCoupon(String couponCode, double cartTotal) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.coupons}validate/'),
      headers: _getHeaders(),
      body: jsonEncode({'code': couponCode, 'cart_total': cartTotal}),
    );
    return _handleResponse(response);
  }

  // ========== VENDOR METHODS ==========
  
  Future<List<dynamic>> getVendors({int page = 1}) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendors}?page=$page'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['results'] ?? data;
  }

  Future<Map<String, dynamic>> getVendorDetails(String vendorId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendors}$vendorId/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  // ========== NOTIFICATION METHODS ==========
  
  Future<List<dynamic>> getNotifications({int page = 1}) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}?page=$page'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['results'] ?? data;
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.markNotificationRead.replaceAll('{notificationId}', notificationId)}'),
      headers: _getHeaders(),
    );
    await _handleResponse(response);
  }

  Future<void> markAllNotificationsAsRead() async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.markAllNotificationsRead}'),
      headers: _getHeaders(),
    );
    await _handleResponse(response);
  }

  // ========== EXTENDED API METHODS ==========

  // Product methods - removed duplicate getProducts method

  Future<Map<String, dynamic>> getProductById(String productId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.productDetail}$productId/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendorProducts}'),
      headers: _getHeaders(),
      body: jsonEncode(productData),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateProduct(String productId, Map<String, dynamic> updates) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendorProductDetail}$productId/'),
      headers: _getHeaders(),
      body: jsonEncode(updates),
    );
    return _handleResponse(response);
  }

  Future<void> deleteProduct(String productId) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendorProductDetail}$productId/'),
      headers: _getHeaders(),
    );
    await _handleResponse(response);
  }

  // Cart methods - removed duplicates, using existing methods

  // Order methods - removed duplicate getOrders

  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orderDetails}$orderId/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}$orderId/cancel/'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateOrderStatus(String orderId, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}$orderId/status/'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> checkout(Map<String, dynamic> checkoutData) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}checkout/'),
      headers: _getHeaders(),
      body: jsonEncode(checkoutData),
    );
    return _handleResponse(response);
  }

  // Vendor methods
  Future<Map<String, dynamic>> getCurrentVendor() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendors}current/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> registerVendor(Map<String, dynamic> vendorData) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendors}register/'),
      headers: _getHeaders(),
      body: jsonEncode(vendorData),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateVendor(String vendorId, Map<String, dynamic> updates) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendors}$vendorId/'),
      headers: _getHeaders(),
      body: jsonEncode(updates),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getVendorById(String vendorId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendors}$vendorId/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Vendor methods - removed duplicate getVendors

  Future<Map<String, dynamic>> getVendorProducts(String vendorId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendorProducts}?vendor=$vendorId'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getVendorOrders([Map<String, String>? params]) async {
    final queryString = params != null ? Uri(queryParameters: params).query : '';
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}vendor/?$queryString'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getVendorAnalytics(String vendorId, Map<String, String> params) async {
    final queryString = Uri(queryParameters: params).query;
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.analytics}vendor/$vendorId/?$queryString'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Notification methods - removed duplicate getNotifications

  Future<Map<String, dynamic>> getUnreadNotificationCount() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}unread-count/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<void> deleteNotification(String notificationId) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}$notificationId/'),
      headers: _getHeaders(),
    );
    await _handleResponse(response);
  }

  Future<void> clearAllNotifications() async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}clear-all/'),
      headers: _getHeaders(),
    );
    await _handleResponse(response);
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}preferences/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<void> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}preferences/'),
      headers: _getHeaders(),
      body: jsonEncode(preferences),
    );
    await _handleResponse(response);
  }

  // Search methods - removed duplicate searchProducts

  Future<Map<String, dynamic>> searchVendors(Map<String, String> params) async {
    final queryString = Uri(queryParameters: params).query;
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendors}search/?$queryString'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> searchCategories(Map<String, String> params) async {
    final queryString = Uri(queryParameters: params).query;
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.categories}search/?$queryString'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getSearchSuggestions(String query) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.products}suggestions/?q=$query'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getTrendingSearches() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.products}trending-searches/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getSearchHistory() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.products}search-history/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<void> saveSearchHistory(List<String> searches) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.products}search-history/'),
      headers: _getHeaders(),
      body: jsonEncode({'searches': searches}),
    );
    await _handleResponse(response);
  }

  // Additional helper methods
  Future<Map<String, dynamic>> applyCoupon(String couponCode) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.coupons}apply/'),
      headers: _getHeaders(),
      body: jsonEncode({'code': couponCode}),
    );
    return _handleResponse(response);
  }

  // Shipping methods - removed duplicate getShippingMethods

  Future<Map<String, dynamic>> trackOrder(String orderId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}$orderId/track/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getReturns() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.returns}'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> requestReturn(Map<String, dynamic> returnData) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.returns}'),
      headers: _getHeaders(),
      body: jsonEncode(returnData),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateReturnStatus(String returnId, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.returns}$returnId/'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> generateInvoice(String orderId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}$orderId/invoice/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<void> downloadInvoice(String orderId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}$orderId/invoice/download/'),
      headers: _getHeaders(),
    );
    await _handleResponse(response);
  }

  Future<Map<String, dynamic>> getOrderAnalytics(Map<String, String> params) async {
    final queryString = Uri(queryParameters: params).query;
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.analytics}orders/?$queryString'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getVendorSalesReport(String vendorId, Map<String, String> params) async {
    final queryString = Uri(queryParameters: params).query;
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.analytics}vendor/$vendorId/sales/?$queryString'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> uploadVendorLogo(String vendorId, File logoFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendors}$vendorId/logo/'),
    );
    
    request.headers.addAll(_getMultipartHeaders());
    request.files.add(await http.MultipartFile.fromPath('logo', logoFile.path));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> uploadProductImages(String productId, List<File> images) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadProductImages.replaceAll('{productId}', productId)}'),
    );
    
    request.headers.addAll(_getMultipartHeaders());
    
    for (var i = 0; i < images.length; i++) {
      request.files.add(
        await http.MultipartFile.fromPath('images', images[i].path),
      );
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> bulkUpdateProducts(List<Map<String, dynamic>> updates) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.bulkProductUpdate}'),
      headers: _getHeaders(),
      body: jsonEncode({'products': updates}),
    );
    return _handleResponse(response);
  }

  // Product review methods - using existing methods below

  // Additional API methods needed by providers
  
  // Override existing methods to return Map instead of List for consistency
  Future<Map<String, dynamic>> getCategoriesMap() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.categories}'),
      headers: _getHeaders(includeAuth: false),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getProductsMap(Map<String, String> params) async {
    final queryString = Uri(queryParameters: params).query;
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.products}?$queryString'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getOrdersMap(Map<String, String> params) async {
    final queryString = Uri(queryParameters: params).query;
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}?$queryString'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getVendorsMap(Map<String, String> params) async {
    final queryString = Uri(queryParameters: params).query;
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendors}?$queryString'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getNotificationsMap(Map<String, String> params) async {
    final queryString = Uri(queryParameters: params).query;
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}?$queryString'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> searchProductsMap(Map<String, String> params) async {
    final queryString = Uri(queryParameters: params).query;
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.searchProducts}?$queryString'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> addToCartMap(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.addToCart}');
    final headers = _getHeaders();
    
    print('Add to cart URL: $url');
    print('Add to cart headers: $headers');
    print('Add to cart data: ${jsonEncode(data)}');
    
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(data),
    );
    
    print('Add to cart response status: ${response.statusCode}');
    print('Add to cart response body: ${response.body}');
    
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateCartItemMap(String itemId, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateCartItem}$itemId/update/'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> removeFromCartMap(String itemId) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.removeFromCart}$itemId/remove/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getShippingMethodsMap() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.shippingMethods}'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getWishlistMap() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.wishlist}'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> addToWishlistMap(String productId) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.addToWishlist}'),
      headers: _getHeaders(),
      body: jsonEncode({'product': productId}),
    );
    return _handleResponse(response);
  }

  Future<void> removeFromWishlistMap(String productId) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.removeFromWishlist.replaceAll('{productId}', productId)}'),
      headers: _getHeaders(),
    );
    await _handleResponse(response);
  }

  // ========== ORDER MANAGEMENT METHODS ==========

  Future<Map<String, dynamic>> updateOrderShippingAddress(String orderId, Map<String, dynamic> addressData) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}$orderId/shipping-address/'),
      headers: _getHeaders(),
      body: jsonEncode(addressData),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> requestOrderModification(String orderId, Map<String, dynamic> modifications) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}$orderId/modify/'),
      headers: _getHeaders(),
      body: jsonEncode(modifications),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getOrderStatusHistory(String orderId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}$orderId/status-history/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> addOrderNote(String orderId, String note) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}$orderId/notes/'),
      headers: _getHeaders(),
      body: jsonEncode({'note': note}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getDeliveryPartners() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/delivery-partners/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> estimateDeliveryTime(String orderId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}$orderId/delivery-estimate/'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }
}
