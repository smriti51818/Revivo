import 'package:flutter/material.dart';

/// Revivo color tokens — extracted from the product design system
/// (vivid green, light surfaces, rounded cards).
abstract class AppColors {
  // Brand
  static const Color primary = Color(0xFF1FBF61);
  static const Color primaryDark = Color(0xFF15A34E);
  static const Color primarySurface = Color(0xFFE7F7EC);

  // Neutrals
  static const Color background = Color(0xFFF5F6F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF0F2F0);
  static const Color border = Color(0xFFE7E9E7);
  static const Color borderStrong = Color(0xFFD6DAD6);

  // Text
  static const Color textPrimary = Color(0xFF16191B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9AA0A6);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF1FBF61);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Semantic surfaces (chip / banner tints)
  static const Color successSurface = Color(0xFFE7F7EC);
  static const Color warningSurface = Color(0xFFFDF3E2);
  static const Color dangerSurface = Color(0xFFFDEAEA);
  static const Color infoSurface = Color(0xFFE8F1FE);
}
