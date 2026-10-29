import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class CountdownTimerWidget extends StatefulWidget {
  final DateTime targetTime;
  final String? label;
  final VoidCallback? onComplete;
  final bool isCompact;
  final bool showDays;
  final Color? normalColor;
  final Color? backgroundColor;

  const CountdownTimerWidget({
    super.key,
    required this.targetTime,
    this.label,
    this.onComplete,
    this.isCompact = false,
    this.showDays = true,
    this.normalColor,
    this.backgroundColor,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  late Duration _remaining;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetTime != widget.targetTime) {
      _calculateRemaining();
      _startTimer();
    }
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    if (widget.targetTime.isAfter(now)) {
      _remaining = widget.targetTime.difference(now);
      _hasCompleted = false;
    } else {
      _remaining = Duration.zero;
      _hasCompleted = true;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_remaining == Duration.zero) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (widget.targetTime.isAfter(now)) {
        setState(() {
          _remaining = widget.targetTime.difference(now);
        });
      } else {
        setState(() {
          _remaining = Duration.zero;
        });
        timer.cancel();
        if (!_hasCompleted) {
          _hasCompleted = true;
          widget.onComplete?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getCurrentColor() {
    final totalSeconds = _remaining.inSeconds;
    if (totalSeconds <= 0) return AppColors.errorRed;
    if (totalSeconds < 30) return AppColors.errorRed;
    if (totalSeconds < 60) return AppColors.warningAmber;
    return widget.normalColor ?? AppColors.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactTimer(context);
    }
    return _buildLargeTimer(context);
  }

  Widget _buildCompactTimer(BuildContext context) {
    final color = _getCurrentColor();
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    String timeText;
    if (hours > 0) {
      timeText =
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      timeText =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            timeText,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeTimer(BuildContext context) {
    final color = _getCurrentColor();
    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    final showDaysUnit = widget.showDays && days > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showDaysUnit) ...[
              _buildSegment(days.toString().padLeft(2, '0'), 'DAYS', color),
              _buildColon(color),
            ],
            _buildSegment(hours.toString().padLeft(2, '0'), 'HOURS', color),
            _buildColon(color),
            _buildSegment(minutes.toString().padLeft(2, '0'), 'MINS', color),
            _buildColon(color),
            _buildSegment(seconds.toString().padLeft(2, '0'), 'SECS', color),
          ],
        ),
      ],
    );
  }

  Widget _buildSegment(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildColon(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ':',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
