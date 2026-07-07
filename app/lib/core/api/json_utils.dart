/// Parses a JSON number (the API sends DynamoDB Decimals as int or double)
/// into a Dart double, defaulting to 0.
double asDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

/// Parses a JSON number into a Dart int, defaulting to 0.
int asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

/// Converts epoch seconds (int/double) to a DateTime, defaulting to now.
DateTime epochToDate(dynamic value) => value is num
    ? DateTime.fromMillisecondsSinceEpoch((value * 1000).round())
    : DateTime.now();
