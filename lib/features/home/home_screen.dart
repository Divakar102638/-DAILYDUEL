import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';

/// Complete Home Dashboard Screen for the DailyDuel Flutter App.
/// Displays greeting, user stats summary, countdown to next reset,
/// interactive daily challenges, quick actions, and recent activities.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Demo user data
  final Map<String, dynamic> demoUser = {
    'name': 'Alex Dev',
    'username': 'alexdev',
    'points': 2450,
    'streak': 7,
    'rank': 47,
    'weeklyProgress': 0.65,
  };

  // Daily challenges data
  final List<Map<String, dynamic>> dailyChallenges = [
    {
      'id': 'challenge-daily-gk',
      'title': 'General Knowledge',
      'category': 'General Knowledge',
      'description':
          'Test your general knowledge across science, history, geography, and culture.',
      'questions': 15,
      'timeLimit': '10 min',
      'points': 150,
      'status': 'available',
      'color': const Color(0xFF06B6D4),
      'icon': Icons.lightbulb_outline,
      'difficulty': 'Beginner',
      'route': '/quiz-instructions/challenge-daily-gk',
    },
    {
      'id': 'challenge-daily-tech',
      'title': 'Technical Quiz',
      'category': 'Programming',
      'description':
          'Programming, cloud computing, DevOps, and networking questions.',
      'questions': 20,
      'timeLimit': '15 min',
      'points': 200,
      'status': 'available',
      'color': const Color(0xFF8B5CF6),
      'icon': Icons.code,
      'difficulty': 'Intermediate',
      'languages': ['Dart', 'Python', 'JS'],
      'route': '/quiz-instructions/challenge-daily-tech',
    },
    {
      'id': 'challenge-daily-code',
      'title': 'Coding Challenge',
      'category': 'Coding',
      'description':
          'Solve a programming problem. Multiple languages supported.',
      'questions': 1,
      'timeLimit': '30 min',
      'points': 300,
      'status': 'available',
      'color': const Color(0xFF10B981),
      'icon': Icons.terminal,
      'difficulty': 'Intermediate',
      'route': '/coding-challenge/challenge-daily-code',
    },
  ];

  // Recent activity data
  final List<Map<String, dynamic>> recentActivities = [
    {
      'id': 'act-001',
      'title': 'Cloud Architecture & DevOps',
      'category': 'Technical Quiz',
      'icon': Icons.cloud_outlined,
      'timeAgo': '2 hours ago',
      'score': '190/200 pts',
      'accuracy': '95%',
      'status': 'Completed',
      'color': const Color(0xFF8B5CF6),
    },
    {
      'id': 'act-002',
      'title': 'World History & Civilizations',
      'category': 'General Knowledge',
      'icon': Icons.public,
      'timeAgo': 'Yesterday',
      'score': '135/150 pts',
      'accuracy': '90%',
      'status': 'Completed',
      'color': const Color(0xFF06B6D4),
    },
    {
      'id': 'act-003',
      'title': 'Binary Search Tree Balancing',
      'category': 'Coding Challenge',
      'icon': Icons.terminal,
      'timeAgo': '2 days ago',
      'score': '300/300 pts',
      'accuracy': '100%',
      'status': 'Completed',
      'color': const Color(0xFF10B981),
    },
  ];

  // Local state
  Timer? _countdownTimer;
  String _countdownText = '00:00:00';
  final Set<String> _completedChallengeIds = {};
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateCountdown();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Calculates real countdown to midnight
  void _updateCountdown() {
    final now = DateTime.now();
    final tomorrowMidnight = DateTime(now.year, now.month, now.day + 1);
    final remaining = tomorrowMidnight.difference(now);

    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    setState(() {
      _countdownText = '$hours:$minutes:$seconds';
    });
  }

  /// Greeting based on current time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning, Alex! ☀️';
    } else if (hour < 17) {
      return 'Good afternoon, Alex! 🌞';
    } else {
      return 'Good evening, Alex! 🌙';
    }
  }

  /// Navigation helper supporting both push and tab switching
  void _navigate(String path, {bool isTab = false}) {
    try {
      if (isTab) {
        context.go(path);
      } else {
        context.push(path);
      }
    } catch (e) {
      debugPrint('Navigation error to $path: $e');
    }
  }

  /// Toggle completed challenge state for demo interactivity
  void _toggleChallengeCompletion(String challengeId) {
    setState(() {
      if (_completedChallengeIds.contains(challengeId)) {
        _completedChallengeIds.remove(challengeId);
      } else {
        _completedChallengeIds.add(challengeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildAnimatedSection(
                      index: 0,
                      child: _buildGreetingSection(),
                    ),
                    const SizedBox(height: 20),
                    _buildAnimatedSection(
                      index: 1,
                      child: _buildUserSummaryCard(),
                    ),
                    const SizedBox(height: 24),
                    _buildAnimatedSection(
                      index: 2,
                      child: _buildDailyChallengesSection(),
                    ),
                    const SizedBox(height: 24),
                    _buildAnimatedSection(
                      index: 3,
                      child: _buildQuickActionsSection(),
                    ),
                    const SizedBox(height: 24),
                    _buildAnimatedSection(
                      index: 4,
                      child: _buildDailyActivitySection(),
                    ),
                    const SizedBox(height: 24),
                    _buildAnimatedSection(
                      index: 5,
                      child: _buildRecentActivitySection(),
                    ),
                    const SizedBox(height: 28),
                    _buildAnimatedSection(index: 6, child: _buildDemoBanner()),
                    const SizedBox(height: 100), // Bottom padding for nav bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Smooth staggered entrance animation wrapper
  Widget _buildAnimatedSection({required int index, required Widget child}) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300 + (index * 70)),
      curve: Curves.easeOutCubic,
      opacity: _isLoaded ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: Duration(milliseconds: 300 + (index * 70)),
        curve: Curves.easeOutCubic,
        offset: _isLoaded ? Offset.zero : const Offset(0, 0.05),
        child: child,
      ),
    );
  }

  /// Custom pinned SliverAppBar with gradient title, notification count badge & avatar
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: AppColors.primaryBackground.withValues(alpha: 0.96),
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      toolbarHeight: 68,
      titleSpacing: 20,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.secondaryViolet],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
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
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF60A5FA), Color(0xFFA78BFA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              AppStrings.appName,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Notification bell with badge count
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
                tooltip: 'Notifications',
                onPressed: () => _navigate('/notifications'),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryBackground,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 17,
                    minHeight: 17,
                  ),
                  child: Center(
                    child: Text(
                      '3',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Circle Avatar with initials 'AD'
        GestureDetector(
          onTap: () => _navigate('/profile', isTab: true),
          child: Container(
            margin: const EdgeInsets.only(right: 20, left: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.secondaryViolet],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.25),
                  blurRadius: 8,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.transparent,
              child: Text(
                'AD',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: AppColors.borderColor.withValues(alpha: 0.4),
          height: 1.0,
        ),
      ),
    );
  }

  /// Time-based greeting section
  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(),
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.readyForChallenges,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Dark summary card with gradient border and 2x2 stat grid
  Widget _buildUserSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.6),
            AppColors.secondaryViolet.withValues(alpha: 0.4),
            AppColors.borderColor.withValues(alpha: 0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.5), // Gradient border width
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(
            AppConstants.cardBorderRadius - 1.5,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF18233B), Color(0xFF121A2E)],
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Top row: User info & progress
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.military_tech_rounded,
                    color: AppColors.primaryBlueLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Target Progress',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '13 of 20 challenges completed this week',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.successGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '65%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(
                    height: 6,
                    color: AppColors.borderColor.withValues(alpha: 0.6),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.65,
                    child: Container(
                      height: 6,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryBlue,
                            AppColors.secondaryViolet,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.borderColor, height: 1),
            const SizedBox(height: 16),
            // 2x2 Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildSummaryStatItem(
                    icon: Icons.emoji_events_rounded,
                    iconColor: AppColors.warningAmber,
                    value: '2,450 pts',
                    label: 'Total Points',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryStatItem(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: const Color(0xFFF97316),
                    value: '7 days 🔥',
                    label: 'Current Streak',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryStatItem(
                    icon: Icons.leaderboard_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    value: '#47',
                    label: 'Global Rank',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryStatItem(
                    icon: Icons.insights_rounded,
                    iconColor: AppColors.successGreen,
                    value: '65%',
                    label: 'Weekly Goal',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Single Stat item in User Summary Card
  Widget _buildSummaryStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Daily challenges section with live countdown and three distinct challenge cards
  Widget _buildDailyChallengesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Title & Live Countdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.dailyChallenges,
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.warningAmber,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Resets in $_countdownText',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.warningAmber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Text(
                '${_completedChallengeIds.length}/3 Done',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Three Distinct Challenge Cards
        ...dailyChallenges.map((challenge) {
          final isCompleted = _completedChallengeIds.contains(challenge['id']);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _InteractiveChallengeCard(
              challenge: challenge,
              isCompleted: isCompleted,
              onTap: () => _navigate(challenge['route'] as String),
              onToggleComplete: () =>
                  _toggleChallengeCompletion(challenge['id'] as String),
            ),
          );
        }),
      ],
    );
  }

  /// Quick action tiles: Continue Challenge, View Leaderboard, Review Results, View Achievements
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.quickActions,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.play_circle_filled_rounded,
                color: AppColors.primaryBlue,
                label: 'Continue\nChallenge',
                onTap: () => _navigate('/challenges'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.leaderboard_rounded,
                color: AppColors.secondaryViolet,
                label: 'View\nLeaderboard',
                onTap: () => _navigate('/leaderboard', isTab: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.analytics_rounded,
                color: AppColors.successGreen,
                label: 'Review\nResults',
                onTap: () => _navigate('/activity'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.emoji_events_rounded,
                color: AppColors.warningAmber,
                label: 'View\nBadges',
                onTap: () => _navigate('/achievements'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Single quick action card
  Widget _buildQuickActionCard({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.15),
        highlightColor: color.withValues(alpha: 0.08),
        child: Container(
          height: 98,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderColor.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Daily activity overview row: Challenges, Accuracy, Points
  Widget _buildDailyActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.dailyActivity,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderColor.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildDailyActivityItem(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppColors.successGreen,
                  value: '2 Challenges',
                  subtitle: 'Done today',
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: AppColors.borderColor.withValues(alpha: 0.6),
              ),
              Expanded(
                child: _buildDailyActivityItem(
                  icon: Icons.pie_chart_outline_rounded,
                  iconColor: AppColors.primaryBlueLight,
                  value: '73% Accuracy',
                  subtitle: 'Daily average',
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: AppColors.borderColor.withValues(alpha: 0.6),
              ),
              Expanded(
                child: _buildDailyActivityItem(
                  icon: Icons.bolt_rounded,
                  iconColor: AppColors.warningAmber,
                  value: '350 Points',
                  subtitle: 'Earned today',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Item inside Daily Activity bar
  Widget _buildDailyActivityItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String subtitle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Recent activity list with 'View All' header and empty state support
  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.recentActivity,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _navigate('/activity'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.viewAll,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlueLight,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.primaryBlueLight,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentActivities.isEmpty)
          _buildEmptyRecentActivity()
        else
          ...recentActivities.map(
            (activity) => _buildRecentActivityCard(activity),
          ),
      ],
    );
  }

  /// Empty state card for recent activities
  Widget _buildEmptyRecentActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_toggle_off_rounded,
              size: 32,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No recent activity. Start your first challenge!',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Single recent activity card
  Widget _buildRecentActivityCard(Map<String, dynamic> activity) {
    final Color categoryColor = activity['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: categoryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      activity['timeAgo'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      activity['score'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warningAmber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.successGreen.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: AppColors.successGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  'Done',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Small amber demo banner at the bottom
  Widget _buildDemoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warningAmber.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bolt_rounded,
            size: 16,
            color: AppColors.warningAmber,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              AppStrings.demoDataNote,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.warningAmber,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive challenge card with tactile scale animation, distinct visual identity,
/// left colored border, glowing icon, badges, info row, and gradient action button.
class _InteractiveChallengeCard extends StatefulWidget {
  final Map<String, dynamic> challenge;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;

  const _InteractiveChallengeCard({
    required this.challenge,
    required this.isCompleted,
    required this.onTap,
    required this.onToggleComplete,
  });

  @override
  State<_InteractiveChallengeCard> createState() =>
      _InteractiveChallengeCardState();
}

class _InteractiveChallengeCardState extends State<_InteractiveChallengeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    final isCompleted = widget.isCompleted;
    final Color accentColor = challenge['color'] as Color;
    final String title = challenge['title'] as String;
    final String description = challenge['description'] as String;
    final IconData icon = challenge['icon'] as IconData;
    final int questions = challenge['questions'] as int;
    final String timeLimit = challenge['timeLimit'] as String;
    final int points = challenge['points'] as int;
    final List<String>? languages = challenge['languages'] as List<String>?;
    final String? difficulty = challenge['difficulty'] as String?;
    final bool isCoding = challenge['id'] == 'code-001';

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          border: Border(
            left: BorderSide(color: accentColor, width: 4.5),
            top: BorderSide(
              color: AppColors.borderColor.withValues(alpha: 0.55),
              width: 1,
            ),
            right: BorderSide(
              color: AppColors.borderColor.withValues(alpha: 0.55),
              width: 1,
            ),
            bottom: BorderSide(
              color: AppColors.borderColor.withValues(alpha: 0.55),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _pressController.forward(),
            onTapUp: (_) => _pressController.reverse(),
            onTapCancel: () => _pressController.reverse(),
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            splashColor: accentColor.withValues(alpha: 0.12),
            highlightColor: accentColor.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Category Icon + Title + Status Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Icon with glowing background
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: accentColor, size: 26),
                      ),
                      const SizedBox(width: 14),
                      // Title and Category Label
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              challenge['category'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Badge (Interactive toggle for demo)
                      GestureDetector(
                        onTap: widget.onToggleComplete,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.successGreen.withValues(alpha: 0.15)
                                : AppColors.successGreen.withValues(
                                    alpha: 0.12,
                                  ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isCompleted
                                  ? AppColors.successGreen
                                  : AppColors.successGreen.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isCompleted) ...[
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: AppColors.successGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'COMPLETED',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.successGreen,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.successGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'AVAILABLE',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.successGreen,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  // Languages Row for Technical Quiz
                  if (languages != null && languages.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Languages: ',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        ...languages.map((lang) {
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.borderColor.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            child: Text(
                              lang,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                  // Difficulty badge for Coding Challenge
                  if (difficulty != null && isCoding) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Difficulty: ',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warningAmber.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.warningAmber.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Text(
                            difficulty,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warningAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  // Info Row: Questions / Time / Points
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground.withValues(
                        alpha: 0.6,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.borderColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildChallengeInfoItem(
                          icon: isCoding
                              ? Icons.code_rounded
                              : Icons.help_outline_rounded,
                          label: isCoding
                              ? '$questions Problem'
                              : '$questions Questions',
                          color: AppColors.textSecondary,
                        ),
                        Container(
                          width: 1,
                          height: 14,
                          color: AppColors.borderColor,
                        ),
                        _buildChallengeInfoItem(
                          icon: Icons.access_time_rounded,
                          label: timeLimit,
                          color: AppColors.textSecondary,
                        ),
                        Container(
                          width: 1,
                          height: 14,
                          color: AppColors.borderColor,
                        ),
                        _buildChallengeInfoItem(
                          icon: Icons.stars_rounded,
                          label: '$points pts',
                          color: AppColors.warningAmber,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? null
                            : LinearGradient(
                                colors: [
                                  accentColor,
                                  accentColor.withValues(alpha: 0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: isCompleted
                            ? AppColors.successGreen.withValues(alpha: 0.15)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        border: isCompleted
                            ? Border.all(
                                color: AppColors.successGreen.withValues(
                                  alpha: 0.5,
                                ),
                              )
                            : null,
                        boxShadow: isCompleted
                            ? null
                            : [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: ElevatedButton(
                        onPressed: widget.onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isCompleted) ...[
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppColors.successGreen,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Completed ✓',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.successGreen,
                                ),
                              ),
                            ] else ...[
                              Text(
                                isCoding
                                    ? AppStrings.solveChallenge
                                    : AppStrings.startChallenge,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Small chip in info row
  Widget _buildChallengeInfoItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
