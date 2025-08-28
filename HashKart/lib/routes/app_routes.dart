import 'package:flutter/material.dart';
import '../models/product_model.dart';

// Auth Screens

import '../screens/auth/SplashScreen.dart';
import '../screens/auth/OnboardingScreen.dart';
import '../screens/auth/LoginScreen.dart';
import '../screens/auth/SignupScreen.dart';
import '../screens/auth/ForgotPasswordScreen.dart';
import '../screens/auth/ResetPasswordScreen.dart';
import '../screens/auth/OTPVerificationScreen.dart';

// Home Screens

import '../screens/home/CategoryScreen.dart';
import '../screens/main/MainNavigationScreen.dart';
import '../screens/home/SubcategoryScreen.dart';
import '../screens/home/MobileScreen.dart';
import '../screens/home/BrandScreen.dart';
import '../screens/home/FlashSaleScreen.dart';
import '../screens/home/OffersScreen.dart';

// Product Screens
import '../screens/product/ProductDetailsScreen.dart';
import '../screens/product/SearchScreen.dart';
import '../screens/product/FilterScreen.dart';
import '../screens/product/WishlistScreen.dart';
import '../screens/product/SavedItemsScreen.dart';
import '../screens/product/RecentlyViewedScreen.dart';
import '../screens/product/ReviewsScreen.dart';

// Cart Screens
import '../screens/cart/CartScreen.dart';
import '../screens/cart/EmptyCartScreen.dart';
import '../screens/cart/CheckoutScreen.dart';
import '../screens/cart/PaymentMethodScreen.dart';
import '../screens/cart/AddNewCardScreen.dart';
import '../screens/cart/AddAddressScreen.dart';
import '../screens/cart/CheckoutSuccessScreen.dart';

// Orders Screens
import '../screens/orders/OrdersScreen.dart';
import '../screens/orders/OrderDetailsScreen.dart' as order_details;
import '../screens/orders/TrackOrderScreen.dart';
import '../screens/orders/OrderSuccessScreen.dart';
import '../screens/orders/OrderRatingScreen.dart';

// Account Screens
import '../screens/account/MyAccountScreen.dart';
import '../screens/account/MyDetailsScreen.dart';
import '../screens/account/ProfileEditScreen.dart';
import '../screens/account/AddressListScreen.dart';
import '../screens/account/AddEditAddressScreen.dart';
import '../screens/account/LogoutScreen.dart';

// Settings Screens
import '../screens/settings/SettingsScreen.dart';
import '../screens/settings/NotificationSettingsScreen.dart';

// Support Screens
import '../screens/support/HelpCenterScreen.dart';
import '../screens/support/CustomerServiceScreen.dart';
import '../screens/support/FAQsScreen.dart';

// Misc Screens
import '../screens/misc/PrivacyPolicyScreen.dart';
import '../screens/misc/TermsConditionsScreen.dart';
import '../screens/product/ProductListingScreen.dart';
import '../screens/demo/PaymentDemoScreen.dart';
import '../screens/demo/product_details_demo.dart';
import '../screens/demo/my_account_demo.dart';

class AppRoutes {
  // Route Names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String otpVerification = '/otp-verification';
  
  static const String home = '/home';
  static const String category = '/category';
  static const String subcategory = '/subcategory';
  static const String mobile = '/mobile';
  static const String brand = '/brand';
  static const String flashSale = '/flash-sale';
  static const String offers = '/offers';
  
  static const String productDetails = '/product-details';
  static const String search = '/search';
  static const String filter = '/filter';
  static const String wishlist = '/wishlist';
  static const String savedItems = '/saved-items';
  static const String recentlyViewed = '/recently-viewed';
  static const String reviews = '/reviews';
  
  static const String cart = '/cart';
  static const String emptyCart = '/empty-cart';
  static const String checkout = '/checkout';
  static const String paymentMethod = '/payment-method';
  static const String addNewCard = '/add-new-card';
  static const String addAddress = '/add-address';
  static const String checkoutSuccess = '/checkout-success';
  
  static const String orders = '/orders';
  static const String orderDetails = '/order-details';
  static const String trackOrder = '/track-order';
  static const String orderSuccess = '/order-success';
  static const String orderRating = '/order-rating';
  
  static const String account = '/account';
  static const String myDetails = '/my-details';
  static const String profileEdit = '/profile-edit';
  static const String addressList = '/address-list';
  static const String addEditAddress = '/add-edit-address';
  static const String logout = '/logout';
  
  static const String settings = '/settings';
  static const String notificationSettings = '/notification-settings';
  
  static const String helpCenter = '/help-center';
  static const String customerService = '/customer-service';
  static const String faqs = '/faqs';
  
  static const String privacyPolicy = '/privacy-policy';
  static const String termsConditions = '/terms-conditions';
  static const String productListing = '/product-listing';
  static const String paymentDemo = '/payment-demo';
  static const String productDetailsDemo = '/product-details-demo';
  static const String myAccountDemo = '/my-account-demo';

  // Route Generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth Routes
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case resetPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());
      case otpVerification:
        return MaterialPageRoute(builder: (_) => const OTPVerificationScreen());
      
      // Home Routes
      case home:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
          settings: settings,
        );
      case category:
        return MaterialPageRoute(builder: (_) => const CategoryScreen());
      case subcategory:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SubcategoryScreen(
            categoryName: args?['categoryName'],
            subcategoryName: args?['subcategoryName'],
          ),
        );
      case mobile:
        return MaterialPageRoute(builder: (_) => const MobileScreen());
      case brand:
        return MaterialPageRoute(builder: (_) => const BrandScreen());
      case flashSale:
        return MaterialPageRoute(builder: (_) => const FlashSaleScreen());
      case offers:
        return MaterialPageRoute(builder: (_) => const OffersScreen());
      
      // Product Routes
      case productDetails:
        final product = settings.arguments as Product;
        return MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product));

      case search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case filter:
        return MaterialPageRoute(builder: (_) => const FilterScreen());
      case wishlist:
        return MaterialPageRoute(builder: (_) => const WishlistScreen());
      case savedItems:
        return MaterialPageRoute(builder: (_) => const SavedItemsScreen());
      case recentlyViewed:
        return MaterialPageRoute(builder: (_) => const RecentlyViewedScreen());
      case reviews:
        return MaterialPageRoute(builder: (_) => const ReviewsScreen());
      
      // Cart Routes
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case emptyCart:
        return MaterialPageRoute(builder: (_) => const EmptyCartScreen());
      case checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());
      case paymentMethod:
        return MaterialPageRoute(builder: (_) => const PaymentMethodScreen());
      case addNewCard:
        return MaterialPageRoute(builder: (_) => const AddNewCardScreen());
      case addAddress:
        return MaterialPageRoute(builder: (_) => const AddAddressScreen());
      case checkoutSuccess:
        return MaterialPageRoute(builder: (_) => const CheckoutSuccessScreen());
      
      // Orders Routes
      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      case orderDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => order_details.OrderDetailsScreen(
            orderId: args?['orderId'],
          ),
        );
      case trackOrder:
        return MaterialPageRoute(builder: (_) => const TrackOrderScreen());
      case orderSuccess:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            paymentId: args?['paymentId'],
            amount: args?['amount'],
            orderId: args?['orderId'],
            paymentMethod: args?['paymentMethod'],
            paymentStatus: args?['paymentStatus'],
          ),
        );
      case orderRating:
        return MaterialPageRoute(builder: (_) => const OrderRatingScreen());
      
      // Account Routes
      case account:
        return MaterialPageRoute(builder: (_) => const MyAccountScreen());
      case myDetails:
        return MaterialPageRoute(builder: (_) => const MyDetailsScreen());
      case profileEdit:
        return MaterialPageRoute(builder: (_) => const ProfileEditScreen());
      case addressList:
        return MaterialPageRoute(builder: (_) => const AddressListScreen());
      case addEditAddress:
        return MaterialPageRoute(builder: (_) => const AddEditAddressScreen());
      case logout:
        return MaterialPageRoute(builder: (_) => const LogoutScreen());
      
      // Settings Routes
      case 'settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case notificationSettings:
        return MaterialPageRoute(builder: (_) => const NotificationSettingsScreen());
      
      // Support Routes
      case helpCenter:
        return MaterialPageRoute(builder: (_) => const HelpCenterScreen());
      case customerService:
        return MaterialPageRoute(builder: (_) => const CustomerServiceScreen());
      case faqs:
        return MaterialPageRoute(builder: (_) => const FAQsScreen());
      
      // Misc Routes
      case privacyPolicy:
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen());
      case termsConditions:
        return MaterialPageRoute(builder: (_) => const TermsConditionsScreen());
      
      // Product Listing Route
      case productListing:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ProductListingScreen(
            category: args?['category'] ?? 'All',
            subCategory: args?['subCategory'],
            categoryId: args?['categoryId'],
          ),
        );
      
      // Payment Demo Route
      case paymentDemo:
        return MaterialPageRoute(builder: (_) => const PaymentDemoScreen());
      
      // Product Details Demo Route
      case productDetailsDemo:
        return MaterialPageRoute(builder: (_) => const ProductDetailsDemo());
      
      // My Account Demo Route
      case myAccountDemo:
        return MaterialPageRoute(builder: (_) => const MyAccountDemo());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: const Center(
              child: Text('404 - Page Not Found'),
            ),
          ),
        );
    }
  }
}
