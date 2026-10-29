import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import 'app_button.dart';

class ErrorStateWidget extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  const ErrorStateWidget({
    super.key,
    this.title,
    required this.message,
    this.onRetry,
    this.retryButtonText,
    this.icon,
    this.padding = const EdgeInsets.all(AppConstants.spacingXL),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.errorRed.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: 40,
                color: AppColors.errorRed,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              title ?? AppStrings.somethingWentWrong,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppConstants.spacingL),
              AppButton(
                text: retryButtonText ?? AppStrings.tryAgain,
                onPressed: onRetry,
                leadingIcon: Icons.refresh_rounded,
                isFullWidth: false,
                style: AppButtonStyle.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: AppConstants.spacingS,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
