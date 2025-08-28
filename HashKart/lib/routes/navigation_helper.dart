import 'package:flutter/material.dart';
import 'app_routes.dart';

class NavigationHelper {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Get current context
  static BuildContext? get context => navigatorKey.currentContext;

  // Navigate to a named route
  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
  }

  // Navigate and replace current route
  static Future<dynamic> navigateAndReplace(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed(routeName, arguments: arguments);
  }

  // Navigate and clear all previous routes
  static Future<dynamic> navigateAndClearAll(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  // Go back
  static void goBack([dynamic result]) {
    if (navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop(result);
    }
  }

  // Go back until specific route
  static void goBackUntil(String routeName) {
    navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
  }

  // Auth Navigation Methods
  static Future<void> goToSplash() => navigateAndClearAll(AppRoutes.splash);
  static Future<void> goToOnboarding() => navigateTo(AppRoutes.onboarding);
  static Future<void> goToLogin() => navigateTo(AppRoutes.login);
  static Future<void> goToSignup() => navigateTo(AppRoutes.signup);
  static Future<void> goToForgotPassword() => navigateTo(AppRoutes.forgotPassword);
  static Future<void> goToResetPassword() => navigateTo(AppRoutes.resetPassword);
  static Future<void> goToOTPVerification() => navigateTo(AppRoutes.otpVerification);

  // Home Navigation Methods
  static Future<void> goToHome() => navigateAndClearAll(AppRoutes.home);
  static Future<void> goToMainNavigation() => navigateAndClearAll(AppRoutes.home);
  
  // Tab Navigation Methods
  static Future<void> goToHomeTab() => navigateAndClearAll(AppRoutes.home, arguments: {'tab': 0});
  static Future<void> goToCategoriesTab() => navigateAndClearAll(AppRoutes.home, arguments: {'tab': 1});
  static Future<void> goToWishlistTab() => navigateAndClearAll(AppRoutes.home, arguments: {'tab': 2});
  static Future<void> goToCartTab() => navigateAndClearAll(AppRoutes.home, arguments: {'tab': 3});
  static Future<void> goToAccountTab() => navigateAndClearAll(AppRoutes.home, arguments: {'tab': 4});
  static Future<void> goToCategory() => goToCategoriesTab();
  static Future<void> goToSubcategory({String? categoryName, String? subcategoryName}) => 
    navigateTo(AppRoutes.subcategory, arguments: {
      'categoryName': categoryName,
      'subcategoryName': subcategoryName,
    });
  static Future<void> goToMobile() => navigateTo(AppRoutes.mobile);
  static Future<void> goToBrand() => navigateTo(AppRoutes.brand);
  static Future<void> goToFlashSale() => navigateTo(AppRoutes.flashSale);
  static Future<void> goToOffers() => navigateTo(AppRoutes.offers);

  // Product Navigation Methods
  static Future<void> goToProductDetails({Object? product}) => navigateTo(AppRoutes.productDetails, arguments: product);
  static Future<void> goToSearch() => navigateTo(AppRoutes.search);
  static Future<void> goToFilter() => navigateTo(AppRoutes.filter);
  static Future<void> goToWishlist() => goToWishlistTab();
  static Future<void> goToSavedItems() => navigateTo(AppRoutes.savedItems);
  static Future<void> goToRecentlyViewed() => navigateTo(AppRoutes.recentlyViewed);
  static Future<void> goToReviews() => navigateTo(AppRoutes.reviews);

  // Cart Navigation Methods
  static Future<void> goToCart() => goToCartTab();
  static Future<void> goToEmptyCart() => navigateTo(AppRoutes.emptyCart);
  static Future<void> goToCheckout() {
    print('NavigationHelper: Navigating to checkout...');
    print('NavigationHelper: Current navigator state: ${navigatorKey.currentState}');
    return navigateTo(AppRoutes.checkout);
  }
  static Future<void> goToPaymentMethod() => navigateTo(AppRoutes.paymentMethod);
  static Future<void> goToAddNewCard() => navigateTo(AppRoutes.addNewCard);
  static Future<void> goToAddAddress() => navigateTo(AppRoutes.addAddress);
  static Future<void> goToCheckoutSuccess() => navigateAndClearAll(AppRoutes.checkoutSuccess);

  // Orders Navigation Methods
  static Future<void> goToOrders() => navigateTo(AppRoutes.orders);
  static Future<void> goToOrderDetails({String? orderId, Object? order}) => 
    navigateTo(AppRoutes.orderDetails, arguments: {
      'orderId': orderId,
      'order': order,
    });
  static Future<void> goToTrackOrder() => navigateTo(AppRoutes.trackOrder);
  static Future<void> goToOrderSuccess() => navigateAndClearAll(AppRoutes.orderSuccess);
  static Future<void> goToOrderRating() => navigateTo(AppRoutes.orderRating);

  // Account Navigation Methods
  static Future<void> goToAccount() => goToAccountTab();
  static Future<void> goToMyDetails() => navigateTo(AppRoutes.myDetails);
  static Future<void> goToProfileEdit() => navigateTo(AppRoutes.profileEdit);
  static Future<void> goToAddressList() => navigateTo(AppRoutes.addressList);
  static Future<void> goToAddEditAddress() => navigateTo(AppRoutes.addEditAddress);
  static Future<void> goToLogout() => navigateTo(AppRoutes.logout);

  // Settings Navigation Methods
  static Future<void> goToSettings() => navigateTo(AppRoutes.settings);
  static Future<void> goToNotificationSettings() => navigateTo(AppRoutes.notificationSettings);

  // Support Navigation Methods
  static Future<void> goToHelpCenter() => navigateTo(AppRoutes.helpCenter);
  static Future<void> goToCustomerService() => navigateTo(AppRoutes.customerService);
  static Future<void> goToFAQs() => navigateTo(AppRoutes.faqs);

  // Misc Navigation Methods
  static Future<void> goToPrivacyPolicy() => navigateTo(AppRoutes.privacyPolicy);
  static Future<void> goToTermsConditions() => navigateTo(AppRoutes.termsConditions);
  
  // Product Listing Navigation
  static Future<void> goToProductListing({String? category, String? subCategory, String? categoryId}) => 
    navigateTo(AppRoutes.productListing, arguments: {
      'category': category,
      'subCategory': subCategory,
      'categoryId': categoryId,
    });
}




