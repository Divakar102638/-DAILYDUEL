import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import 'app_button.dart';

class EmptyStateWidget extends StatefulWidget {
  final IconData? icon;
  final String? emoji;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final Widget? customAction;
  final double iconSize;
  final Color? iconColor;
  final EdgeInsetsGeometry padding;

  const EmptyStateWidget({
    super.key,
    this.icon,
    this.emoji,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onActionPressed,
    this.customAction,
    this.iconSize = 72,
    this.iconColor,
    this.padding = const EdgeInsets.all(AppConstants.spacingXL),
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.longAnimation,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: widget.padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: widget.iconSize + 32,
                    height: widget.iconSize + 32,
                    decoration: BoxDecoration(
                      color: (widget.iconColor ?? AppColors.primaryBlue)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (widget.iconColor ?? AppColors.primaryBlue)
                            .withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: widget.emoji != null
                        ? Text(
                            widget.emoji!,
                            style: TextStyle(fontSize: widget.iconSize * 0.6),
                          )
                        : Icon(
                            widget.icon ?? Icons.inbox_outlined,
                            size: widget.iconSize,
                            color:
                                widget.iconColor ?? AppColors.primaryBlueLight,
                          ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingL),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                if (widget.customAction != null) ...[
                  const SizedBox(height: AppConstants.spacingXL),
                  widget.customAction!,
                ] else if (widget.actionText != null &&
                    widget.onActionPressed != null) ...[
                  const SizedBox(height: AppConstants.spacingXL),
                  AppButton(
                    text: widget.actionText!,
                    onPressed: widget.onActionPressed,
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
        ),
      ),
    );
  }
}
