import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart'; // Commented out for now, using fallback animations
import 'dart:math';
import '../../routes/navigation_helper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> 
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  double _scrollProgress = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      title: 'Buy What\nYou Want',
      subtitle: 'Discover thousands of products from your favorite brands',
      animation: 'assets/animations/onboarding1.json',
      color: const Color(0xFF667EEA),
    ),
    OnboardingData(
      title: 'Fast\nDelivery',
      subtitle: 'Get your orders delivered quickly and safely to your doorstep',
      animation: 'assets/animations/onboarding2.json',
      color: const Color(0xFF764BA2),
    ),
    OnboardingData(
      title: 'Secure\nPayment',
      subtitle: 'Multiple payment options with bank-level security',
      animation: 'assets/animations/onboarding3.json',
      color: const Color(0xFF6C5CE7),
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _pageController.addListener(() {
      setState(() {
        _scrollProgress = _pageController.page ?? 0;
      });
    });
    
    // Start the fade animation
    _fadeController.forward();
  }

  Color _getBackgroundColor() {
    int currentIndex = _scrollProgress.floor();
    int nextIndex = min(currentIndex + 1, _onboardingData.length - 1);
    double pageOffset = _scrollProgress - currentIndex;

    return Color.lerp(
      _onboardingData[currentIndex].color,
      _onboardingData[nextIndex].color,
      pageOffset,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => NavigationHelper.goToLogin(),
                  child: Text(
                    'Skip',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return _buildAnimation(index);
                },
              ),
            ),
            
            // Bottom section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => _buildPageIndicator(index),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Buttons
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: (_scrollProgress.round() == _onboardingData.length - 1)
                        ? Column(
                            key: const ValueKey('lastPageButtons'),
                            children: [
                              CustomButton(
                                text: 'Get Started',
                                onPressed: () => NavigationHelper.goToLogin(),
                                backgroundColor: Colors.white,
                                textColor: _getBackgroundColor(),
                              ),
                              const SizedBox(height: 16),
                              CustomButton(
                                text: 'Continue as Guest',
                                onPressed: () => NavigationHelper.goToHome(),
                                isOutlined: true,
                                textColor: Colors.white,
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('nextButton'),
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Next',
                                  onPressed: () {
                                    _pageController.nextPage(
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  backgroundColor: Colors.white,
                                  textColor: _getBackgroundColor(),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimation(int index) {
    double pageOffset = _scrollProgress - index;
    double animationOpacity = 1.0 - pageOffset.abs();
    double animationTranslateY = pageOffset * 100;

    return Opacity(
      opacity: animationOpacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, animationTranslateY),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 300,
                height: 300,
                child: _buildAnimationWidget(index),
              ),
              const SizedBox(height: 60),
              Text(
                _onboardingData[index].title,
                style: AppTheme.heading1.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                _onboardingData[index].subtitle,
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationWidget(int index) {
    // For now, let's use fallback animations to ensure it works
    // You can switch back to Lottie later once we confirm the files are working
    return _buildFallbackAnimation(index);
    
    // Uncomment below to try Lottie animations again:
    /*
    return Lottie.asset(
      _onboardingData[index].animation,
      width: 300,
      height: 300,
      fit: BoxFit.contain,
      repeat: true,
      animate: true,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Lottie animation error: $error');
        return _buildFallbackAnimation(index);
      },
    );
    */
  }

  Widget _buildFallbackAnimation(int index) {
    // Fallback animated icons when Lottie fails
    final List<IconData> fallbackIcons = [
      Icons.shopping_bag_outlined,
      Icons.local_shipping_outlined,
      Icons.security_outlined,
    ];
    
    final List<String> fallbackTitles = [
      'Shop',
      'Deliver',
      'Secure',
    ];
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 3),
      tween: Tween(begin: 0.0, end: 2 * pi),
      builder: (context, value, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: value,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: -value, // Counter-rotate the icon
                    child: Icon(
                      fallbackIcons[index],
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              fallbackTitles[index],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPageIndicator(int index) {
    double selectedness = 1.0 - (_scrollProgress - index).abs();
    double size = 8.0 + (16.0 * selectedness.clamp(0.0, 1.0));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: size,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String animation;
  final Color color;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.animation,
    required this.color,
  });
}
