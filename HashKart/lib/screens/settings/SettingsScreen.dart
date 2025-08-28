import 'package:flutter/material.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;
  bool _darkMode = false;
  bool _biometricAuth = true;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'USD';

  final List<String> _languages = ['English', 'Spanish', 'French', 'German', 'Chinese'];
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD'];

  @override
  Widget build(BuildContext context) {
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
          'Settings',
          style: AppTheme.heading3.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Notifications Section
            _buildSectionHeader('Notifications'),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Push Notifications',
                    'Receive push notifications on your device',
                    Icons.notifications_outlined,
                    _pushNotifications,
                    (value) => setState(() => _pushNotifications = value),
                  ),
                  _buildSwitchTile(
                    'Email Notifications',
                    'Receive notifications via email',
                    Icons.email_outlined,
                    _emailNotifications,
                    (value) => setState(() => _emailNotifications = value),
                  ),
                  _buildSwitchTile(
                    'SMS Notifications',
                    'Receive notifications via SMS',
                    Icons.sms_outlined,
                    _smsNotifications,
                    (value) => setState(() => _smsNotifications = value),
                  ),
                  _buildNavigationTile(
                    'Notification Settings',
                    'Manage detailed notification preferences',
                    Icons.tune,
                    () => NavigationHelper.goToNotificationSettings(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Appearance Section
            _buildSectionHeader('Appearance'),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Dark Mode',
                    'Use dark theme throughout the app',
                    Icons.dark_mode_outlined,
                    _darkMode,
                    (value) => setState(() => _darkMode = value),
                  ),
                  _buildDropdownTile(
                    'Language',
                    'Choose your preferred language',
                    Icons.language,
                    _selectedLanguage,
                    _languages,
                    (value) => setState(() => _selectedLanguage = value!),
                  ),
                  _buildDropdownTile(
                    'Currency',
                    'Select your preferred currency',
                    Icons.attach_money,
                    _selectedCurrency,
                    _currencies,
                    (value) => setState(() => _selectedCurrency = value!),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Security Section
            _buildSectionHeader('Security'),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Biometric Authentication',
                    'Use fingerprint or face ID to unlock',
                    Icons.fingerprint,
                    _biometricAuth,
                    (value) => setState(() => _biometricAuth = value),
                  ),
                  _buildNavigationTile(
                    'Change Password',
                    'Update your account password',
                    Icons.lock_outline,
                    () => NavigationHelper.goToResetPassword(),
                  ),
                  _buildNavigationTile(
                    'Two-Factor Authentication',
                    'Add an extra layer of security',
                    Icons.security,
                    () => _showComingSoonDialog('Two-Factor Authentication'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Account Section
            _buildSectionHeader('Account'),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildNavigationTile(
                    'Personal Information',
                    'Manage your account details',
                    Icons.person_outline,
                    () => NavigationHelper.goToMyDetails(),
                  ),
                  _buildNavigationTile(
                    'Address Book',
                    'Manage your delivery addresses',
                    Icons.location_on_outlined,
                    () => NavigationHelper.goToAddressList(),
                  ),
                  _buildNavigationTile(
                    'Payment Methods',
                    'Manage your payment options',
                    Icons.payment_outlined,
                    () => NavigationHelper.goToPaymentMethod(),
                  ),
                  _buildNavigationTile(
                    'Download My Data',
                    'Export your account data',
                    Icons.download_outlined,
                    () => _showComingSoonDialog('Data Export'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Support Section
            _buildSectionHeader('Support'),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildNavigationTile(
                    'Help Center',
                    'Get help and find answers',
                    Icons.help_outline,
                    () => NavigationHelper.goToHelpCenter(),
                  ),
                  _buildNavigationTile(
                    'Contact Support',
                    'Get in touch with our team',
                    Icons.support_agent_outlined,
                    () => NavigationHelper.goToCustomerService(),
                  ),
                  _buildNavigationTile(
                    'Report a Problem',
                    'Let us know about any issues',
                    Icons.bug_report_outlined,
                    () => _showComingSoonDialog('Problem Reporting'),
                  ),
                  _buildNavigationTile(
                    'Rate the App',
                    'Share your feedback on the app store',
                    Icons.star_outline,
                    () => _showComingSoonDialog('App Rating'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Legal Section
            _buildSectionHeader('Legal'),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildNavigationTile(
                    'Privacy Policy',
                    'Read our privacy policy',
                    Icons.privacy_tip_outlined,
                    () => NavigationHelper.goToPrivacyPolicy(),
                  ),
                  _buildNavigationTile(
                    'Terms of Service',
                    'Read our terms and conditions',
                    Icons.description_outlined,
                    () => NavigationHelper.goToTermsConditions(),
                  ),
                  _buildNavigationTile(
                    'Licenses',
                    'View open source licenses',
                    Icons.code,
                    () => _showComingSoonDialog('Open Source Licenses'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Danger Zone
            _buildSectionHeader('Account Actions'),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildNavigationTile(
                    'Delete Account',
                    'Permanently delete your account',
                    Icons.delete_outline,
                    _showDeleteAccountDialog,
                    isDestructive: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // App Version
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'HashKart',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(
        title,
        style: AppTheme.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTheme.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildNavigationTile(
    String title,
    String subtitle,
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
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.textSecondary,
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

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTheme.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Coming Soon',
          style: AppTheme.heading3,
        ),
        content: Text(
          '$feature will be available in a future update.',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Account',
          style: AppTheme.heading3.copyWith(
            color: AppTheme.accentColor,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
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
            onPressed: () {
              Navigator.pop(context);
              // Handle account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion requested'),
                  backgroundColor: AppTheme.accentColor,
                ),
              );
            },
            child: Text(
              'Delete',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
