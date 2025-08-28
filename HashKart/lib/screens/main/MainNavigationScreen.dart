import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/HomeScreen.dart';
import '../home/CategoryScreen.dart';
import '../product/WishlistScreen.dart';
import '../cart/CartScreen.dart';
import '../account/MyAccountScreen.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoryScreen(),
    const WishlistScreen(),
    const CartScreen(),
    const MyAccountScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.grid_view_outlined),
      activeIcon: Icon(Icons.grid_view),
      label: 'Categories',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.favorite_outline),
      activeIcon: Icon(Icons.favorite),
      label: 'Wishlist',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.shopping_cart_outlined),
      activeIcon: Icon(Icons.shopping_cart),
      label: 'Cart',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Account',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get initial tab from route arguments if provided
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final initialTab = args?['tab'] ?? 0;
    if (initialTab != _currentIndex) {
      _currentIndex = initialTab;
      _pageController.animateToPage(
        initialTab,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppTheme.primaryColor,
              unselectedItemColor: Colors.grey[600],
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              elevation: 0,
              items: _navItems.map((item) {
                // Add cart badge for cart tab
                if (item.label == 'Cart' && cartProvider.itemCount > 0) {
                  return BottomNavigationBarItem(
                    icon: Stack(
                      children: [
                        item.icon,
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              cartProvider.itemCount > 99 
                                  ? '99+' 
                                  : cartProvider.itemCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    activeIcon: Stack(
                      children: [
                        item.activeIcon,
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              cartProvider.itemCount > 99 
                                  ? '99+' 
                                  : cartProvider.itemCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    label: item.label,
                  );
                }
                return item;
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}