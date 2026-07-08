import 'package:flutter/material.dart';

/// Revivo color tokens — extracted from the product design system
/// (vivid green, light surfaces, rounded cards).
abstract class AppColors {
  // Brand
  static const Color primary = Color(0xFF1FBF61);
  static const Color primaryDark = Color(0xFF16A34A);
  static const Color primarySurface = Color(0xFFE6F8ED);
  static const Color primaryLight = Color(0xFF4ADE80);

  // Neutrals
  static const Color background = Color(0xFFF9FAFB); // Cleaner off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF3F4F6); // Softer gray
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderStrong = Color(0xFFD1D5DB);

  // Text
  static const Color textPrimary = Color(0xFF111827); // Darker for contrast
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF1FBF61);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Semantic surfaces (chip / banner tints)
  static const Color successSurface = Color(0xFFE6F8ED);
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color dangerSurface = Color(0xFFFEE2E2);
  static const Color infoSurface = Color(0xFFDBEAFE);
}
