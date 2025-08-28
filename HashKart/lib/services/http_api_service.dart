import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class HttpApiService {
  static final HttpApiService _instance = HttpApiService._internal();
  factory HttpApiService() => _instance;
  HttpApiService._internal();

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  // Authentication APIs
  Future<Map<String, dynamic>> registerUser(
      Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          jsonDecode(response.body)['message'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setAuthToken(data['access']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
    }
  }

  // Product APIs
  Future<List<dynamic>> getProducts({
    int? page,
    int? limit,
    String? category,
    String? search,
    String? sort,
  }) async {
    final params = {
      if (page != null) 'page': page.toString(),
      if (limit != null) 'limit': limit.toString(),
      if (category != null) 'category': category,
      if (search != null) 'search': search,
      if (sort != null) 'ordering': sort,
    };

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.products}')
        .replace(queryParameters: params);

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'] ?? data;
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.categories}'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<Map<String, dynamic>> getProductDetails(String slug) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.productDetail}$slug/'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load product details');
    }
  }

  // User APIs
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userProfile}'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  // Order APIs
  Future<List<dynamic>> getUserOrders() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.orders}'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'] ?? data;
    } else {
      throw Exception('Failed to load orders');
    }
  }

  // Wishlist APIs
  Future<List<dynamic>> getWishlist() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.wishlist}'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load wishlist');
    }
  }

  Future<Map<String, dynamic>> toggleWishlist(String productId) async {
    final response = await http.post(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.wishlistToggle}$productId/'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to toggle wishlist');
    }
  }

  // Error handling
  String _handleError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data['message'] ?? data['detail'] ?? 'An error occurred';
    } catch (e) {
      return 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
    }
  }
}
