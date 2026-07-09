import 'dart:math';

/// Derived, stable facts about a vendor for the Coimbatore pilot.
///
/// The backend does not yet aggregate per-vendor location or reputation (that
/// needs a VENDOR_STATS item + geolocation, which are future scope). Until then
/// these are derived deterministically from the vendor's name so every screen
/// agrees on the same numbers across rebuilds — believable pilot data, not
/// random noise. Swap [vendorInfo] for a real API lookup when the backend ships.
class VendorInfo {
  const VendorInfo({
    required this.name,
    required this.distanceKm,
    required this.area,
    required this.rating,
    required this.reviews,
    required this.completedOrders,
    required this.bearing,
  });

  final String name;
  final double distanceKm;

  /// Neighbourhood within Coimbatore.
  final String area;

  /// Average rating (4.1–4.9), one decimal.
  final double rating;

  /// Number of ratings behind [rating].
  final int reviews;

  /// Lifetime completed orders — drives the Trusted Vendor badge.
  final int completedOrders;

  /// Direction from the buyer, radians (for the rescue radar).
  final double bearing;

  /// Auto-earned after 10 completed orders at 4.3★+ (per the spec's trust model).
  bool get trusted => completedOrders >= 10 && rating >= 4.3;

  String get areaLabel => '$area · Coimbatore';
}

const List<String> _areas = [
  'Gandhipuram',
  'R.S. Puram',
  'Peelamedu',
  'Saibaba Colony',
  'Town Hall',
  'Ganapathy',
  'Singanallur',
  'Ukkadam',
  'Race Course',
  'Saravanampatti',
];

/// FNV-1a over the code units — deterministic across runs (unlike
/// [String.hashCode], which is seed-randomised).
int _hash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

VendorInfo vendorInfo(String name) {
  final key = name.trim().isEmpty ? 'Vendor' : name.trim();
  final h = _hash(key);
  final distance = ((0.3 + (h % 320) / 100) * 10).round() / 10; // 0.3–3.5, 1dp
  final rating = (41 + ((h >> 7) % 9)) / 10; // 4.1–4.9
  return VendorInfo(
    name: key,
    distanceKm: distance.toDouble(),
    area: _areas[(h >> 3) % _areas.length],
    rating: rating,
    reviews: 18 + ((h >> 11) % 242), // 18–259
    completedOrders: 6 + ((h >> 17) % 59), // 6–64
    bearing: ((h >> 5) % 360) * pi / 180,
  );
}

/// A single buyer review of a vendor.
class VendorReview {
  const VendorReview({
    required this.author,
    required this.stars,
    required this.text,
    required this.ago,
  });

  final String author;
  final int stars;
  final String text;
  final String ago;
}

const List<String> _reviewers = [
  'Hotel Ashok',
  'Sri Krishna Mess',
  'Junior Kuppanna',
  'Adyar Ananda Bhavan',
  'Vaibhav Restaurant',
];

const List<String> _reviewText = [
  'Produce matched the photo exactly — firm and fresh. Smooth pickup.',
  'Great value versus the mandi, and the freshness band was honest.',
  'Picked up in ten minutes. Good quality, will rescue from here again.',
  'Slightly ripe but perfect for same-day cooking. Fair price.',
  'Friendly vendor, quantities were spot on. Recommended.',
  'Saved a good amount and cut our evening waste. Reliable so far.',
];

const List<String> _reviewAgo = [
  '2 days ago',
  '5 days ago',
  '1 week ago',
  '3 days ago',
  '2 weeks ago',
];

/// Three deterministic recent reviews for a vendor — social proof for the pilot
/// until real reviews are aggregated server-side.
List<VendorReview> vendorReviews(String name) {
  final key = name.trim().isEmpty ? 'Vendor' : name.trim();
  final h = _hash(key);
  final base = vendorInfo(key).rating.round();
  return [
    for (var i = 0; i < 3; i++)
      VendorReview(
        author: _reviewers[(h >> (i * 4)) % _reviewers.length],
        stars: (base - (i == 1 ? 1 : 0)).clamp(3, 5),
        text: _reviewText[(h >> (i * 3)) % _reviewText.length],
        ago: _reviewAgo[(h >> (i * 5)) % _reviewAgo.length],
      ),
  ];
}
