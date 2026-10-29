import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

enum AvatarSize {
  small(32),
  medium(48),
  large(80);

  final double dimension;
  const AvatarSize(this.dimension);
}

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final AvatarSize size;
  final double? customSize;
  final bool showOnlineIndicator;
  final bool isOnline;
  final int? rank;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.initials,
    this.size = AvatarSize.medium,
    this.customSize,
    this.showOnlineIndicator = false,
    this.isOnline = true,
    this.rank,
    this.onTap,
    this.backgroundColor,
    this.textColor,
  });

  double get _dimension => customSize ?? size.dimension;

  @override
  Widget build(BuildContext context) {
    final dimension = _dimension;
    final fontSize = dimension * 0.4;

    Widget avatarCore = Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? _getAvatarBgColor(initials),
        border: Border.all(
          color: _getBorderColor(),
          width: dimension >= 80 ? 3.0 : 1.5,
        ),
      ),
      child: ClipOval(
        child: (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: backgroundColor ?? _getAvatarBgColor(initials),
                  alignment: Alignment.center,
                  child: _buildInitialsText(fontSize),
                ),
                errorWidget: (context, url, error) => Container(
                  color: backgroundColor ?? _getAvatarBgColor(initials),
                  alignment: Alignment.center,
                  child: _buildInitialsText(fontSize),
                ),
              )
            : Center(child: _buildInitialsText(fontSize)),
      ),
    );

    Widget avatarWithBadges = Stack(
      clipBehavior: Clip.none,
      children: [
        avatarCore,
        if (showOnlineIndicator)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: dimension * 0.28,
              height: dimension * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline
                    ? AppColors.successGreen
                    : AppColors.textDisabled,
                border: Border.all(
                  color: AppColors.primaryBackground,
                  width: 2,
                ),
              ),
            ),
          ),
        if (rank != null && rank! > 0)
          Positioned(right: -2, top: -2, child: _buildRankBadge()),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatarWithBadges);
    }

    return avatarWithBadges;
  }

  Widget _buildInitialsText(double fontSize) {
    return Text(
      initials.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: textColor ?? AppColors.textPrimary,
      ),
    );
  }

  Widget _buildRankBadge() {
    Color badgeColor;
    Color badgeTextColor = Colors.black;

    if (rank == 1) {
      badgeColor = AppColors.goldColor;
    } else if (rank == 2) {
      badgeColor = AppColors.silverColor;
    } else if (rank == 3) {
      badgeColor = AppColors.bronzeColor;
      badgeTextColor = Colors.white;
    } else {
      badgeColor = AppColors.cardBackground;
      badgeTextColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryBackground, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '#$rank',
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: badgeTextColor,
        ),
      ),
    );
  }

  Color _getBorderColor() {
    if (rank == 1) return AppColors.goldColor;
    if (rank == 2) return AppColors.silverColor;
    if (rank == 3) return AppColors.bronzeColor;
    return AppColors.borderLight;
  }

  Color _getAvatarBgColor(String text) {
    if (text.isEmpty) return AppColors.primaryBlue;
    final code = text.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    const colors = [
      AppColors.primaryBlue,
      AppColors.secondaryViolet,
      AppColors.devOpsColor,
      AppColors.networkingColor,
      AppColors.cybersecurityColor,
      AppColors.cloudComputingColor,
    ];
    return colors[code % colors.length];
  }
}
