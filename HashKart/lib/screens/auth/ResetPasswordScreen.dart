import 'package:flutter/material.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Header
                Text(
                  'Reset\nPassword',
                  style: AppTheme.heading1.copyWith(
                    fontSize: 28,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your new password must be different from previously used passwords.',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Illustration
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: AppTheme.successColor,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // New Password Field
                CustomTextField(
                  label: 'New Password',
                  hint: 'Enter new password',
                  controller: _newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textLight),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textLight,
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter new password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Confirm Password Field
                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Confirm new password',
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textLight),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textLight,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Password Requirements
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password must contain:',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRequirement('At least 8 characters', _newPasswordController.text.length >= 8),
                      _buildRequirement('One uppercase letter', RegExp(r'[A-Z]').hasMatch(_newPasswordController.text)),
                      _buildRequirement('One lowercase letter', RegExp(r'[a-z]').hasMatch(_newPasswordController.text)),
                      _buildRequirement('One number', RegExp(r'[0-9]').hasMatch(_newPasswordController.text)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Reset Password Button
                CustomButton(
                  text: 'Reset Password',
                  onPressed: _handleResetPassword,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isValid ? AppTheme.successColor : AppTheme.textLight,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTheme.bodySmall.copyWith(
              color: isValid ? AppTheme.successColor : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 40,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Password Reset Successful!',
                  style: AppTheme.heading3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your password has been reset successfully. You can now login with your new password.',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Back to Login',
                  onPressed: () {
                    Navigator.of(context).pop();
                    NavigationHelper.goToLogin();
                  },
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
