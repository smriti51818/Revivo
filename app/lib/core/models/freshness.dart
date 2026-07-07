/// Freshness bands — deliberately shown as bands with time ranges, never a
/// false-precision percentage. Derived server-side from the shelf-life DB.
enum FreshnessBand {
  good,
  useSoon,
  rescue;

  String get label => switch (this) {
        FreshnessBand.good => 'Good',
        FreshnessBand.useSoon => 'Use soon',
        FreshnessBand.rescue => 'Rescue',
      };

  String get meaning => switch (this) {
        FreshnessBand.good => 'Well within usable window',
        FreshnessBand.useSoon => 'Approaching end of optimal window',
        FreshnessBand.rescue => 'Near end of usable life',
      };

  /// Backend band string (GOOD / USE_SOON / RESCUE) — the inverse of [fromValue].
  String get value => switch (this) {
        FreshnessBand.good => 'GOOD',
        FreshnessBand.useSoon => 'USE_SOON',
        FreshnessBand.rescue => 'RESCUE',
      };

  static FreshnessBand fromValue(String? value) => switch (value?.toUpperCase()) {
        'GOOD' => FreshnessBand.good,
        'USE_SOON' || 'USESOON' => FreshnessBand.useSoon,
        'RESCUE' => FreshnessBand.rescue,
        _ => FreshnessBand.good,
      };

  /// Maps a remaining/total life ratio to a band — mirrors the backend engine
  /// (GOOD ≥ 0.5, USE_SOON ≥ 0.2, else RESCUE) so the live client countdown and
  /// the server agree on the band as it decays.
  static FreshnessBand fromRatio(double ratio) => ratio >= 0.5
      ? FreshnessBand.good
      : ratio >= 0.2
          ? FreshnessBand.useSoon
          : FreshnessBand.rescue;

  /// Price multiplier applied to the market price for this band.
  double get priceFactor => switch (this) {
        FreshnessBand.good => 1.0,
        FreshnessBand.useSoon => 0.7,
        FreshnessBand.rescue => 0.4,
      };
}
