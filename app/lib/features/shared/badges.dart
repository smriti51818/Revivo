import 'package:hugeicons/hugeicons.dart';

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
  final dynamic icon;
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
        icon: HugeIcons.strokeRoundedLeaf02,
        earned: orders >= 1),
    MilestoneBadge(
        title: 'Regular rescuer',
        sub: '5 orders',
        icon: HugeIcons.strokeRoundedRefresh,
        earned: orders >= 5),
    MilestoneBadge(
        title: 'Waste warrior',
        sub: '10 orders',
        icon: HugeIcons.strokeRoundedCheckmarkBadge01,
        earned: orders >= 10),
    MilestoneBadge(
        title: '₹500 saved',
        sub: 'saved ₹500+',
        icon: HugeIcons.strokeRoundedMoney01,
        earned: saved >= 500),
    MilestoneBadge(
        title: 'Meal maker',
        sub: '~50 meals',
        icon: HugeIcons.strokeRoundedRestaurant02,
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
        icon: HugeIcons.strokeRoundedStore02,
        earned: orders >= 1),
    MilestoneBadge(
        title: 'Busy vendor',
        sub: '10 orders',
        icon: HugeIcons.strokeRoundedDeliveryTruck02,
        earned: orders >= 10),
    MilestoneBadge(
        title: '100 kg saved',
        sub: 'from waste',
        icon: HugeIcons.strokeRoundedLeaf02,
        earned: kg >= 100),
    MilestoneBadge(
        title: '₹5k recovered',
        sub: 'in surplus',
        icon: HugeIcons.strokeRoundedMoneyBag01,
        earned: revenue >= 5000),
    MilestoneBadge(
        title: 'Trusted vendor',
        sub: '4.3★ · 10+',
        icon: HugeIcons.strokeRoundedCheckmarkBadge01,
        earned: trusted),
  ];
}
