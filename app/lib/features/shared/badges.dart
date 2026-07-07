import 'package:flutter/material.dart';

/// A gamification milestone shown on the profile. [earned] is computed from the
/// buyer's real order history.
class MilestoneBadge {
  const MilestoneBadge({
    required this.title,
    required this.sub,
    required this.icon,
    required this.earned,
  });

  final String title;
  final String sub;
  final IconData icon;
  final bool earned;
}

/// Buyer milestones derived from orders placed, rupees saved, and kg rescued
/// (~2.5 meals/kg, matching the impact engine).
List<MilestoneBadge> buyerBadges({
  required int orders,
  required double saved,
  required double kg,
}) {
  final meals = (kg * 2.5).round();
  return [
    MilestoneBadge(
        title: 'First rescue',
        sub: '1 order',
        icon: Icons.eco_rounded,
        earned: orders >= 1),
    MilestoneBadge(
        title: 'Regular rescuer',
        sub: '5 orders',
        icon: Icons.repeat_rounded,
        earned: orders >= 5),
    MilestoneBadge(
        title: 'Waste warrior',
        sub: '10 orders',
        icon: Icons.shield_outlined,
        earned: orders >= 10),
    MilestoneBadge(
        title: '₹500 saved',
        sub: 'saved ₹500+',
        icon: Icons.savings_outlined,
        earned: saved >= 500),
    MilestoneBadge(
        title: 'Meal maker',
        sub: '~50 meals',
        icon: Icons.restaurant_rounded,
        earned: meals >= 50),
  ];
}
