import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/app_screens.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/privacy_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/terms_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/providers/providers.dart';
import '../../features/splash/splash_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

// ============================================================================
// ROUTE CONSTANTS
// ============================================================================

class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String terms = '/terms';
  static const String privacy = '/privacy';

  // Shell tabs
  static const String shell = '/shell';
  static const String home = '/home';
  static const String challenges = '/challenges';
  static const String leaderboard = '/leaderboard';
  static const String activity = '/activity';
  static const String profile = '/profile';

  // Challenge & Quiz routes
  static const String quizInstructions = '/quiz-instructions/:challengeId';
  static const String quiz = '/quiz/:challengeId';
  static const String quizResults = '/quiz-results/:attemptId';
  static const String answerReview = '/answer-review/:attemptId';
  static const String codingChallenge = '/coding-challenge/:challengeId';

  // Other feature routes
  static const String achievements = '/achievements';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';

  // Admin routes
  static const String admin = '/admin';
  static const String createQuiz = '/admin/create-quiz';
  static const String editQuiz = '/admin/edit-quiz/:quizId';
  static const String manageUsers = '/admin/manage-users';

  // Helper route builders
  static String quizInstructionsPath(String challengeId) =>
      '/quiz-instructions/$challengeId';
  static String quizPath(String challengeId) => '/quiz/$challengeId';
  static String quizResultsPath(String attemptId) => '/quiz-results/$attemptId';
  static String answerReviewPath(String attemptId) =>
      '/answer-review/$attemptId';
  static String codingChallengePath(String challengeId) =>
      '/coding-challenge/$challengeId';
  static String editQuizPath(String quizId) => '/admin/edit-quiz/$quizId';
}

// ============================================================================
// ROUTER NOTIFIER (REACTIVE REFRESH)
// ============================================================================

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
    _ref.listen(onboardingCompleteProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}

final _routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

// ============================================================================
// MAIN SHELL (BOTTOM NAVIGATION BAR)
// ============================================================================

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.secondaryBackground,
          border: Border(
            top: BorderSide(color: AppColors.borderColor, width: 1),
          ),
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.18),
            elevation: 0,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: AppColors.primaryBlue,
                ),
                label: AppStrings.home,
              ),
              NavigationDestination(
                icon: Icon(Icons.bolt_outlined, color: AppColors.textSecondary),
                selectedIcon: Icon(
                  Icons.bolt_rounded,
                  color: AppColors.primaryBlue,
                ),
                label: AppStrings.challenges,
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.leaderboard_outlined,
                  color: AppColors.textSecondary,
                ),
                selectedIcon: Icon(
                  Icons.leaderboard_rounded,
                  color: AppColors.primaryBlue,
                ),
                label: AppStrings.leaderboard,
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.timeline_outlined,
                  color: AppColors.textSecondary,
                ),
                selectedIcon: Icon(
                  Icons.timeline_rounded,
                  color: AppColors.primaryBlue,
                ),
                label: AppStrings.activity,
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outlined,
                  color: AppColors.textSecondary,
                ),
                selectedIcon: Icon(
                  Icons.person_rounded,
                  color: AppColors.primaryBlue,
                ),
                label: AppStrings.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// GO ROUTER PROVIDER
// ============================================================================

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: routerNotifier,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) async {
      final loc = state.matchedLocation;

      // Allow splash to run without redirect interference
      if (loc == AppRoutes.splash) {
        return null;
      }

      // Public informational pages
      if (loc == AppRoutes.terms || loc == AppRoutes.privacy) {
        return null;
      }

      // Check storage for onboarding completion and auth state
      final prefs = await SharedPreferences.getInstance();
      final isOnboarded =
          prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;

      final authUser = ref.read(authStateProvider).value;
      final storedUser = prefs.getString(AppConstants.keyCurrentUser);
      final isDemoLoggedIn =
          prefs.getBool(AppConstants.keyDemoLoggedIn) ?? false;
      final isLoggedIn =
          authUser != null ||
          (storedUser != null && storedUser.isNotEmpty) ||
          isDemoLoggedIn;

      // 1. If not onboarded -> redirect to /onboarding
      if (!isOnboarded) {
        if (loc != AppRoutes.onboarding) {
          return AppRoutes.onboarding;
        }
        return null;
      }

      // 2. If onboarded but not logged in -> redirect to /login
      final isAuthRoute =
          loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.forgotPassword;

      if (!isLoggedIn) {
        if (!isAuthRoute && loc != AppRoutes.onboarding) {
          return AppRoutes.login;
        }
        return null;
      }

      // 3. If logged in and attempting to access auth or onboarding -> /home
      if (isLoggedIn && (isAuthRoute || loc == AppRoutes.onboarding)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (context, state) => const PrivacyScreen(),
      ),

      // Bottom Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.challenges,
                builder: (context, state) => const ChallengeCatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.leaderboard,
                builder: (context, state) =>
                    const AppFeatureScreen(feature: AppFeature.leaderboard),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.activity,
                builder: (context, state) =>
                    const AppFeatureScreen(feature: AppFeature.activity),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) =>
                    const AppFeatureScreen(feature: AppFeature.profile),
              ),
            ],
          ),
        ],
      ),

      // Challenge & Quiz Routes
      GoRoute(
        path: AppRoutes.quizInstructions,
        builder: (context, state) {
          final challengeId = state.pathParameters['challengeId'] ?? '';
          return ChallengeInstructionsScreen(challengeId: challengeId);
        },
      ),
      GoRoute(
        path: AppRoutes.quiz,
        builder: (context, state) {
          final challengeId = state.pathParameters['challengeId'] ?? '';
          return QuizSessionScreen(challengeId: challengeId);
        },
      ),
      GoRoute(
        path: AppRoutes.quizResults,
        builder: (context, state) {
          final attemptId = state.pathParameters['attemptId'] ?? '';
          return QuizResultScreen(attemptId: attemptId);
        },
      ),
      GoRoute(
        path: AppRoutes.answerReview,
        builder: (context, state) {
          final attemptId = state.pathParameters['attemptId'] ?? '';
          return QuizResultScreen(attemptId: attemptId, reviewOnly: true);
        },
      ),
      GoRoute(
        path: AppRoutes.codingChallenge,
        builder: (context, state) {
          final challengeId = state.pathParameters['challengeId'] ?? '';
          return CodingChallengeScreen(challengeId: challengeId);
        },
      ),

      // Achievements, Notifications, Settings, Profile
      GoRoute(
        path: AppRoutes.achievements,
        builder: (context, state) =>
            const AppFeatureScreen(feature: AppFeature.achievements),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) =>
            const AppFeatureScreen(feature: AppFeature.notifications),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) =>
            const AppFeatureScreen(feature: AppFeature.settings),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) =>
            const AppFeatureScreen(feature: AppFeature.editProfile),
      ),

      // Admin Routes
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) =>
            const AppFeatureScreen(feature: AppFeature.admin),
      ),
      GoRoute(
        path: AppRoutes.createQuiz,
        builder: (context, state) =>
            const AppFeatureScreen(feature: AppFeature.createQuiz),
      ),
      GoRoute(
        path: AppRoutes.editQuiz,
        builder: (context, state) {
          final quizId = state.pathParameters['quizId'] ?? '';
          return AppFeatureScreen(feature: AppFeature.editQuiz, itemId: quizId);
        },
      ),
      GoRoute(
        path: AppRoutes.manageUsers,
        builder: (context, state) =>
            const AppFeatureScreen(feature: AppFeature.manageUsers),
      ),
    ],
  );
});

// Alias for convenience as requested in prompt
final routerProvider = appRouterProvider;
