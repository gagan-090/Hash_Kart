import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({Key? key}) : super(key: key);

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ApiService _apiService = ApiService();
  
  // Dynamic data variables
  Map<String, dynamic>? _userProfile;
  List<dynamic> _recentlyViewed = [];
  Map<String, dynamic> _userStats = {
    'orders': 0,
    'wishlist': 0,
    'reviews': 0,
    'wallet_balance': 0,
    'loyalty_points': 0,
  };
  
  String selectedLanguage = 'English';
  bool _isLoading = true;
  bool showVerificationBanner = true;

  final List<String> languages = [
    'English',
    'हिंदी',
    'বাংলা',
    'தமிழ்',
    'తెలుগు',
    'ಕನ್ನಡ',
    'മലയാളം',
    'ગુજરાતી'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load user profile
      final profile = await _apiService.getUserProfile();
      
      // Load user stats
      final orders = await _apiService.getOrders(page: 1);
      final wishlist = await _apiService.getWishlist(page: 1);
      
      // Load recently viewed items (if available)
      try {
        // Assuming there's a recently viewed endpoint
        _recentlyViewed = []; // Will be populated when endpoint is available
      } catch (e) {
        _recentlyViewed = [];
      }

      setState(() {
        _userProfile = profile;
        _userStats = {
          'orders': orders.length,
          'wishlist': wishlist.length,
          'reviews': 0, // Will be updated when reviews endpoint is available
          'wallet_balance': profile['wallet_balance'] ?? 0,
          'loyalty_points': profile['loyalty_points'] ?? 0,
        };
        showVerificationBanner = !(profile['is_email_verified'] ?? false);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshUserData() async {
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshUserData,
              child: CustomScrollView(
                slivers: [
                  // Header Section
                  SliverToBoxAdapter(
                    child: _buildHeaderSection(),
                  ),
                  
                  // Quick Access Grid
                  SliverToBoxAdapter(
                    child: _buildQuickAccessGrid(),
                  ),
                  
                  // Recently Viewed Section
                  SliverToBoxAdapter(
                    child: _buildRecentlyViewedSection(),
                  ),
                  
                  // Verification Banner
                  if (showVerificationBanner)
                    SliverToBoxAdapter(
                      child: _buildVerificationBanner(),
                    ),
                  
                  // Finance Options
                  SliverToBoxAdapter(
                    child: _buildFinanceOptionsSection(),
                  ),
                  
                  // Language Selection
                  SliverToBoxAdapter(
                    child: _buildLanguageSection(),
                  ),
                  
                  // Account Settings
                  SliverToBoxAdapter(
                    child: _buildAccountSettingsSection(),
                  ),
                  
                  // My Activity
                  SliverToBoxAdapter(
                    child: _buildMyActivitySection(),
                  ),
                  
                  // Earn with Platform
                  SliverToBoxAdapter(
                    child: _buildEarnWithPlatformSection(),
                  ),
                  
                  // Feedback & Information
                  SliverToBoxAdapter(
                    child: _buildFeedbackSection(),
                  ),
                  
                  // Logout Button
                  SliverToBoxAdapter(
                    child: _buildLogoutButton(),
                  ),
                  
                  // Bottom spacing for navigation bar
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    final userName = _userProfile?['full_name'] ?? _userProfile?['first_name'] ?? 'User';
    final userEmail = _userProfile?['email'] ?? 'email@example.com';
    final membershipTier = _userProfile?['membership_tier'] ?? 'Silver';
    final walletBalance = _userStats['wallet_balance'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage: _userProfile?['profile_image'] != null
                  ? NetworkImage(_userProfile!['profile_image'])
                  : null,
              child: _userProfile?['profile_image'] == null
                  ? const Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        membershipTier,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.yellow[300],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '₹${walletBalance.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _navigateToProfile(),
            icon: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    final quickAccessItems = [
      {
        'icon': Icons.shopping_bag_outlined, 
        'label': 'Orders', 
        'color': Colors.blue,
        'count': _userStats['orders'],
        'onTap': () => _navigateToOrders(),
      },
      {
        'icon': Icons.favorite_outline, 
        'label': 'Wishlist', 
        'color': Colors.red,
        'count': _userStats['wishlist'],
        'onTap': () => _navigateToWishlist(),
      },
      {
        'icon': Icons.local_offer_outlined, 
        'label': 'Coupons', 
        'color': Colors.green,
        'count': 0,
        'onTap': () => _navigateToCoupons(),
      },
      {
        'icon': Icons.help_outline, 
        'label': 'Help Center', 
        'color': Colors.orange,
        'count': null,
        'onTap': () => _navigateToHelpCenter(),
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
        ),
        itemCount: quickAccessItems.length,
        itemBuilder: (context, index) {
          final item = quickAccessItems[index];
          return _buildQuickAccessCard(
            icon: item['icon'] as IconData,
            label: item['label'] as String,
            color: item['color'] as Color,
            count: item['count'] as int?,
            onTap: item['onTap'] as VoidCallback,
          );
        },
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String label,
    required Color color,
    int? count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            if (count != null && count > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyViewedSection() {
    if (_recentlyViewed.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Recently Viewed Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 100,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No recently viewed items',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Recently Viewed Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recentlyViewed.length,
              itemBuilder: (context, index) {
                final item = _recentlyViewed[index];
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: item['image'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  item['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.shopping_bag,
                                      color: Colors.grey[600],
                                      size: 24,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.shopping_bag,
                                color: Colors.grey[600],
                                size: 24,
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['name'] ?? 'Product',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify your Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Get latest updates of your orders',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _verifyEmail(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Verify',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                showVerificationBanner = false;
              });
            },
            child: Icon(
              Icons.close,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceOptionsSection() {
    final financeOptions = [
      {
        'icon': Icons.account_balance_wallet_outlined,
        'title': 'Personal Loan',
        'subtitle': 'Apply for instant personal loan',
        'color': Colors.purple,
      },
      {
        'icon': Icons.credit_card_outlined,
        'title': 'Credit Card',
        'subtitle': 'Get ₹1,500 Voucher + Limit ₹ 5% Cashback',
        'color': Colors.blue,
      },
      {
        'icon': Icons.payment_outlined,
        'title': 'Buy Now Pay Later / UPI Finance',
        'subtitle': 'Enjoy 3-step checkout and flexible payment',
        'color': Colors.green,
      },
    ];

    return _buildSection(
      title: 'Finance Options',
      child: Column(
        children: financeOptions.map((option) {
          return _buildListTile(
            icon: option['icon'] as IconData,
            title: option['title'] as String,
            subtitle: option['subtitle'] as String,
            iconColor: option['color'] as Color,
            onTap: () => _navigateToFinanceOption(option['title'] as String),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageSection() {
    return _buildSection(
      title: 'Try HashKart in your language',
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: languages.length,
          itemBuilder: (context, index) {
            final language = languages[index];
            final isSelected = language == selectedLanguage;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedLanguage = language;
                });
                _updateLanguagePreference(language);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[600] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  language,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccountSettingsSection() {
    final settingsOptions = [
      {'icon': Icons.star_outline, 'title': 'HashKart Plus', 'subtitle': null, 'onTap': () => _navigateToPlus()},
      {'icon': Icons.person_outline, 'title': 'Edit Profile', 'subtitle': null, 'onTap': () => _navigateToProfile()},
      {'icon': Icons.credit_card_outlined, 'title': 'Saved Cards', 'subtitle': null, 'onTap': () => _navigateToSavedCards()},
      {'icon': Icons.location_on_outlined, 'title': 'Saved Addresses', 'subtitle': null, 'onTap': () => _navigateToAddresses()},
      {'icon': Icons.language_outlined, 'title': 'Select Language', 'subtitle': null, 'onTap': () => _showLanguageSelector()},
      {'icon': Icons.notifications_outlined, 'title': 'Notification Settings', 'subtitle': null, 'onTap': () => _navigateToNotifications()},
      {'icon': Icons.privacy_tip_outlined, 'title': 'Privacy Center', 'subtitle': null, 'onTap': () => _navigateToPrivacy()},
    ];

    return _buildSection(
      title: 'Account Settings',
      child: Column(
        children: settingsOptions.map((option) {
          return _buildListTile(
            icon: option['icon'] as IconData,
            title: option['title'] as String,
            subtitle: option['subtitle'] as String?,
            onTap: option['onTap'] as VoidCallback,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMyActivitySection() {
    final activityOptions = [
      {'icon': Icons.rate_review_outlined, 'title': 'Reviews', 'onTap': () => _navigateToReviews()},
      {'icon': Icons.help_outline, 'title': 'Questions & Answers', 'onTap': () => _navigateToQA()},
    ];

    return _buildSection(
      title: 'My Activity',
      child: Column(
        children: activityOptions.map((option) {
          return _buildListTile(
            icon: option['icon'] as IconData,
            title: option['title'] as String,
            onTap: option['onTap'] as VoidCallback,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEarnWithPlatformSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => _navigateToVendorRegistration(),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[400]!, Colors.green[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.store_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Sell on HashKart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    final feedbackOptions = [
      {'icon': Icons.description_outlined, 'title': 'Terms, Policies & Licenses', 'onTap': () => _navigateToTerms()},
      {'icon': Icons.quiz_outlined, 'title': 'Browse FAQs', 'onTap': () => _navigateToFAQ()},
    ];

    return _buildSection(
      title: 'Feedback & Information',
      child: Column(
        children: feedbackOptions.map((option) {
          return _buildListTile(
            icon: option['icon'] as IconData,
            title: option['title'] as String,
            onTap: option['onTap'] as VoidCallback,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: OutlinedButton(
        onPressed: () {
          _showLogoutDialog();
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red[400]!, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout,
              color: Colors.red[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.blue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.blue[600],
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey[400],
        size: 16,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  // Navigation methods
  void _navigateToOrders() {
    try {
      NavigationHelper.goToOrders();
    } catch (e) {
      Navigator.pushNamed(context, '/orders');
    }
  }

  void _navigateToWishlist() {
    try {
      NavigationHelper.goToWishlist();
    } catch (e) {
      Navigator.pushNamed(context, '/wishlist');
    }
  }

  void _navigateToProfile() {
    try {
      NavigationHelper.goToProfileEdit();
    } catch (e) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  void _navigateToAddresses() {
    try {
      NavigationHelper.goToAddressList();
    } catch (e) {
      Navigator.pushNamed(context, '/addresses');
    }
  }

  void _navigateToHelpCenter() {
    try {
      NavigationHelper.goToHelpCenter();
    } catch (e) {
      Navigator.pushNamed(context, '/help');
    }
  }

  void _navigateToCoupons() {
    Navigator.pushNamed(context, '/coupons');
  }

  void _navigateToSavedCards() {
    Navigator.pushNamed(context, '/saved-cards');
  }

  void _navigateToNotifications() {
    Navigator.pushNamed(context, '/notification-settings');
  }

  void _navigateToPrivacy() {
    try {
      NavigationHelper.goToPrivacyPolicy();
    } catch (e) {
      Navigator.pushNamed(context, '/privacy');
    }
  }

  void _navigateToReviews() {
    Navigator.pushNamed(context, '/my-reviews');
  }

  void _navigateToQA() {
    Navigator.pushNamed(context, '/questions-answers');
  }

  void _navigateToVendorRegistration() {
    Navigator.pushNamed(context, '/vendor-register');
  }

  void _navigateToTerms() {
    try {
      NavigationHelper.goToTermsConditions();
    } catch (e) {
      Navigator.pushNamed(context, '/terms');
    }
  }

  void _navigateToFAQ() {
    Navigator.pushNamed(context, '/faq');
  }

  void _navigateToPlus() {
    Navigator.pushNamed(context, '/plus');
  }

  void _navigateToFinanceOption(String option) {
    Navigator.pushNamed(context, '/finance/$option');
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              ...languages.map((language) {
                return ListTile(
                  title: Text(language),
                  trailing: selectedLanguage == language
                      ? Icon(Icons.check, color: Colors.blue[600])
                      : null,
                  onTap: () {
                    setState(() {
                      selectedLanguage = language;
                    });
                    _updateLanguagePreference(language);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // Action methods
  Future<void> _verifyEmail() async {
    try {
      await _apiService.resendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateLanguagePreference(String language) async {
    try {
      // Update language preference via API if endpoint exists
      print('Language updated to: $language');
    } catch (e) {
      print('Error updating language: $e');
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}