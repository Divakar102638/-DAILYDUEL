import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Fullscreen or centered loading spinner with optional message
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;
  final bool isFullScreen;

  const LoadingWidget({
    super.key,
    this.message,
    this.size = 36.0,
    this.color,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primaryBlue,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppConstants.spacingM),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );

    if (isFullScreen) {
      return Container(
        color: AppColors.primaryBackground,
        width: double.infinity,
        height: double.infinity,
        child: content,
      );
    }

    return content;
  }
}

/// Shimmer card placeholder for loading states
class ShimmerCard extends StatelessWidget {
  final double? width;
  final double? height;
  final double? borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Widget? child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerCard({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
    this.padding,
    this.child,
    this.baseColor,
    this.highlightColor,
  });

  /// Factory for a card-shaped shimmer box
  factory ShimmerCard.rectangular({
    Key? key,
    double? width,
    double height = 120,
    double? borderRadius,
    EdgeInsetsGeometry? margin,
  }) {
    return ShimmerCard(
      key: key,
      width: width ?? double.infinity,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    );
  }

  /// Factory for a challenge-card skeleton
  factory ShimmerCard.challengeSkeleton({
    Key? key,
    EdgeInsetsGeometry? margin,
  }) {
    return ShimmerCard(
      key: key,
      height: 140,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 16, width: 140, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(height: 12, width: 90, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 12, width: 70, color: Colors.white),
                Container(height: 12, width: 60, color: Colors.white),
                Container(
                  height: 28,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppConstants.cardBorderRadius;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Shimmer.fromColors(
        baseColor: baseColor ?? AppColors.cardBackground,
        highlightColor: highlightColor ?? AppColors.surfaceColor,
        child: child != null
            ? Container(
                width: width,
                height: height,
                padding: padding,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(effectiveRadius),
                  border: Border.all(color: AppColors.borderColor, width: 1),
                ),
                child: child,
              )
            : Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(effectiveRadius),
                ),
              ),
      ),
    );
  }
}

/// Semi-transparent loading overlay with spinner that blocks user interaction
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? barrierColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.barrierColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color:
                  barrierColor ??
                  AppColors.primaryBackground.withValues(alpha: 0.75),
              alignment: Alignment.center,
              child: LoadingWidget(message: message),
            ),
          ),
      ],
    );
  }
}
