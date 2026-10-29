import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_duel/core/constants/app_colors.dart';
import 'package:daily_duel/core/constants/app_constants.dart';
import 'package:daily_duel/core/constants/app_strings.dart';

/// Three-step onboarding experience explaining the core value of DailyDuel:
/// 1. Learn Daily
/// 2. Beat the Clock
/// 3. Rise Through the Ranks
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingComplete, true);
    if (!mounted) return;
    context.go('/login');
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with Logo & Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Brand Mark
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),

                  // Skip Button
                  AnimatedOpacity(
                    opacity: _currentPage < 2 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: _currentPage < 2 ? _completeOnboarding : null,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Skip'),
                    ),
                  ),
                ],
              ),
            ),

            // Page View with 3 Onboarding Slides
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildSlide(
                    gradientColor: AppColors.generalKnowledgeColor,
                    illustration: _buildLearnDailyIllustration(),
                    title: 'Learn Every Day',
                    description:
                        'Join thousands of learners in daily quizzes covering general knowledge, programming, cloud computing, and more.',
                  ),
                  _buildSlide(
                    gradientColor: AppColors.warningAmber,
                    illustration: _buildBeatTheClockIllustration(),
                    title: 'Beat the Clock',
                    description:
                        'Face timed quizzes and coding challenges. Answer accurately, beat the countdown, and show your skills under pressure.',
                  ),
                  _buildSlide(
                    gradientColor: AppColors.secondaryViolet,
                    illustration: _buildRiseThroughRanksIllustration(),
                    title: 'Rise Through the Ranks',
                    description:
                        'Earn points, maintain daily streaks, unlock achievements, and climb to the top of global and weekly leaderboards.',
                  ),
                ],
              ),
            ),

            // Bottom Navigation Area (Indicators + Buttons)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 30 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: isActive ? AppColors.primaryGradient : null,
                          color: isActive ? null : AppColors.surfaceColor,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  // Action Buttons Row
                  Row(
                    children: [
                      // Back Button (shown if page > 0)
                      if (_currentPage > 0) ...[
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.borderColor,
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.textPrimary,
                            ),
                            onPressed: _previousPage,
                            tooltip: 'Back',
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],

                      // Primary Next / Get Started Button
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == 2 ? 'Get Started' : 'Next',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage == 2
                                      ? Icons.bolt_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an onboarding slide containing a custom illustration, title, and description.
  Widget _buildSlide({
    required Color gradientColor,
    required Widget illustration,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Box with Radial Glow
          Expanded(
            flex: 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle colored radial ambient glow behind illustration
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        gradientColor.withValues(alpha: 0.18),
                        gradientColor.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                illustration,
              ],
            ),
          ),

          // Slide Text
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Screen 1 Illustration: Learn Daily
  Widget _buildLearnDailyIllustration() {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer decorative concentric circle
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.borderColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
          ),
          // Inner dashed circle
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
          ),
          // Central Learning Badge
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E2F5D), Color(0xFF131D36)],
              ),
              border: Border.all(
                color: AppColors.generalKnowledgeColor.withValues(alpha: 0.6),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.generalKnowledgeColor.withValues(
                    alpha: 0.25,
                  ),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.psychology_rounded,
                size: 64,
                color: AppColors.generalKnowledgeColor,
              ),
            ),
          ),
          // Floating Badge: Coding
          Positioned(
            top: 24,
            left: 16,
            child: _buildFloatingBadge(
              icon: Icons.code_rounded,
              label: 'Programming',
              color: AppColors.programmingColor,
            ),
          ),
          // Floating Badge: Daily Quiz
          Positioned(
            top: 36,
            right: 8,
            child: _buildFloatingBadge(
              icon: Icons.quiz_rounded,
              label: 'Daily Quiz',
              color: AppColors.primaryBlue,
            ),
          ),
          // Floating Badge: 10+ Categories
          Positioned(
            bottom: 24,
            left: 20,
            child: _buildFloatingBadge(
              icon: Icons.auto_stories_rounded,
              label: '10+ Topics',
              color: AppColors.successGreen,
            ),
          ),
          // Floating Badge: Cloud
          Positioned(
            bottom: 34,
            right: 14,
            child: _buildFloatingBadge(
              icon: Icons.cloud_done_rounded,
              label: 'Cloud & DevOps',
              color: AppColors.infoBlue,
            ),
          ),
        ],
      ),
    );
  }

  /// Screen 2 Illustration: Beat the Clock
  Widget _buildBeatTheClockIllustration() {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress ring graphic
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.warningAmber.withValues(alpha: 0.2),
                width: 6,
              ),
            ),
          ),
          // Central Timer Disc
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C2417), Color(0xFF171324)],
              ),
              border: Border.all(
                color: AppColors.warningAmber.withValues(alpha: 0.8),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.warningAmber.withValues(alpha: 0.3),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 46,
                  color: AppColors.warningAmber,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '00:45',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warningAmber,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating Badge: Speed Bonus
          Positioned(
            top: 14,
            child: _buildFloatingBadge(
              icon: Icons.bolt_rounded,
              label: 'Speed Bonus +50',
              color: AppColors.warningAmber,
            ),
          ),
          // Floating Badge: Rapid Multiple Choice
          Positioned(
            left: 4,
            bottom: 46,
            child: _buildFloatingBadge(
              icon: Icons.check_circle_outline_rounded,
              label: '10 Questions',
              color: AppColors.successGreen,
            ),
          ),
          // Floating Badge: Multiplier
          Positioned(
            right: 8,
            bottom: 54,
            child: _buildFloatingBadge(
              icon: Icons.local_fire_department_rounded,
              label: 'Combo 2x',
              color: AppColors.errorRed,
            ),
          ),
        ],
      ),
    );
  }

  /// Screen 3 Illustration: Rise Through the Ranks
  Widget _buildRiseThroughRanksIllustration() {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient glow
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.secondaryViolet.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
          ),

          // Central Trophy Showcase
          Container(
            width: 136,
            height: 136,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C2245), Color(0xFF13192F)],
              ),
              border: Border.all(
                color: AppColors.goldColor.withValues(alpha: 0.8),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldColor.withValues(alpha: 0.25),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.emoji_events_rounded,
                size: 68,
                color: AppColors.goldColor,
              ),
            ),
          ),

          // Floating Rank 1 Medal Badge
          Positioned(
            top: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.goldColor.withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.military_tech_rounded,
                    color: AppColors.goldColor,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Rank #1 Global',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Streak Badge
          Positioned(
            bottom: 24,
            left: 12,
            child: _buildFloatingBadge(
              icon: Icons.local_fire_department_rounded,
              label: '7-Day Streak',
              color: const Color(0xFFF97316),
            ),
          ),

          // Floating Achievements Badge
          Positioned(
            bottom: 30,
            right: 8,
            child: _buildFloatingBadge(
              icon: Icons.stars_rounded,
              label: 'Top 10 Tier',
              color: AppColors.secondaryViolet,
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable floating illustration badge
  Widget _buildFloatingBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
