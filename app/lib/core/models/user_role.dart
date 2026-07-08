/// The Revivo personas. Backed by the Cognito `custom:role` attribute.
enum UserRole {
  vendor,
  buyer;

  /// Value stored in Cognito / DynamoDB.
  String get value => name.toUpperCase();

  String get label => switch (this) {
        UserRole.vendor => 'Seller',
        UserRole.buyer => 'Hotel owner',
      };

  String get tagline => switch (this) {
        UserRole.vendor => 'List surplus produce and reduce waste',
        UserRole.buyer => 'Buy fresh surplus at a discount',
      };

  /// Landing route after login for this role.
  String get homeRoute => switch (this) {
        UserRole.vendor => '/seller/dashboard',
        UserRole.buyer => '/buyer/home',
      };

  static UserRole? fromValue(String? value) {
    if (value == null) return null;
    return UserRole.values
        .where((r) => r.value == value.toUpperCase())
        .firstOrNull;
  }
}
