import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

enum ProgressLabelPosition { right, top }

class ProgressBarWidget extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final bool isThin;
  final double? height;
  final bool showLabel;
  final ProgressLabelPosition labelPosition;
  final String? customLabel;
  final Color? backgroundColor;
  final Color? progressColor;
  final Gradient? gradient;
  final double? borderRadius;
  final Duration animationDuration;
  final Curve curve;

  const ProgressBarWidget({
    super.key,
    required this.value,
    this.isThin = false,
    this.height,
    this.showLabel = false,
    this.labelPosition = ProgressLabelPosition.right,
    this.customLabel,
    this.backgroundColor,
    this.progressColor,
    this.gradient,
    this.borderRadius,
    this.animationDuration = AppConstants.mediumAnimation,
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);
    final effectiveHeight = height ?? (isThin ? 4.0 : 8.0);
    final effectiveRadius = BorderRadius.circular(
      borderRadius ?? (effectiveHeight / 2),
    );

    final percentageText = customLabel ?? '${(clampedValue * 100).toInt()}%';

    Widget barContent = LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        return Stack(
          children: [
            // Background bar
            Container(
              height: effectiveHeight,
              width: maxWidth,
              decoration: BoxDecoration(
                color: backgroundColor ?? AppColors.surfaceColor,
                borderRadius: effectiveRadius,
              ),
            ),
            // Animated fill bar
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: clampedValue),
              duration: animationDuration,
              curve: curve,
              builder: (context, animValue, _) {
                return Container(
                  height: effectiveHeight,
                  width: maxWidth * animValue,
                  decoration: BoxDecoration(
                    color:
                        progressColor ??
                        (gradient == null ? null : Colors.transparent),
                    gradient: progressColor == null
                        ? (gradient ?? AppColors.primaryGradient)
                        : null,
                    borderRadius: effectiveRadius,
                  ),
                );
              },
            ),
          ],
        );
      },
    );

    if (!showLabel) {
      return barContent;
    }

    if (labelPosition == ProgressLabelPosition.top) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (customLabel != null)
                Text(
                  customLabel!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              Text(
                '${(clampedValue * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          barContent,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: barContent),
        const SizedBox(width: AppConstants.spacingS),
        Text(
          percentageText,
          style: GoogleFonts.poppins(
            fontSize: isThin ? 11 : 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
