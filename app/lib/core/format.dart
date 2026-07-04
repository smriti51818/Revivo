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
