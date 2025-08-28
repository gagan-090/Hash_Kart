import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
        _startTimer();
      } else if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Header
              Text(
                'Verify your\nemail',
                style: AppTheme.heading1.copyWith(
                  fontSize: 28,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'We sent a verification code to\n'),
                    TextSpan(
                      text: 'user@example.com',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // OTP Input
              Text(
                'Enter verification code',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) => _buildOTPField(index)),
              ),
              const SizedBox(height: 32),
              
              // Resend Code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (_canResend)
                    TextButton(
                      onPressed: _resendCode,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Resend',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Resend in ${_resendTimer}s',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              
              // Verify Button
              CustomButton(
                text: 'Verify',
                onPressed: _isOTPComplete() ? _handleVerification : null,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPField(int index) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _controllers[index].text.isNotEmpty 
              ? AppTheme.primaryColor 
              : AppTheme.borderColor,
          width: _controllers[index].text.isNotEmpty ? 2 : 1,
        ),
      ),
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTheme.heading2.copyWith(
          color: AppTheme.textPrimary,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 3) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  bool _isOTPComplete() {
    return _controllers.every((controller) => controller.text.isNotEmpty);
  }

  void _handleVerification() async {
    if (_isOTPComplete()) {
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
            content: Text('Email verified successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        NavigationHelper.goToHome();
      }
    }
  }

  void _resendCode() {
    setState(() {
      _canResend = false;
      _resendTimer = 60;
    });
    _startTimer();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification code sent!')),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
