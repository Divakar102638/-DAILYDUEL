import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class NotificationBadge extends StatelessWidget {
  final Widget? child;
  final int count;
  final int maxCount;
  final Color? badgeColor;
  final Color? textColor;
  final Offset offset;
  final bool showZero;
  final bool isDot;

  const NotificationBadge({
    super.key,
    this.child,
    required this.count,
    this.maxCount = 99,
    this.badgeColor,
    this.textColor,
    this.offset = const Offset(6, -6),
    this.showZero = false,
    this.isDot = false,
  });

  /// Factory for a small dot indicator without numeric text
  factory NotificationBadge.dot({
    Key? key,
    Widget? child,
    bool show = true,
    Color? badgeColor,
    Offset offset = const Offset(4, -4),
  }) {
    return NotificationBadge(
      key: key,
      count: show ? 1 : 0,
      badgeColor: badgeColor,
      offset: offset,
      isDot: true,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shouldShow = count > 0 || (count == 0 && showZero);

    final badgeWidget = AnimatedScale(
      scale: shouldShow ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: Container(
        padding: isDot
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        constraints: BoxConstraints(
          minWidth: isDot ? 8 : 18,
          minHeight: isDot ? 8 : 18,
        ),
        decoration: BoxDecoration(
          color: badgeColor ?? AppColors.errorRed,
          shape: isDot ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isDot ? null : BorderRadius.circular(10),
          border: Border.all(color: AppColors.primaryBackground, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: (badgeColor ?? AppColors.errorRed).withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isDot
            ? null
            : Text(
                count > maxCount ? '$maxCount+' : '$count',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: textColor ?? Colors.white,
                  height: 1.1,
                ),
              ),
      ),
    );

    if (child == null) {
      return badgeWidget;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child!,
        Positioned(top: offset.dy, right: offset.dx, child: badgeWidget),
      ],
    );
  }
}
