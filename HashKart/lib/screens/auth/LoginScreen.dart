import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

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
                  'Login to your\naccount',
                  style: AppTheme.heading1.copyWith(
                    fontSize: 28,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back! Please enter your details',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Email Field
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
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
                const SizedBox(height: 20),
                
                // Password Field
                CustomTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textLight),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textLight,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => NavigationHelper.goToForgotPassword(),
                    child: Text(
                      'Forgot Password?',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Login Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return CustomButton(
                      text: 'Login',
                      onPressed: authProvider.isLoading ? null : _handleLogin,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppTheme.borderColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or continue with',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppTheme.borderColor)),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Social Login Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        'Google',
                        Icons.g_mobiledata,
                        () => _handleSocialLogin('google'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSocialButton(
                        'Facebook',
                        Icons.facebook,
                        () => _handleSocialLogin('facebook'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => NavigationHelper.goToSignup(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Sign Up',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String text, IconData icon, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: AppTheme.borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        
        if (success) {
          NavigationHelper.goToHome();
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Login failed'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        }
      }
    }
  }

  void _handleSocialLogin(String provider) {
    // Handle social login
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider login not implemented yet')),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
