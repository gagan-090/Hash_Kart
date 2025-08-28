import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/notification_model.dart';
import 'dart:async';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Notifications
  List<NotificationModel> _notifications = [];
  List<NotificationModel> _unreadNotifications = [];
  int _unreadCount = 0;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _pageSize = 20;
  
  // Loading states
  bool _isLoading = false;
  bool _isLoadingMore = false;
  
  // Error handling
  String? _error;
  
  // Real-time updates
  Timer? _pollingTimer;
  bool _isPollingEnabled = false;
  
  // Filters
  String? _typeFilter;
  bool _unreadOnly = false;
  
  // Getters
  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get unreadNotifications => _unreadNotifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasUnread => _unreadCount > 0;
  bool get isPollingEnabled => _isPollingEnabled;
  
  // ========== INITIALIZATION ==========
  
  Future<void> initialize() async {
    await fetchNotifications(refresh: true);
    startPolling();
  }
  
  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
  
  // ========== NOTIFICATION FETCHING ==========
  
  Future<void> fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _notifications.clear();
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final params = <String, String>{
        'page': _currentPage.toString(),
        'page_size': _pageSize.toString(),
        'ordering': '-created_at',
      };
      
      if (_typeFilter != null) {
        params['type'] = _typeFilter!;
      }
      if (_unreadOnly) {
        params['is_read'] = 'false';
      }
      
      final response = await _apiService.getNotificationsMap(params);
      
      final List<dynamic> results = response['results'] ?? [];
      final List<NotificationModel> newNotifications = results
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      
      if (refresh) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }
      
      // Update unread notifications
      _updateUnreadNotifications();
      
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
  
  Future<void> fetchUnreadCount() async {
    try {
      final response = await _apiService.getUnreadNotificationCount();
      _unreadCount = response['count'] ?? 0;
      notifyListeners();
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }
  
  // ========== NOTIFICATION ACTIONS ==========
  
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _apiService.markNotificationAsRead(notificationId);
      
      // Update local notification
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
      
      _updateUnreadNotifications();
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsAsRead();
      
      // Update all local notifications
      _notifications = _notifications.map((n) {
        return n.copyWith(isRead: true);
      }).toList();
      
      _unreadNotifications.clear();
      _unreadCount = 0;
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _apiService.deleteNotification(notificationId);
      
      _notifications.removeWhere((n) => n.id == notificationId);
      _updateUnreadNotifications();
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> clearAllNotifications() async {
    try {
      await _apiService.clearAllNotifications();
      
      _notifications.clear();
      _unreadNotifications.clear();
      _unreadCount = 0;
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // ========== NOTIFICATION PREFERENCES ==========
  
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      final response = await _apiService.getNotificationPreferences();
      return response;
    } catch (e) {
      print('Error fetching notification preferences: $e');
      return {};
    }
  }
  
  Future<bool> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    try {
      await _apiService.updateNotificationPreferences(preferences);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // ========== REAL-TIME UPDATES ==========
  
  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    if (_isPollingEnabled) return;
    
    _isPollingEnabled = true;
    _pollingTimer = Timer.periodic(interval, (_) {
      _pollForNewNotifications();
    });
  }
  
  void stopPolling() {
    _isPollingEnabled = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
  
  Future<void> _pollForNewNotifications() async {
    try {
      // Fetch only new unread notifications
      final params = {
        'page': '1',
        'page_size': '10',
        'is_read': 'false',
        'ordering': '-created_at',
      };
      
      final response = await _apiService.getNotificationsMap(params);
      final List<dynamic> results = response['results'] ?? [];
      
      if (results.isNotEmpty) {
        final newNotifications = results
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        
        // Check for actually new notifications
        for (final notification in newNotifications) {
          if (!_notifications.any((n) => n.id == notification.id)) {
            _notifications.insert(0, notification);
            _handleNewNotification(notification);
          }
        }
        
        _updateUnreadNotifications();
        notifyListeners();
      }
    } catch (e) {
      print('Error polling for notifications: $e');
    }
  }
  
  void _handleNewNotification(NotificationModel notification) {
    // Handle different notification types
    switch (notification.type) {
      case 'order_placed':
      case 'order_shipped':
      case 'order_delivered':
        // Could trigger specific actions or show special UI
        break;
      case 'product_review':
      case 'vendor_message':
        // Handle vendor-specific notifications
        break;
      default:
        // General notification handling
        break;
    }
    
    // Could also trigger local notifications here
    _showLocalNotification(notification);
  }
  
  void _showLocalNotification(NotificationModel notification) {
    // This would integrate with a local notification package
    // For now, just print for debugging
    print('New notification: ${notification.title}');
  }
  
  // ========== FILTERS ==========
  
  void setTypeFilter(String? type) {
    _typeFilter = type;
    fetchNotifications(refresh: true);
  }
  
  void setUnreadOnly(bool unreadOnly) {
    _unreadOnly = unreadOnly;
    fetchNotifications(refresh: true);
  }
  
  void clearFilters() {
    _typeFilter = null;
    _unreadOnly = false;
    fetchNotifications(refresh: true);
  }
  
  // ========== HELPER METHODS ==========
  
  void _updateUnreadNotifications() {
    _unreadNotifications = _notifications.where((n) => !n.isRead).toList();
    _unreadCount = _unreadNotifications.length;
  }
  
  Future<void> loadMore() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    _currentPage++;
    await fetchNotifications();
    
    _isLoadingMore = false;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // ========== NOTIFICATION TYPES ==========
  
  List<String> getAvailableNotificationTypes() {
    return [
      'order_placed',
      'order_confirmed',
      'order_shipped',
      'order_delivered',
      'order_cancelled',
      'payment_received',
      'payment_failed',
      'product_review',
      'product_question',
      'vendor_message',
      'system_update',
      'promotion',
      'price_drop',
      'back_in_stock',
    ];
  }
  
  String getNotificationIcon(String type) {
    switch (type) {
      case 'order_placed':
      case 'order_confirmed':
        return '📦';
      case 'order_shipped':
        return '🚚';
      case 'order_delivered':
        return '✅';
      case 'order_cancelled':
        return '❌';
      case 'payment_received':
        return '💰';
      case 'payment_failed':
        return '⚠️';
      case 'product_review':
        return '⭐';
      case 'product_question':
        return '❓';
      case 'vendor_message':
        return '💬';
      case 'system_update':
        return '🔔';
      case 'promotion':
        return '🎉';
      case 'price_drop':
        return '💸';
      case 'back_in_stock':
        return '📈';
      default:
        return '📬';
    }
  }
}
