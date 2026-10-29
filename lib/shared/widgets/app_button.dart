import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

enum AppButtonStyle { primary, secondary, outline, text, danger }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.height,
    this.width,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.borderRadius,
    this.padding,
  });

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 52.0;
    final effectiveBorderRadius =
        borderRadius ?? AppConstants.buttonBorderRadius;
    final effectiveRadius = BorderRadius.circular(effectiveBorderRadius);

    Widget buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
        ] else if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 20, color: _getTextColor()),
          const SizedBox(width: AppConstants.spacingS),
        ],
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: fontSize ?? 15,
            fontWeight: fontWeight ?? FontWeight.w600,
            color: _getTextColor(),
            letterSpacing: 0.3,
          ),
        ),
        if (!isLoading && trailingIcon != null) ...[
          const SizedBox(width: AppConstants.spacingS),
          Icon(trailingIcon, size: 20, color: _getTextColor()),
        ],
      ],
    );

    Widget decoratedChild = Container(
      height: effectiveHeight,
      width: isFullWidth ? (width ?? double.infinity) : width,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
      decoration: _getBoxDecoration(effectiveRadius),
      alignment: Alignment.center,
      child: buttonContent,
    );

    return Opacity(
      opacity: _isDisabled ? 0.5 : 1.0,
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTap: _isDisabled ? null : onPressed,
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: decoratedChild,
        ),
      ),
    );
  }

  BoxDecoration _getBoxDecoration(BorderRadius radius) {
    if (backgroundColor != null) {
      return BoxDecoration(color: backgroundColor, borderRadius: radius);
    }

    switch (style) {
      case AppButtonStyle.primary:
        return BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case AppButtonStyle.secondary:
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.secondaryViolet, AppColors.secondaryVioletDark],
          ),
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryViolet.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case AppButtonStyle.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: radius,
          border: Border.all(color: AppColors.primaryBlue, width: 1.5),
        );
      case AppButtonStyle.text:
        return BoxDecoration(color: Colors.transparent, borderRadius: radius);
      case AppButtonStyle.danger:
        return BoxDecoration(
          gradient: AppColors.errorGradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.errorRed.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        );
    }
  }

  Color _getTextColor() {
    if (textColor != null) return textColor!;

    switch (style) {
      case AppButtonStyle.primary:
      case AppButtonStyle.secondary:
      case AppButtonStyle.danger:
        return AppColors.textPrimary;
      case AppButtonStyle.outline:
      case AppButtonStyle.text:
        return AppColors.primaryBlue;
    }
  }
}
