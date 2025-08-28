class ApiConstants {
  // Your backend server - Updated to correct IP
  static const String baseUrl = 'http://192.168.1.4:8000/api';
  // Optional fallbacks for different environments (auto-tried by ApiService)
  static const List<String> fallbackBaseUrls = [
    'http://192.168.1.4:8000/api', // LAN PC
    'http://10.0.2.2:8000/api',     // Android emulator
    'http://127.0.0.1:8000/api',    // ADB reverse or local
  ];
  // For physical device testing, use: 'http://192.168.1.20:8000/api'
  // For Android emulator, use: 'http://10.0.2.2:8000/api'

  // Authentication endpoints
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String logout = '/auth/logout/';
  static const String logoutAll = '/auth/logout-all/';
  static const String refreshToken = '/auth/refresh/';
  static const String forgotPassword = '/auth/password-reset/';
  static const String confirmPasswordReset = '/auth/password-reset-confirm/';
  static const String verifyEmail = '/auth/verify-email/';
  static const String resendVerification = '/auth/resend-verification/';
  static const String requestOtp = '/auth/otp/request/';
  static const String verifyOtp = '/auth/otp/verify/';
  static const String userSessions = '/auth/sessions/';
  static const String socialAuth = '/auth/social/';

  // User endpoints
  static const String userProfile = '/users/profile/';
  static const String updateProfile = '/users/profile/update/';
  static const String userAddresses = '/users/addresses/';
  static const String userPreferences = '/users/preferences/';

  // Product endpoints
  static const String products = '/products/';
  static const String categories = '/products/categories/';
  static const String categoryTree = '/products/categories/tree/';
  static const String brands = '/products/brands/';
  static const String searchProducts = '/products/search/';
  static const String productDetail = '/products/';
  static const String productAttributes = '/products/attributes/';

  // Product reviews
  static const String productReviews = '/reviews/';
  static const String markReviewHelpful = '/reviews/{reviewId}/helpful/';

  // Vendor endpoints
  static const String vendors = '/vendors/';
  static const String vendorProducts = '/products/vendor/products/';
  static const String vendorProductDetail = '/products/vendor/products/';
  static const String uploadProductImages =
      '/products/vendor/products/{productId}/images/';
  static const String bulkProductUpdate =
      '/products/vendor/products/bulk-update/';
  static const String vendorProductStats = '/products/vendor/products/stats/';
  static const String productVariations =
      '/products/vendor/products/{productId}/variations/';

  // Order endpoints
  static const String orders = '/orders/';
  static const String createOrder = '/orders/checkout/create/';
  static const String orderDetails = '/orders/';
  static const String cancelOrder = '/orders/'; // Will be appended with {order_id}/cancel/
  static const String shippingMethods = '/orders/shipping-methods/';
  static const String coupons = '/orders/coupons/';
  static const String returns = '/orders/returns/';

  // Cart endpoints
  static const String cart = '/orders/cart/';
  static const String cartItems = '/orders/cart/items/';
  static const String addToCart = '/orders/cart/add/';
  static const String updateCartItem =
      '/orders/cart/items/'; // Will be appended with {item_id}/update/
  static const String removeFromCart =
      '/orders/cart/items/'; // Will be appended with {item_id}/remove/
  static const String clearCart = '/orders/cart/clear/';

  // Wishlist endpoints
  static const String wishlist = '/products/wishlist/';
  static const String addToWishlist = '/products/wishlist/add/';
  static const String removeFromWishlist =
      '/products/wishlist/{productId}/remove/';
  static const String wishlistToggle = '/products/wishlist/toggle/';

  // Notification endpoints
  static const String notifications = '/notifications/';
  static const String markNotificationRead =
      '/notifications/{notificationId}/read/';
  static const String markAllNotificationsRead =
      '/notifications/mark-all-read/';

  // Payment endpoints
  static const String paymentMethods = '/payments/methods/';
  static const String createPaymentOrder = '/payments/orders/create/';
  static const String verifyPayment = '/payments/verify/';
  static const String paymentStatus = '/payments/status/';
  static const String refundPayment = '/payments/refund/';
  static const String razorpayWebhook = '/payments/webhooks/razorpay/';

  // Analytics endpoints (if available)
  static const String analytics = '/analytics/';
  static const String orderAnalytics = '/analytics/orders/';

  // Razorpay Configuration
  static const String razorpayKeyId =
      'rzp_test_R7xVvdyoHrXAT3'; // Your actual test key
  static const String razorpayKeySecret =
      '0N4ChYZnK7BAn3j4eyi7vyfw'; // Your actual test secret

  // Payment Configuration
  static const String companyName = 'HashKart';
  static const String companyLogo = 'https://your-domain.com/logo.png';
  static const String supportEmail = 'support@hashkart.com';
  static const String supportPhone = '+91-9876543210';
}
