import '../domain/impact.dart';

abstract class ImpactRepository {
  Future<ImpactData> fetchImpact();
}

class InMemoryImpactRepository implements ImpactRepository {
  @override
  Future<ImpactData> fetchImpact() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const ImpactData(
      summary: ImpactSummary(
        kgRescued: 1240,
        mealsServed: 3100,
        co2SavedKg: 3100, // ~2.5 kg CO2e avoided per kg of food saved
        moneySaved: 48600,
        activeVendors: 6,
        activeNgos: 3,
        mealsGoal: 5000,
      ),
      leaderboard: [
        LeaderboardEntry(
            rank: 1,
            name: 'GreenLeaf Farms',
            role: 'Vendor',
            kg: 210,
            meals: 525),
        LeaderboardEntry(
            rank: 2,
            name: 'Annapoorna Trust',
            role: 'NGO',
            kg: 180,
            meals: 450),
        LeaderboardEntry(
            rank: 3,
            name: 'Kovai Fresh Mart',
            role: 'Vendor',
            kg: 156,
            meals: 390),
        LeaderboardEntry(
            rank: 4,
            name: 'Sunrise Organics',
            role: 'Vendor',
            kg: 132,
            meals: 330),
        LeaderboardEntry(
            rank: 5,
            name: 'Seva Kitchen',
            role: 'NGO',
            kg: 120,
            meals: 300),
      ],
    );
  }
}
