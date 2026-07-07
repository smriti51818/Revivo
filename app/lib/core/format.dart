/// Formats a rupee amount, dropping the decimals when the value is whole.
String formatMoney(double value) {
  final whole = value == value.roundToDouble();
  return '₹${whole ? value.toStringAsFixed(0) : value.toStringAsFixed(2)}';
}

/// Formats a kilogram amount, dropping the decimal when whole.
String formatKg(double value) {
  final whole = value == value.roundToDouble();
  return '${whole ? value.toStringAsFixed(0) : value.toStringAsFixed(1)} kg';
}

/// Formats a remaining duration as a compact live countdown, e.g. "2d 4h",
/// "5h 12m", "8m 30s", or "Expired" once the window has closed.
String formatCountdown(Duration d) {
  if (d.inSeconds <= 0) return 'Expired';
  if (d.inHours >= 48) return '${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
  return '${d.inMinutes}m ${d.inSeconds % 60}s';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String _hm(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// A full timestamp, e.g. "7 Jul 2026, 6:42 PM".
String formatDateTime(DateTime t) =>
    '${t.day} ${_months[t.month - 1]} ${t.year}, ${_hm(t)}';

/// A coarse "time ago" label, e.g. "just now", "12 min ago", "3 days ago".
String formatAgo(DateTime time, [DateTime? now]) {
  final d = (now ?? DateTime.now()).difference(time);
  if (d.inSeconds < 45) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} hr ago';
  if (d.inDays < 7) return '${d.inDays} day${d.inDays == 1 ? '' : 's'} ago';
  final w = (d.inDays / 7).floor();
  return '$w week${w == 1 ? '' : 's'} ago';
}

/// Groups an integer with thousands separators, e.g. 48600 -> "48,600".
String formatCount(num value) {
  final digits = value.round().abs().toString();
  final buf = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}
