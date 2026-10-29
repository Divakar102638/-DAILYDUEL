import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class DemoBanner extends StatefulWidget {
  final String text;
  final bool isDismissible;
  final VoidCallback? onDismissed;
  final EdgeInsetsGeometry margin;

  const DemoBanner({
    super.key,
    this.text = '⚡ DEMO DATA — Mock rankings and accounts only',
    this.isDismissible = true,
    this.onDismissed,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  /// Static non-dismissible variant
  const DemoBanner.statik({
    super.key,
    this.text = '⚡ DEMO DATA — Mock rankings and accounts only',
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  }) : isDismissible = false,
       onDismissed = null;

  @override
  State<DemoBanner> createState() => _DemoBannerState();
}

class _DemoBannerState extends State<DemoBanner> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: AppConstants.shortAnimation,
      curve: Curves.easeInOut,
      child: Container(
        margin: widget.margin,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warningAmber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.warningAmber.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.bolt_rounded,
              size: 18,
              color: AppColors.warningAmber,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.text,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.warningAmber,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (widget.isDismissible) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isDismissed = true;
                  });
                  widget.onDismissed?.call();
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.warningAmber.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
