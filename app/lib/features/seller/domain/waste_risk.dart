import '../../../core/models/freshness.dart';
import 'listing.dart';

/// A forward-looking waste-risk projection over the seller's live listings.
///
/// The freshness engine already tells us, for each lot, exactly when it will
/// cross into the RESCUE band (ratio 0.2 of its shelf window). Running that
/// forward turns reactive "this is now in Rescue" into a predictive nudge —
/// "N kg reaches Rescue within a day, act now" — which is the smart, on-thesis
/// insight for cutting waste before it happens. Pure + client-side, so it works
/// offline and live alike.
class WasteRiskItem {
  const WasteRiskItem({
    required this.listing,
    required this.hoursToRescue,
    required this.alreadyRescue,
  });

  final Listing listing;

  /// Hours until this lot enters the RESCUE band (0 if already there).
  final double hoursToRescue;
  final bool alreadyRescue;

  double get kg => listing.quantityKg;

  /// What the lot is worth right now at its live (decayed) price.
  double get valueAtRisk => listing.liveValue();
}

class WasteRisk {
  const WasteRisk({
    required this.items,
    required this.atRiskKg,
    required this.atRiskValue,
    required this.rescueNowCount,
    required this.soonestHours,
    required this.horizonHours,
  });

  /// Listings that reach RESCUE within [horizonHours], most-urgent first.
  final List<WasteRiskItem> items;
  final double atRiskKg;
  final double atRiskValue;

  /// How many are already in the RESCUE band right now.
  final int rescueNowCount;

  /// Hours until the soonest lot hits RESCUE (0 if one already has).
  final double soonestHours;
  final double horizonHours;

  bool get isEmpty => items.isEmpty;
  int get count => items.length;
}

/// When a lot crosses into the RESCUE band: [expiresAt] minus the 0.2-of-window
/// tail. Null when the listing has no live clock.
DateTime? rescueThreshold(Listing l) {
  if (!l.hasClock) return null;
  final tailSeconds = (0.2 * l.totalHours! * 3600).round();
  return l.expiresAt!.subtract(Duration(seconds: tailSeconds));
}

/// Projects waste risk over [listings] within [horizonHours] (default 24h).
WasteRisk computeWasteRisk(
  List<Listing> listings, {
  double horizonHours = 24,
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final items = <WasteRiskItem>[];
  var rescueNow = 0;

  for (final l in listings) {
    final band = l.liveBand(at);
    final threshold = rescueThreshold(l);

    if (band == FreshnessBand.rescue) {
      rescueNow++;
      items.add(WasteRiskItem(
          listing: l, hoursToRescue: 0, alreadyRescue: true));
      continue;
    }
    if (threshold == null) continue;

    final hours = threshold.difference(at).inMinutes / 60.0;
    if (hours >= 0 && hours <= horizonHours) {
      items.add(WasteRiskItem(
          listing: l, hoursToRescue: hours, alreadyRescue: false));
    }
  }

  items.sort((a, b) => a.hoursToRescue.compareTo(b.hoursToRescue));

  final kg = items.fold<double>(0, (s, i) => s + i.kg);
  final value = items.fold<double>(0, (s, i) => s + i.valueAtRisk);
  final soonest = items.isEmpty ? 0.0 : items.first.hoursToRescue;

  return WasteRisk(
    items: items,
    atRiskKg: kg,
    atRiskValue: value,
    rescueNowCount: rescueNow,
    soonestHours: soonest,
    horizonHours: horizonHours,
  );
}
