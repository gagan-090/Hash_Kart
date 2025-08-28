import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  String? _accessToken;
  String? _refreshToken;
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _accessToken != null && _user != null;
  bool get isInitialized => _isInitialized;

  // Initialize auth state from stored data
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    try {
      await _loadStoredTokens();
      if (_accessToken != null) {
        _apiService.setAuthToken(_accessToken!);
        if (_refreshToken != null) {
          _apiService.setRefreshToken(_refreshToken!);
        }
        await _loadUserProfile();
      }
    } catch (e) {
      print('Auth initialization error: $e');
      await _clearStoredData();
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ========== AUTHENTICATION METHODS ==========

  Future<bool> login(String email, String password) async {
    setLoading(true);
    setError(null);

    try {
      final response = await _apiService.login(email, password);
      
      if (response['access'] != null) {
        _accessToken = response['access'];
        _refreshToken = response['refresh'];
        
        // Set tokens in API service
        _apiService.setAuthToken(_accessToken!);
        if (_refreshToken != null) {
          _apiService.setRefreshToken(_refreshToken!);
        }
        
        // Store tokens persistently
        await _storeTokens();
        
        // Load user profile
        await _loadUserProfile();
        
        notifyListeners();
        return true;
      } else {
        setError('Invalid login response');
        return false;
      }
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    setLoading(true);
    setError(null);

    try {
      // Ensure required fields are present
      if (!userData.containsKey('password_confirm')) {
        userData['password_confirm'] = userData['password'];
      }
      if (!userData.containsKey('user_type')) {
        userData['user_type'] = 'customer';
      }

      final response = await _apiService.register(userData);
      
      // Django registration doesn't return tokens directly
      // User needs to verify email first, then login
      if (response['success'] == true) {
        // Registration successful, but user needs to verify email
        return true;
      } else {
        setError(response['message'] ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout({bool logoutFromAllDevices = false}) async {
    setLoading(true);
    setError(null);

    try {
      if (_accessToken != null) {
        if (logoutFromAllDevices) {
          await _apiService.logoutAllDevices();
        } else {
          await _apiService.logout();
        }
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await _clearAuthData();
      setLoading(false);
    }
  }

  // ========== PASSWORD RESET METHODS ==========

  Future<bool> requestPasswordReset(String email) async {
    setLoading(true);
    setError(null);

    try {
      await _apiService.requestPasswordReset(email);
      return true;
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> confirmPasswordReset(String email, String token, String newPassword) async {
    setLoading(true);
    setError(null);

    try {
      await _apiService.confirmPasswordReset(email, token, newPassword);
      return true;
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }

  // ========== EMAIL VERIFICATION METHODS ==========

  Future<bool> verifyEmail(String token) async {
    setLoading(true);
    setError(null);

    try {
      await _apiService.verifyEmail(token);
      // Reload user profile to update email verification status
      if (_accessToken != null) {
        await _loadUserProfile();
      }
      return true;
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> resendEmailVerification() async {
    setLoading(true);
    setError(null);

    try {
      await _apiService.resendEmailVerification();
      return true;
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }

  // ========== OTP METHODS ==========

  Future<bool> requestOtp(String phone) async {
    setLoading(true);
    setError(null);

    try {
      await _apiService.requestOtp(phone);
      return true;
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    setLoading(true);
    setError(null);

    try {
      await _apiService.verifyOtp(phone, otp);
      // Reload user profile to update phone verification status
      if (_accessToken != null) {
        await _loadUserProfile();
      }
      return true;
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }

  // ========== USER PROFILE METHODS ==========

  Future<void> refreshUserProfile() async {
    if (_accessToken != null) {
      await _loadUserProfile();
    }
  }

  Future<bool> updateUserProfile(Map<String, dynamic> userData) async {
    setLoading(true);
    setError(null);

    try {
      final response = await _apiService.updateUserProfile(userData);
      _user = User.fromJson(response);
      notifyListeners();
      return true;
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }

  // ========== PRIVATE HELPER METHODS ==========

  Future<void> _loadUserProfile() async {
    try {
      final response = await _apiService.getUserProfile();
      _user = User.fromJson(response);
      notifyListeners();
    } catch (e) {
      print('Failed to load user profile: $e');
      // If profile loading fails due to auth issues, clear auth data
      if (e.toString().contains('Unauthorized')) {
        await _clearAuthData();
      }
    }
  }

  Future<void> _storeTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_accessToken != null) {
        await prefs.setString('access_token', _accessToken!);
      }
      if (_refreshToken != null) {
        await prefs.setString('refresh_token', _refreshToken!);
      }
    } catch (e) {
      print('Failed to store tokens: $e');
    }
  }

  Future<void> _loadStoredTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');
    } catch (e) {
      print('Failed to load stored tokens: $e');
    }
  }

  Future<void> _clearStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
    } catch (e) {
      print('Failed to clear stored data: $e');
    }
  }

  Future<void> _clearAuthData() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    _apiService.clearAuthToken();
    await _clearStoredData();
    notifyListeners();
  }

  // ========== TOKEN REFRESH ==========

  Future<bool> refreshTokens() async {
    if (_refreshToken == null) return false;

    try {
      // The API service handles token refresh internally
      // We just need to update our stored tokens if successful
      await _storeTokens();
      return true;
    } catch (e) {
      print('Token refresh failed: $e');
      await _clearAuthData();
      return false;
    }
  }
}
