import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/notification_badge.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final int activityBadgeCount;
  final bool hasHomeNotification;

  const MainShell({
    super.key,
    required this.navigationShell,
    this.activityBadgeCount = 0,
    this.hasHomeNotification = false,
  });

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 64,
              indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.16),
              iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
                states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(
                    color: AppColors.primaryBlue,
                    size: 24,
                  );
                }
                return const IconThemeData(
                  color: AppColors.textTertiary,
                  size: 24,
                );
              }),
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
                states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  );
                }
                return GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => _onTap(context, index),
              destinations: [
                // 1. Home
                NavigationDestination(
                  icon: NotificationBadge.dot(
                    show: hasHomeNotification,
                    badgeColor: AppColors.primaryBlue,
                    child: const Icon(Icons.home_outlined),
                  ),
                  selectedIcon: NotificationBadge.dot(
                    show: hasHomeNotification,
                    badgeColor: AppColors.primaryBlue,
                    child: const Icon(Icons.home_rounded),
                  ),
                  label: AppStrings.home,
                  tooltip: AppStrings.home,
                ),

                // 2. Challenges
                const NavigationDestination(
                  icon: Icon(Icons.extension_outlined),
                  selectedIcon: Icon(Icons.extension_rounded),
                  label: AppStrings.challenges,
                  tooltip: AppStrings.challenges,
                ),

                // 3. Leaderboard
                const NavigationDestination(
                  icon: Icon(Icons.leaderboard_outlined),
                  selectedIcon: Icon(Icons.leaderboard_rounded),
                  label: AppStrings.leaderboard,
                  tooltip: AppStrings.leaderboard,
                ),

                // 4. Activity
                NavigationDestination(
                  icon: NotificationBadge(
                    count: activityBadgeCount,
                    child: const Icon(Icons.history_outlined),
                  ),
                  selectedIcon: NotificationBadge(
                    count: activityBadgeCount,
                    child: const Icon(Icons.history_rounded),
                  ),
                  label: AppStrings.activity,
                  tooltip: AppStrings.activity,
                ),

                // 5. Profile
                const NavigationDestination(
                  icon: Icon(Icons.person_outlined),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: AppStrings.profile,
                  tooltip: AppStrings.profile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
