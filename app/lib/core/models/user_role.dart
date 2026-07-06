/// The Revivo personas. Backed by the Cognito `custom:role` attribute.
enum UserRole {
  vendor,
  buyer,
  cook;

  /// Value stored in Cognito / DynamoDB.
  String get value => name.toUpperCase();

  String get label => switch (this) {
        UserRole.vendor => 'Seller',
        UserRole.buyer => 'Hotel owner',
        UserRole.cook => 'Community cook',
      };

  String get tagline => switch (this) {
        UserRole.vendor => 'List surplus produce and reduce waste',
        UserRole.buyer => 'Buy fresh surplus at a discount',
        UserRole.cook => 'Turn rescued produce into meals',
      };

  /// Landing route after login for this role.
  String get homeRoute => switch (this) {
        UserRole.vendor => '/seller/dashboard',
        UserRole.buyer => '/buyer/home',
        UserRole.cook => '/cook/inbox',
      };

  static UserRole? fromValue(String? value) {
    if (value == null) return null;
    return UserRole.values
        .where((r) => r.value == value.toUpperCase())
        .firstOrNull;
  }
}
