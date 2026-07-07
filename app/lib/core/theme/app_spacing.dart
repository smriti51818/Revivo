import 'package:flutter/material.dart';

/// Spacing, radius, and sizing tokens for a consistent layout rhythm.
abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Screen edge padding
  static const double screen = 16;
}

abstract class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;

  /// Extra-curvy — hero cards, product tiles, sheets. Matches the soft, rounded
  /// grocery-app look.
  static const double xl = 26;

  /// Rounded CTAs / inputs.
  static const double button = 16;

  static const double pill = 999;
}

/// Soft, low-contrast elevation used across cards — the "Dribbble" look, a
/// diffuse shadow instead of a hard hairline border.
abstract class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF16191B).withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFF16191B).withValues(alpha: 0.02),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  /// A slightly stronger lift for pressed / floating elements.
  static List<BoxShadow> get lifted => [
        BoxShadow(
          color: const Color(0xFF16191B).withValues(alpha: 0.10),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];
}
