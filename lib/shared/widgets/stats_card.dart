import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import 'app_card.dart';

class StatItem {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final String? trend;
  final bool isPositiveTrend;
  final VoidCallback? onTap;

  const StatItem({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.trend,
    this.isPositiveTrend = true,
    this.onTap,
  });
}

class StatsCard extends StatelessWidget {
  final List<StatItem> items;
  final int crossAxisCount;
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool isCompact;

  const StatsCard({
    super.key,
    required this.items,
    this.crossAxisCount = 2,
    this.title,
    this.trailing,
    this.margin,
    this.padding,
    this.isCompact = false,
  });

  /// Factory for a single-metric stat card
  factory StatsCard.single({
    Key? key,
    required StatItem item,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return StatsCard(
      key: key,
      items: [item],
      crossAxisCount: 1,
      margin: margin,
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: title,
      headerTrailing: trailing,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppConstants.spacingM),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final effectiveCrossAxis = constraints.maxWidth < 320
              ? 1
              : crossAxisCount;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: effectiveCrossAxis,
              crossAxisSpacing: AppConstants.spacingM,
              mainAxisSpacing: AppConstants.spacingM,
              childAspectRatio: isCompact ? 2.2 : 1.7,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildStatTile(context, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, StatItem item) {
    Widget content = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (item.icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (item.iconColor ?? AppColors.primaryBlue).withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    size: 16,
                    color: item.iconColor ?? AppColors.primaryBlueLight,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (item.trend != null) ...[
                const SizedBox(width: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isPositiveTrend
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: item.isPositiveTrend
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      item.trend!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.isPositiveTrend
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const Spacer(),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: isCompact ? 18 : 22,
              fontWeight: FontWeight.w700,
              color: item.valueColor ?? AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );

    if (item.onTap != null) {
      return InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }

    return content;
  }
}
