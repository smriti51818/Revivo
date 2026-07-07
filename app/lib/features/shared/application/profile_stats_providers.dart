import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../../../core/api/json_utils.dart';

/// The signed-in user's real, persisted numbers (GET /profile) — wallet balance,
/// vendor reputation, and role-specific aggregates. Replaces the old hardcoded
/// profile stats and the name-hash-faked vendor reputation.
class ProfileStats {
  const ProfileStats({
    required this.walletCredits,
    required this.vendorOrders,
    required this.vendorSoldKg,
    required this.vendorRevenue,
    required this.vendorRating,
    required this.vendorRatingCount,
    required this.vendorTrusted,
    required this.buyerOrders,
    required this.buyerSaved,
    required this.buyerKg,
    required this.cookRescues,
    required this.cookMeals,
    required this.cookKg,
  });

  final int walletCredits;

  final int vendorOrders;
  final double vendorSoldKg;
  final double vendorRevenue;
  final double vendorRating;
  final int vendorRatingCount;
  final bool vendorTrusted;

  final int buyerOrders;
  final double buyerSaved;
  final double buyerKg;

  final int cookRescues;
  final int cookMeals;
  final double cookKg;

  static const empty = ProfileStats(
    walletCredits: 0,
    vendorOrders: 0,
    vendorSoldKg: 0,
    vendorRevenue: 0,
    vendorRating: 0,
    vendorRatingCount: 0,
    vendorTrusted: false,
    buyerOrders: 0,
    buyerSaved: 0,
    buyerKg: 0,
    cookRescues: 0,
    cookMeals: 0,
    cookKg: 0,
  );

  factory ProfileStats.fromJson(Map<String, dynamic> j) {
    final vendor = (j['vendor'] as Map?)?.cast<String, dynamic>() ?? const {};
    final buyer = (j['buyer'] as Map?)?.cast<String, dynamic>() ?? const {};
    final cook = (j['cook'] as Map?)?.cast<String, dynamic>() ?? const {};
    return ProfileStats(
      walletCredits: asInt(j['wallet']),
      vendorOrders: asInt(vendor['orders']),
      vendorSoldKg: asDouble(vendor['soldKg']),
      vendorRevenue: asDouble(vendor['revenue']),
      vendorRating: asDouble(vendor['avgRating']),
      vendorRatingCount: asInt(vendor['ratingCount']),
      vendorTrusted: vendor['trusted'] == true,
      buyerOrders: asInt(buyer['orders']),
      buyerSaved: asDouble(buyer['saved']),
      buyerKg: asDouble(buyer['kg']),
      cookRescues: asInt(cook['rescues']),
      cookMeals: asInt(cook['meals']),
      cookKg: asDouble(cook['kg']),
    );
  }
}

/// Fetches the live profile aggregates. Offline/mock mode returns zeros — the
/// UI degrades to an honest empty state rather than fabricated numbers.
final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final config = ref.read(appConfigProvider);
  if (!config.useLiveApi) return ProfileStats.empty;
  final res = await ref.read(apiClientProvider).get('/profile');
  if (res is! Map) return ProfileStats.empty;
  return ProfileStats.fromJson(res.cast<String, dynamic>());
});
