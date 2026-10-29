import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:daily_duel/core/constants/app_colors.dart';
import 'package:daily_duel/core/constants/app_strings.dart';

/// Screen displaying the Privacy Policy for DailyDuel.
/// Clearly details data practices and highlights local demo mode operation.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
          AppStrings.privacyPolicy,
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
                            color: AppColors.secondaryViolet.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.secondaryViolet.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Last updated: October 2026',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryViolet,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.security_rounded,
                          color: AppColors.textTertiary,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Your Privacy is Our Priority',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'DailyDuel is committed to transparency regarding the collection, use, and security of user data. This policy outlines how your information is handled when you use our daily challenges and quiz features.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Demo Mode Notice Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.warningAmber.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warningAmber,
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demo Mode Operation',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warningAmber,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Currently in demo mode - no real data is collected or stored on external servers. All authentication credentials, quiz results, streaks, and preferences reside solely on your local device storage.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Section 1: What We Collect
              _buildSectionCard(
                icon: Icons.folder_shared_outlined,
                title: '1. What We Collect',
                body:
                    'To deliver competitive quiz experiences, DailyDuel collects: (a) Profile information including name, chosen username, and email address; (b) Quiz performance data such as questions answered, completion time, score, and streak counts; (c) App preferences including dark mode, sound effects, and haptic feedback toggles.',
              ),

              // Section 2: How We Use Data
              _buildSectionCard(
                icon: Icons.insights_rounded,
                title: '2. How We Use Data',
                body:
                    'We use collected data solely for core app functions: delivering daily quizzes, calculating your rankings and streaks, displaying user stats, and tailoring challenge recommendations. We do not use your data for advertising targeting or behavioral tracking.',
              ),

              // Section 3: Data Storage & Local Persistence
              _buildSectionCard(
                icon: Icons.save_alt_rounded,
                title: '3. Data Storage & Local Persistence',
                body:
                    'All user data and performance metrics are stored locally on your device via sandboxed key-value storage (SharedPreferences). Clearing app data or uninstalling the app permanently purges all local records from your hardware.',
              ),

              // Section 4: Third Parties
              _buildSectionCard(
                icon: Icons.share_location_outlined,
                title: '4. Third-Party Sharing',
                body:
                    'DailyDuel does not sell, rent, monetize, or transmit your personal data to external third parties, data brokers, or advertising networks. External font assets (Google Fonts) and icons are bundled or cached in compliance with open-source guidelines.',
              ),

              // Section 5: Security
              _buildSectionCard(
                icon: Icons.lock_outline_rounded,
                title: '5. Security Measures',
                body:
                    'We design our data models following strict null-safety and input sanitization practices. Sensitive data stored on the client is restricted to the private application sandbox provided by your mobile operating system.',
              ),

              // Section 6: Children
              _buildSectionCard(
                icon: Icons.child_care_rounded,
                title: '6. Children\'s Privacy',
                body:
                    'DailyDuel is crafted for learners and developers aged 13 and older. We do not knowingly collect or solicit personal information from children under 13 years of age.',
              ),

              // Section 7: Changes
              _buildSectionCard(
                icon: Icons.history_rounded,
                title: '7. Changes to This Policy',
                body:
                    'We may update this Privacy Policy from time to time to accommodate new platform capabilities. Significant changes will be communicated through in-app release notes.',
              ),

              // Section 8: Contact
              _buildSectionCard(
                icon: Icons.mail_outline_rounded,
                title: '8. Contact Us',
                body:
                    'For privacy inquiries or requests to verify your data handling, you can contact our privacy officer at privacy@dailyduel.com.',
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
                    'Close',
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
                child: Icon(icon, size: 18, color: AppColors.secondaryViolet),
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
