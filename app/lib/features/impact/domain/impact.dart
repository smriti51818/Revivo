/// Network-wide impact for the Coimbatore pilot. Numbers are aggregated
/// server-side from delivered rescues and completed orders; seeded here for
/// the demo and swapped for a live query after deploy.
class ImpactSummary {
  const ImpactSummary({
    required this.kgRescued,
    required this.mealsServed,
    required this.co2SavedKg,
    required this.moneySaved,
    required this.activeVendors,
    required this.activeNgos,
    required this.mealsGoal,
  });

  final double kgRescued;
  final int mealsServed;
  final double co2SavedKg;
  final double moneySaved;
  final int activeVendors;
  final int activeNgos;
  final int mealsGoal;

  double get goalProgress =>
      mealsGoal <= 0 ? 0 : (mealsServed / mealsGoal).clamp(0, 1).toDouble();
}

/// A ranked contributor on the impact leaderboard.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.role,
    required this.kg,
    required this.meals,
  });

  final int rank;
  final String name;
  final String role;
  final double kg;
  final int meals;
}

/// Bundle read by the impact screen.
class ImpactData {
  const ImpactData({required this.summary, required this.leaderboard});

  final ImpactSummary summary;
  final List<LeaderboardEntry> leaderboard;
}
