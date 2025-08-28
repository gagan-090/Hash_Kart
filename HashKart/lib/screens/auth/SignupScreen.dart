import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;

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
                  'Create your\naccount',
                  style: AppTheme.heading1.copyWith(fontSize: 28, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join us and start shopping today!',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                // Name Field
                CustomTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameController,
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppTheme.textLight,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email Field
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppTheme.textLight,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
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
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppTheme.textLight,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
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
                  hint: 'Confirm your password',
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppTheme.textLight,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
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
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Terms and Conditions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreeToTerms = !_agreeToTerms;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: RichText(
                            text: TextSpan(
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Sign Up Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return CustomButton(
                      text: 'Sign Up',
                      onPressed: authProvider.isLoading 
                          ? null 
                          : _agreeToTerms
                              ? _handleSignup
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please agree to the terms and conditions',
                                      ),
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                  );
                                },
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

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: AppTheme.borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _handleSignup() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final fullName = _nameController.text.trim();
      final nameParts = fullName.split(' ');
      
      final userData = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'password_confirm': _confirmPasswordController.text,
        'first_name': nameParts.isNotEmpty ? nameParts.first : 'User',
        'last_name': nameParts.length > 1 ? nameParts.skip(1).join(' ') : 'User',
        'user_type': 'customer',
      };
      
      final success = await authProvider.register(userData);
      
      if (mounted) {
        if (success) {
          // Registration successful - show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please check your email for verification.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          
          // Navigate to login screen
          NavigationHelper.goToLogin();
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Registration failed'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        }
      }
    }
  }

  void _handleSocialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider signup not implemented yet')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
