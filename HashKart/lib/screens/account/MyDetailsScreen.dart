import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';

class MyDetailsScreen extends StatefulWidget {
  const MyDetailsScreen({super.key});

  @override
  State<MyDetailsScreen> createState() => _MyDetailsScreenState();
}

class _MyDetailsScreenState extends State<MyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  String _selectedGender = 'Not specified';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _dobController.text = user.dateOfBirth ?? '';
      _selectedGender = 'Not specified'; // Gender not in current user model
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile(AuthProvider authProvider) async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final profileData = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'date_of_birth': _dobController.text.trim().isNotEmpty 
          ? _dobController.text.trim() 
          : null,
    };

    final success = await authProvider.updateUserProfile(profileData);
    
    if (success) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to update profile'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
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
              'My Details',
              style: AppTheme.heading3.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isEditing 
                    ? () => _saveProfile(authProvider)
                    : () => _toggleEditing(),
                child: Text(
                  _isEditing ? 'Save' : 'Edit',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Picture Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'John Doe',
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Premium Member',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Personal Information
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: AppTheme.heading3.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'First Name',
                            controller: _firstNameController,
                            enabled: _isEditing,
                            validator: (value) {
                              if (value?.trim().isEmpty == true) {
                                return 'First name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            label: 'Last Name',
                            controller: _lastNameController,
                            enabled: _isEditing,
                            validator: (value) {
                              if (value?.trim().isEmpty == true) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      label: 'Email Address',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: false,
                      suffixIcon: const Icon(Icons.verified, color: AppTheme.successColor),
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: _isEditing,
                      suffixIcon: authProvider.user?.isPhoneVerified == true
                          ? const Icon(Icons.verified, color: AppTheme.successColor)
                          : null,
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      label: 'Date of Birth',
                      controller: _dobController,
                      enabled: _isEditing,
                      suffixIcon: const Icon(Icons.calendar_today, color: AppTheme.textLight),
                      readOnly: true,
                      onTap: _isEditing ? () => _selectDate(context) : null,
                    ),
                    const SizedBox(height: 20),

                    // Gender Selection
                    Text(
                      'Gender',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedGender,
                            style: AppTheme.bodyMedium,
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down, color: AppTheme.textLight),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Account Statistics
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Statistics',
                    style: AppTheme.heading3.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(child: _buildStatItem('Member Since', 'Jan 2023')),
                      Expanded(child: _buildStatItem('Total Orders', '12')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildStatItem('Total Spent', 'Rs.1,02,800')),
                      Expanded(child: _buildStatItem('Loyalty Points', '2,450')),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Account Actions
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.security, color: AppTheme.primaryColor),
                    title: Text(
                      'Change Password',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textLight),
                    onTap: () => NavigationHelper.goToResetPassword(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications, color: AppTheme.primaryColor),
                    title: Text(
                      'Notification Settings',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textLight),
                    onTap: () => NavigationHelper.goToNotificationSettings(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                    title: Text(
                      'Delete Account',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textLight),
                    onTap: () => _showDeleteAccountDialog(),
                  ),
                ],
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

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
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
            color: AppTheme.errorColor,
          ),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
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
            },
            child: Text(
              'Delete',
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
