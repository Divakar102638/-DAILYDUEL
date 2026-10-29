import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_duel/core/constants/app_colors.dart';
import 'package:daily_duel/core/constants/app_constants.dart';
import 'package:daily_duel/core/constants/app_strings.dart';

/// Premium animated splash screen for DailyDuel.
/// Features a glowing animated lightning bolt, gradient branding,
/// pulsating loading indicator, and route determination via SharedPreferences.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _glowController;
  late final AnimationController _textController;
  late final AnimationController _dotsController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // 1. Logo entry animation (scale + fade)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );

    _logoOpacity = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    // 2. Continuous breathing pulse for the bolt glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // 3. Text entrance (fade + upward slide)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textOpacity = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    _textSlide = Tween<Offset>(begin: const Offset(0.0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    // 4. Loading dots looping animation
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Sequence animations
    _logoController.forward().then((_) {
      if (mounted) {
        _textController.forward();
      }
    });

    // Schedule navigation after 2.5 seconds
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted || _navigated) return;
    _navigated = true;

    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete =
        prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;

    if (!mounted) return;

    if (!onboardingComplete) {
      context.go('/onboarding');
    } else {
      final demoLoggedIn = prefs.getBool(AppConstants.keyDemoLoggedIn) ?? false;
      final storedUser = prefs.getString(AppConstants.keyCurrentUser);
      if (demoLoggedIn || (storedUser != null && storedUser.isNotEmpty)) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _textController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.primaryBackground,
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.1,
            colors: [
              Color(0xFF1E2F5D),
              Color(0xFF131D36),
              AppColors.primaryBackground,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // Animated Lightning Bolt Logo with Glow
              AnimatedBuilder(
                animation: Listenable.merge([_logoController, _glowController]),
                builder: (context, child) {
                  final glowValue = _glowController.value;
                  final glowRadius = 24.0 + (glowValue * 18.0);
                  final glowOpacity = 0.35 + (glowValue * 0.35);

                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            // Outer violet/blue glow
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(
                                alpha: glowOpacity,
                              ),
                              blurRadius: glowRadius * 1.5,
                              spreadRadius: 4 + (glowValue * 6),
                            ),
                            BoxShadow(
                              color: AppColors.secondaryViolet.withValues(
                                alpha: glowOpacity * 0.8,
                              ),
                              blurRadius: glowRadius,
                              spreadRadius: 2,
                            ),
                          ],
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF263A6E), Color(0xFF16213D)],
                          ),
                          border: Border.all(
                            color: AppColors.primaryBlue.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                AppColors.primaryGradient.createShader(bounds),
                            child: const Icon(
                              Icons.bolt_rounded,
                              size: 68,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Animated Title & Tagline
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textOpacity,
                  child: Column(
                    children: [
                      // Gradient Brand Name
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.primaryBlue,
                            Color(0xFF9F75FF),
                            AppColors.secondaryViolet,
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          AppStrings.appName,
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tagline with decorative accent dashes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 18,
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.tagline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.9,
                              ),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 18,
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryViolet.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Animated Loading Dots at Bottom
              AnimatedBuilder(
                animation: _dotsController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final double delay = index * 0.25;
                      final double progress =
                          (_dotsController.value - delay) % 1.0;
                      final double scale =
                          0.7 + (0.5 * math.sin(progress * math.pi));
                      final double opacity =
                          0.3 + (0.7 * math.sin(progress * math.pi));

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.5),
                        width: 8 * scale,
                        height: 8 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == 1
                              ? AppColors.secondaryViolet.withValues(
                                  alpha: opacity.clamp(0.2, 1.0),
                                )
                              : AppColors.primaryBlue.withValues(
                                  alpha: opacity.clamp(0.2, 1.0),
                                ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (index == 1
                                          ? AppColors.secondaryViolet
                                          : AppColors.primaryBlue)
                                      .withValues(alpha: 0.4 * opacity),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),

              const SizedBox(height: 18),

              // Version indicator
              Text(
                'v${AppConstants.appVersion}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDisabled,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
