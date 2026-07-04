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

  static FreshnessBand fromValue(String? value) => switch (value?.toUpperCase()) {
        'GOOD' => FreshnessBand.good,
        'USE_SOON' || 'USESOON' => FreshnessBand.useSoon,
        'RESCUE' => FreshnessBand.rescue,
        _ => FreshnessBand.good,
      };
}
