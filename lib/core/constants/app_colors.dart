// App Colors - DailyDuel Brand Identity
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background Colors
  static const Color primaryBackground = Color(0xFF0B1020);
  static const Color secondaryBackground = Color(0xFF121A2E);
  static const Color cardBackground = Color(0xFF18233B);
  static const Color surfaceColor = Color(0xFF1E2D45);

  // Brand Colors
  static const Color primaryBlue = Color(0xFF5B7CFF);
  static const Color primaryBlueDark = Color(0xFF3D5FE0);
  static const Color primaryBlueLight = Color(0xFF7B9CFF);
  static const Color secondaryViolet = Color(0xFF8B5CF6);
  static const Color secondaryVioletDark = Color(0xFF6D3EE0);

  // Status Colors
  static const Color successGreen = Color(0xFF22C55E);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFFBBF24);
  static const Color infoBlue = Color(0xFF38BDF8);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF475569);

  // Border Colors
  static const Color borderColor = Color(0xFF1E3A5F);
  static const Color borderLight = Color(0xFF2D4A6B);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, secondaryViolet],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryBackground, secondaryBackground],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardBackground, surfaceColor],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
  );

  // Challenge Category Colors
  static const Color generalKnowledgeColor = Color(0xFF06B6D4);
  static const Color programmingColor = Color(0xFF8B5CF6);
  static const Color cloudComputingColor = Color(0xFF3B82F6);
  static const Color devOpsColor = Color(0xFF10B981);
  static const Color networkingColor = Color(0xFFF59E0B);
  static const Color databasesColor = Color(0xFFEF4444);
  static const Color cybersecurityColor = Color(0xFFEC4899);
  static const Color aptitudeColor = Color(0xFF84CC16);
  static const Color mathematicsColor = Color(0xFFF97316);

  // Rank Colors
  static const Color goldColor = Color(0xFFFFD700);
  static const Color silverColor = Color(0xFFC0C0C0);
  static const Color bronzeColor = Color(0xFFCD7F32);

  // Difficulty Colors
  static const Color beginnerColor = Color(0xFF22C55E);
  static const Color intermediateColor = Color(0xFFFBBF24);
  static const Color advancedColor = Color(0xFFEF4444);

  // Overlay
  static const Color overlayLight = Color(0x1AFFFFFF);
  static const Color overlayDark = Color(0x40000000);
}
