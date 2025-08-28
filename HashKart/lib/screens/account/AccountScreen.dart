import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).refreshUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'My Account',
              style: AppTheme.heading3.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: AppTheme.textPrimary),
                onPressed: () => NavigationHelper.goToSettings(),
              ),
            ],
          ),
          body: authProvider.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: user?.profileImage != null 
                                    ? null 
                                    : AppTheme.primaryGradient,
                              ),
                              child: user?.profileImage != null
                                  ? ClipOval(
                                      child: Image.network(
                                        user!.profileImage!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: AppTheme.primaryGradient,
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.fullName ?? 'Unknown User',
                                    style: AppTheme.heading3,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.email ?? 'No email',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: user?.isEmailVerified == true
                                          ? AppTheme.successColor.withValues(alpha: 0.1)
                                          : AppTheme.accentColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user?.isEmailVerified == true
                                          ? 'Verified Member'
                                          : 'Unverified Account',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: user?.isEmailVerified == true
                                            ? AppTheme.successColor
                                            : AppTheme.accentColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  IconButton(
                    onPressed: () => NavigationHelper.goToProfileEdit(),
                    icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Quick Stats
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                      child:
                          _buildStatCard('Orders', '12', Icons.shopping_bag)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildStatCard('Wishlist', '8', Icons.favorite)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Reviews', '5', Icons.star)),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Menu Items
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildMenuItem(
                    'My Details',
                    Icons.person_outline,
                    () => NavigationHelper.goToMyDetails(),
                  ),
                  _buildMenuItem(
                    'Address Book',
                    Icons.location_on_outlined,
                    () => NavigationHelper.goToAddressList(),
                  ),
                  _buildMenuItem(
                    'My Orders',
                    Icons.shopping_bag_outlined,
                    () => NavigationHelper.goToOrders(),
                  ),
                  _buildMenuItem(
                    'Wishlist',
                    Icons.favorite_outline,
                    () => NavigationHelper.goToWishlist(),
                  ),
                  _buildMenuItem(
                    'Recently Viewed',
                    Icons.history,
                    () => NavigationHelper.goToRecentlyViewed(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Support & Settings
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildMenuItem(
                    'Help Center',
                    Icons.help_outline,
                    () => NavigationHelper.goToHelpCenter(),
                  ),
                  _buildMenuItem(
                    'Customer Service',
                    Icons.support_agent,
                    () => NavigationHelper.goToCustomerService(),
                  ),
                  _buildMenuItem(
                    'Settings',
                    Icons.settings_outlined,
                    () => NavigationHelper.goToSettings(),
                  ),
                  _buildMenuItem(
                    'Privacy Policy',
                    Icons.privacy_tip_outlined,
                    () => NavigationHelper.goToPrivacyPolicy(),
                  ),
                  _buildMenuItem(
                    'Terms & Conditions',
                    Icons.description_outlined,
                    () => NavigationHelper.goToTermsConditions(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Logout
            Container(
              color: Colors.white,
              child: _buildMenuItem(
                'Logout',
                Icons.logout,
                () => _showLogoutDialog(),
                isDestructive: true,
              ),
            ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.heading3.copyWith(
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? AppTheme.accentColor.withValues(alpha: 0.1)
              : AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppTheme.accentColor : AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTheme.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppTheme.accentColor : AppTheme.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textLight,
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: AppTheme.heading3,
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              NavigationHelper.goToLogin();
            },
            child: Text(
              'Logout',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
