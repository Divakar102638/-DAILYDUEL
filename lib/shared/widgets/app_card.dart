import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class AppCard extends StatelessWidget {
  final Widget? child;
  final String? title;
  final String? subtitle;
  final Widget? headerLeading;
  final Widget? headerTrailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Border? border;
  final double? borderRadius;
  final bool showShadow;
  final Clip clipBehavior;

  const AppCard({
    super.key,
    this.child,
    this.title,
    this.subtitle,
    this.headerLeading,
    this.headerTrailing,
    this.onTap,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.gradient,
    this.border,
    this.borderRadius,
    this.showShadow = false,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = BorderRadius.circular(
      borderRadius ?? AppConstants.cardBorderRadius,
    );

    final hasHeader =
        title != null ||
        subtitle != null ||
        headerLeading != null ||
        headerTrailing != null;

    Widget cardBody = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasHeader) ...[
          Padding(
            padding: EdgeInsets.only(
              bottom: child != null ? AppConstants.spacingM : 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (headerLeading != null) ...[
                  headerLeading!,
                  const SizedBox(width: AppConstants.spacingS),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (headerTrailing != null) ...[
                  const SizedBox(width: AppConstants.spacingS),
                  headerTrailing!,
                ],
              ],
            ),
          ),
        ],
        ?child,
      ],
    );

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? AppColors.cardBackground)
            : null,
        gradient: gradient,
        borderRadius: effectiveRadius,
        border: border ?? Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: clipBehavior,
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTap: onTap,
          splashColor: onTap != null
              ? AppColors.primaryBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          highlightColor: onTap != null
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppConstants.spacingM),
            child: cardBody,
          ),
        ),
      ),
    );

    return content;
  }
}
