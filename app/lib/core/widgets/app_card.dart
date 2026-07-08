import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A rounded, hairline-bordered surface — the base container of the UI.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tinted = color != null && color != AppColors.surface;
    final radius = BorderRadius.circular(AppRadius.lg);
    
    Widget content = Padding(
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: tinted ? Border.all(color: AppColors.border) : null,
        boxShadow: tinted ? null : AppShadows.card,
      ),
      child: Material(
        color: color ?? AppColors.surface,
        borderRadius: radius,
        child: content,
      ),
    );
  }
}
