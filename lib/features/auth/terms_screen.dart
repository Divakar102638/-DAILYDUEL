import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:daily_duel/core/constants/app_colors.dart';
import 'package:daily_duel/core/constants/app_strings.dart';

/// Screen presenting the Terms and Conditions for the DailyDuel application.
/// Formats legal clauses in clean, readable cards with dedicated section icons.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        title: const Text(
          AppStrings.termsAndConditions,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Last updated: October 2026',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.gavel_rounded,
                          color: AppColors.textTertiary,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Terms of Service & Usage Agreement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Welcome to DailyDuel. Please review these Terms and Conditions carefully before using our daily challenge and quiz application. By creating an account or accessing the service, you agree to comply with and be bound by the following terms.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Section 1: Acceptance of Terms
              _buildSectionCard(
                icon: Icons.check_circle_outline_rounded,
                title: '1. Acceptance of Terms',
                body:
                    'By accessing or using the DailyDuel mobile application, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions as well as our Privacy Policy. If you do not agree with any part of these terms, you must discontinue using the application immediately.',
              ),

              // Section 2: Use of Service & License
              _buildSectionCard(
                icon: Icons.verified_user_outlined,
                title: '2. Use of Service & License',
                body:
                    'DailyDuel grants you a personal, revocable, non-exclusive, non-transferable, limited license to access and participate in daily quizzes, coding puzzles, and leaderboard contests strictly for personal, non-commercial educational purposes.',
              ),

              // Section 3: User Accounts & Responsibilities
              _buildSectionCard(
                icon: Icons.badge_outlined,
                title: '3. User Accounts & Responsibilities',
                body:
                    'To participate in competitive rankings, you may create an account by providing accurate and complete information. You are solely responsible for safeguarding your login credentials and for all activities that take place under your account. In this demo release, account data is stored locally on your device.',
              ),

              // Section 4: Daily Duels, Scoring & Fair Play
              _buildSectionCard(
                icon: Icons.sports_esports_outlined,
                title: '4. Scoring, Streaks & Fair Play',
                body:
                    'Scoring formulas, streak calculations, timer multipliers, and leaderboard ranks are governed automatically by DailyDuel application logic. Any attempt to use automated scripts, bots, reverse-engineered payloads, or network interceptors to falsify scores or solve times is strictly prohibited.',
              ),

              // Section 5: Intellectual Property
              _buildSectionCard(
                icon: Icons.copyright_rounded,
                title: '5. Intellectual Property',
                body:
                    'All intellectual property rights in the application—including software source code, graphics, branding, questions, UI designs, and database structures—are owned by DailyDuel and its contributors. You may not copy, modify, distribute, or reverse engineer any part without prior written authorization.',
              ),

              // Section 6: Privacy
              _buildSectionCard(
                icon: Icons.lock_outline_rounded,
                title: '6. Privacy & Data Handling',
                body:
                    'Your privacy is important to us. Please refer to our Privacy Policy for detailed information on how data is handled. In this local demonstration build, all statistics, profile details, and quiz progress are maintained entirely on your local device.',
              ),

              // Section 7: Disclaimer of Warranties
              _buildSectionCard(
                icon: Icons.warning_amber_rounded,
                title: '7. Disclaimer of Warranties',
                body:
                    'The DailyDuel platform is provided on an "AS IS" and "AS AVAILABLE" basis without warranties of any kind, whether express or implied. We do not warrant that the application will be error-free, uninterrupted, or that questions and answers will be completely free of typographical discrepancies.',
              ),

              // Section 8: Limitation of Liability
              _buildSectionCard(
                icon: Icons.shield_outlined,
                title: '8. Limitation of Liability',
                body:
                    'To the maximum extent permitted by applicable law, DailyDuel, its developers, and contributors shall not be liable for any direct, indirect, incidental, special, or consequential damages resulting from your use of or inability to access the platform.',
              ),

              // Section 9: Changes to Terms
              _buildSectionCard(
                icon: Icons.update_rounded,
                title: '9. Changes to Terms',
                body:
                    'We reserve the right to amend or replace these Terms and Conditions at any time. When updates occur, the "Last Updated" date at the top of this document will be revised accordingly. Your continued use of DailyDuel following any changes constitutes acceptance of the new terms.',
              ),

              // Section 10: Contact Us
              _buildSectionCard(
                icon: Icons.contact_support_outlined,
                title: '10. Contact Information',
                body:
                    'If you have questions, inquiries, or feedback regarding these Terms & Conditions, please contact our support team at legal@dailyduel.com.',
              ),

              const SizedBox(height: 20),

              // Confirmation Button
              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'I Understand',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
