import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _screenFadeAnimation;

  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Screen fade animation controller
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Logo scale animation
    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Logo fade animation
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Screen fade out animation
    _screenFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start logo animation
    _logoAnimationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Simulate app initialization tasks
      await Future.wait([
        _checkAuthenticationStatus(),
        _loadUserPreferences(),
        _fetchMarketplaceConfig(),
        _prepareCachedData(),
      ]);

      setState(() {
      });

      // Wait for minimum splash duration
      await Future.delayed(const Duration(milliseconds: 2500));

      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize app. Please try again.';
      });

      // Show retry option after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _hasError) {
          _showRetryOption();
        }
      });
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    // Simulate checking authentication
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _loadUserPreferences() async {
    // Simulate loading user preferences
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _fetchMarketplaceConfig() async {
    // Simulate fetching marketplace configuration
    await Future.delayed(const Duration(milliseconds: 700));
  }

  Future<void> _prepareCachedData() async {
    // Simulate preparing cached product data
    await Future.delayed(const Duration(milliseconds: 400));
  }

  void _navigateToNextScreen() {
    _fadeAnimationController.forward().then((_) {
      if (mounted) {
        // Public landing: Consumer Marketplace. Protected pages will guard themselves.
        Navigator.pushReplacementNamed(context, '/consumer-marketplace');
      }
    });
  }

  void _showRetryOption() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: Text(
            'Connection Error',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            _errorMessage,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _hasError = false;
                  _errorMessage = '';
                });
                _initializeApp();
              },
              child: Text(
                'Retry',
                style: TextStyle(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide status bar on Android, match brand color on iOS
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppTheme.lightTheme.colorScheme.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: AnimatedBuilder(
        animation: _screenFadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _screenFadeAnimation.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: AppTheme.lightTheme.colorScheme.primary,
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Top spacing to help center content on tall screens
                            SizedBox(height: 8.h),

                            // Animated Logo Section
                            AnimatedBuilder(
                              animation: _logoAnimationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _logoScaleAnimation.value,
                                  child: Opacity(
                                    opacity: _logoFadeAnimation.value,
                                    child: _buildLogoSection(),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 8.h),

                            // Loading Indicator
                            _buildLoadingSection(),

                            SizedBox(height: 6.h),

                            // Bottom Branding
                            _buildBottomBranding(),

                            SizedBox(height: 4.h),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // White circular logo with green icon
        Container(
          width: 28.w,
          height: 28.w,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        SizedBox(height: 3.h),

        // App Name
        Text(
          'FarmMarket',
          style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.surface,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),

        SizedBox(height: 1.h),

        // Tagline
        Text(
          'Connecting Farmers & Consumers',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color:
                AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.9),
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        // Loading indicator
        SizedBox(
          width: 8.w,
          height: 8.w,
          child: CircularProgressIndicator(
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.lightTheme.colorScheme.surface,
            ),
            backgroundColor:
                AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.3),
          ),
        ),

        SizedBox(height: 2.h),

        // Loading text
        Text(
          _hasError ? 'Connection Error' : 'Initializing...',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color:
                AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBranding() {
    return Column(
      children: [
        // Version info
        Text(
          'Version 1.0.0',
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color:
                AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.7),
          ),
        ),

        SizedBox(height: 1.h),

        // Copyright
        Text(
          '© 2024 FarmMarket. All rights reserved.',
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color:
                AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
