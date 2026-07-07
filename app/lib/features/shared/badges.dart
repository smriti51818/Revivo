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

/// Seller milestones from real orders fulfilled, kg moved, revenue, and the
/// auto-earned Trusted flag.
List<MilestoneBadge> sellerBadges({
  required int orders,
  required double kg,
  required double revenue,
  required bool trusted,
}) {
  return [
    MilestoneBadge(
        title: 'First sale',
        sub: '1 order',
        icon: Icons.storefront_rounded,
        earned: orders >= 1),
    MilestoneBadge(
        title: 'Busy vendor',
        sub: '10 orders',
        icon: Icons.local_shipping_outlined,
        earned: orders >= 10),
    MilestoneBadge(
        title: '100 kg saved',
        sub: 'from waste',
        icon: Icons.eco_rounded,
        earned: kg >= 100),
    MilestoneBadge(
        title: '₹5k recovered',
        sub: 'in surplus',
        icon: Icons.payments_outlined,
        earned: revenue >= 5000),
    MilestoneBadge(
        title: 'Trusted vendor',
        sub: '4.3★ · 10+',
        icon: Icons.verified_rounded,
        earned: trusted),
  ];
}

/// Cook/NGO milestones from rescues handled and meals served.
List<MilestoneBadge> cookBadges({
  required int rescues,
  required int meals,
  required double kg,
}) {
  return [
    MilestoneBadge(
        title: 'First rescue',
        sub: '1 handled',
        icon: Icons.volunteer_activism_outlined,
        earned: rescues >= 1),
    MilestoneBadge(
        title: 'Meal hero',
        sub: '~100 meals',
        icon: Icons.restaurant_rounded,
        earned: meals >= 100),
    MilestoneBadge(
        title: 'Kitchen force',
        sub: '10 rescues',
        icon: Icons.soup_kitchen_outlined,
        earned: rescues >= 10),
    MilestoneBadge(
        title: '500 meals',
        sub: 'served',
        icon: Icons.diversity_3_outlined,
        earned: meals >= 500),
    MilestoneBadge(
        title: '250 kg rescued',
        sub: 'kept from waste',
        icon: Icons.shield_outlined,
        earned: kg >= 250),
  ];
}
