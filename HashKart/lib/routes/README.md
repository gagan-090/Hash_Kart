# Navigation System Documentation

This document explains how to use the navigation system in the HashKart Flutter app.

## Overview

The navigation system consists of two main files:
- `app_routes.dart`: Contains all route definitions and the route generator
- `navigation_helper.dart`: Provides convenient methods for navigation

## Usage

### Basic Navigation

```dart
import '../../routes/navigation_helper.dart';

// Navigate to a screen
NavigationHelper.goToLogin();

// Navigate and replace current screen
NavigationHelper.navigateAndReplace('/new-route');

// Navigate and clear all previous screens
NavigationHelper.goToHome(); // This uses navigateAndClearAll internally

// Go back
NavigationHelper.goBack();
```

### Available Navigation Methods

#### Auth Screens
- `NavigationHelper.goToSplash()`
- `NavigationHelper.goToOnboarding()`
- `NavigationHelper.goToLogin()`
- `NavigationHelper.goToSignup()`
- `NavigationHelper.goToForgotPassword()`
- `NavigationHelper.goToResetPassword()`
- `NavigationHelper.goToOTPVerification()`

#### Home Screens
- `NavigationHelper.goToHome()`
- `NavigationHelper.goToCategory()`
- `NavigationHelper.goToSubcategory()`
- `NavigationHelper.goToBrand()`
- `NavigationHelper.goToFlashSale()`
- `NavigationHelper.goToOffers()`

#### Product Screens
- `NavigationHelper.goToProductDetails()`
- `NavigationHelper.goToSearch()`
- `NavigationHelper.goToFilter()`
- `NavigationHelper.goToWishlist()`
- `NavigationHelper.goToSavedItems()`
- `NavigationHelper.goToRecentlyViewed()`
- `NavigationHelper.goToReviews()`

#### Cart Screens
- `NavigationHelper.goToCart()`
- `NavigationHelper.goToEmptyCart()`
- `NavigationHelper.goToCheckout()`
- `NavigationHelper.goToPaymentMethod()`
- `NavigationHelper.goToAddNewCard()`
- `NavigationHelper.goToAddAddress()`
- `NavigationHelper.goToCheckoutSuccess()`

#### Orders Screens
- `NavigationHelper.goToOrders()`
- `NavigationHelper.goToOrderDetails()`
- `NavigationHelper.goToTrackOrder()`
- `NavigationHelper.goToOrderSuccess()`
- `NavigationHelper.goToOrderRating()`

#### Account Screens
- `NavigationHelper.goToAccount()`
- `NavigationHelper.goToMyDetails()`
- `NavigationHelper.goToProfileEdit()`
- `NavigationHelper.goToAddressList()`
- `NavigationHelper.goToAddEditAddress()`
- `NavigationHelper.goToLogout()`

#### Settings Screens
- `NavigationHelper.goToSettings()`
- `NavigationHelper.goToNotificationSettings()`

#### Support Screens
- `NavigationHelper.goToHelpCenter()`
- `NavigationHelper.goToCustomerService()`
- `NavigationHelper.goToFAQs()`

#### Misc Screens
- `NavigationHelper.goToPrivacyPolicy()`
- `NavigationHelper.goToTermsConditions()`

### Passing Arguments

To pass arguments to a screen:

```dart
// Using the generic navigation method
NavigationHelper.navigateTo('/product-details', arguments: {
  'productId': '123',
  'productName': 'Sample Product'
});

// In the destination screen, retrieve arguments:
class ProductDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final productId = args?['productId'];
    final productName = args?['productName'];
    
    return Scaffold(
      appBar: AppBar(title: Text(productName ?? 'Product Details')),
      body: Text('Product ID: $productId'),
    );
  }
}
```

### Adding New Routes

1. Add the route name constant in `AppRoutes` class:
```dart
static const String newScreen = '/new-screen';
```

2. Add the route case in `generateRoute` method:
```dart
case newScreen:
  return MaterialPageRoute(builder: (_) => const NewScreen());
```

3. Add a navigation method in `NavigationHelper`:
```dart
static Future<void> goToNewScreen() => navigateTo(AppRoutes.newScreen);
```

### Best Practices

1. Always use `NavigationHelper` methods instead of direct `Navigator` calls
2. Use `goToHome()` for login success (clears navigation stack)
3. Use `goToCheckoutSuccess()` and `goToOrderSuccess()` for completion flows
4. Import navigation helper in screens that need navigation
5. Handle back button behavior appropriately in critical flows

### Example Implementation

```dart
import 'package:flutter/material.dart';
import '../../routes/navigation_helper.dart';

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => NavigationHelper.goToCart(),
          ),
        ],
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => NavigationHelper.goToProductDetails(),
            child: const Text('View Product'),
          ),
          ElevatedButton(
            onPressed: () => NavigationHelper.goToWishlist(),
            child: const Text('View Wishlist'),
          ),
          ElevatedButton(
            onPressed: () => NavigationHelper.goBack(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
```

This navigation system provides a clean, maintainable way to handle all screen transitions in your HashKart app.