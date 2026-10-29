import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/challenge_model.dart';
import 'app_button.dart';

class ChallengeCard extends StatefulWidget {
  final ChallengeModel challenge;
  final VoidCallback? onStart;
  final VoidCallback? onTap;
  final bool isCompact;
  final EdgeInsetsGeometry? margin;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onStart,
    this.onTap,
    this.isCompact = false,
    this.margin,
  });

  @override
  State<ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<ChallengeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.challenge.isLocked) {
      _animController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.challenge.isLocked) {
      _animController.reverse();
    }
  }

  void _onTapCancel() {
    if (!widget.challenge.isLocked) {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    final category = challenge.category;
    final categoryColor = category.color;
    final isLocked = challenge.isLocked;

    final cardBorderRadius = BorderRadius.circular(
      AppConstants.cardBorderRadius,
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: Container(
        margin:
            widget.margin ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: cardBorderRadius,
          border: Border.all(
            color: isLocked
                ? AppColors.borderColor
                : categoryColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isLocked
                  ? Colors.black.withValues(alpha: 0.2)
                  : categoryColor.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: cardBorderRadius,
          child: InkWell(
            borderRadius: cardBorderRadius,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: isLocked ? null : (widget.onTap ?? widget.onStart),
            splashColor: categoryColor.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: widget.isCompact
                ? _buildCompactContent(context)
                : _buildFullContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFullContent(BuildContext context) {
    final challenge = widget.challenge;
    final category = challenge.category;
    final categoryColor = category.color;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Icon, Name, and Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(category.icon, size: 22, color: categoryColor),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: categoryColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      challenge.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              _buildDifficultyBadge(challenge.difficulty),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),

          // Description
          Text(
            challenge.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),

          // Metadata Chips (Questions, Time, Points)
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildMetaChip(
                icon: Icons.help_outline_rounded,
                text: '${challenge.questionCount} Questions',
              ),
              _buildMetaChip(
                icon: Icons.timer_outlined,
                text: '${(challenge.timeLimitSeconds / 60).round()} mins',
              ),
              _buildMetaChip(
                icon: Icons.military_tech_outlined,
                text: '${challenge.maxPoints} pts',
                textColor: AppColors.goldColor,
                iconColor: AppColors.goldColor,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),

          // Divider
          Container(
            height: 1,
            color: AppColors.borderColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppConstants.spacingM),

          // Footer: Status Badge & Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(challenge.status),
              _buildActionButton(challenge),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactContent(BuildContext context) {
    final challenge = widget.challenge;
    final category = challenge.category;
    final categoryColor = category.color;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(category.icon, size: 20, color: categoryColor),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  challenge.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${challenge.questionCount} Qs • ${(challenge.timeLimitSeconds / 60).round()}m',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildDifficultyBadge(
                      challenge.difficulty,
                      isCompact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          _buildActionButton(challenge, isCompact: true),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(
    ChallengeDifficulty difficulty, {
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: difficulty.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: difficulty.color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        difficulty.displayName,
        style: GoogleFonts.poppins(
          fontSize: isCompact ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: difficulty.color,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ChallengeStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status.color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String text,
    Color? textColor,
    Color? iconColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor ?? AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    ChallengeModel challenge, {
    bool isCompact = false,
  }) {
    String buttonText;
    AppButtonStyle buttonStyle;
    IconData? icon;
    VoidCallback? action = widget.onStart ?? widget.onTap;

    switch (challenge.status) {
      case ChallengeStatus.completed:
        buttonText = 'Review';
        buttonStyle = AppButtonStyle.outline;
        icon = Icons.check_circle_outline_rounded;
        break;
      case ChallengeStatus.inProgress:
        buttonText = 'Continue';
        buttonStyle = AppButtonStyle.primary;
        icon = Icons.play_arrow_rounded;
        break;
      case ChallengeStatus.locked:
        buttonText = 'Locked';
        buttonStyle = AppButtonStyle.secondary;
        icon = Icons.lock_outline_rounded;
        action = null;
        break;
      case ChallengeStatus.upcoming:
        buttonText = 'Upcoming';
        buttonStyle = AppButtonStyle.outline;
        icon = Icons.schedule_rounded;
        action = null;
        break;
      case ChallengeStatus.available:
        buttonText = 'Start';
        buttonStyle = AppButtonStyle.primary;
        icon = Icons.play_arrow_rounded;
        break;
    }

    return AppButton(
      text: buttonText,
      onPressed: action,
      style: buttonStyle,
      isFullWidth: false,
      height: isCompact ? 36 : 40,
      fontSize: isCompact ? 12 : 13,
      leadingIcon: icon,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 18),
    );
  }
}
