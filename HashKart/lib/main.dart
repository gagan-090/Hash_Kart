import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'routes/navigation_helper.dart';
import 'theme/app_theme.dart';
import 'providers/providers.dart';

void main() {
  runApp(const HashKartApp());
}

class HashKartApp extends StatelessWidget {
  const HashKartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, child) {
          return MaterialApp(
            title: 'HashKart - Multi-Vendor E-Commerce',
            navigatorKey: NavigationHelper.navigatorKey,
            theme: themeProvider.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return AppInitializer(child: child!);
            },
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  final Widget child;
  
  const AppInitializer({super.key, required this.child});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;
    
    try {
      // Initialize authentication
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();

      if (!mounted) return;

      // Initialize search provider
      final searchProvider = Provider.of<SearchProvider>(context, listen: false);
      await searchProvider.initialize();

      // Initialize payment provider
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      await paymentProvider.initialize();

      // Load essential data
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      await Future.wait([
        productProvider.fetchCategories(),
        productProvider.fetchFeaturedProducts(),
      ]);

      if (!mounted) return;

      // If user is authenticated, load user-specific data
      if (authProvider.isAuthenticated) {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        final orderProvider = Provider.of<OrderProvider>(context, listen: false);
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
        
        await Future.wait([
          cartProvider.initializeCart(),
          productProvider.fetchWishlist(),
          orderProvider.fetchOrders(refresh: true),
          notificationProvider.initialize(),
          vendorProvider.initializeVendor(),
        ]);
      }
    } catch (e) {
      if (mounted) {
        print('App initialization error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
