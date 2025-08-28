import 'package:flutter/material.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Header
                Text(
                  'Forgot\nPassword?',
                  style: AppTheme.heading1.copyWith(
                    fontSize: 28,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Don\'t worry! It happens. Please enter the email address associated with your account.',
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
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Email Field
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textLight),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const Spacer(),
                
                // Send Code Button
                CustomButton(
                  text: 'Send Reset Code',
                  onPressed: _handleSendCode,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                
                // Back to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Remember your password? ',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => NavigationHelper.goToLogin(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Login',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSendCode() async {
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
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset code sent to your email!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        NavigationHelper.goToResetPassword();
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
