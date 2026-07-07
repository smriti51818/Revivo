import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_controller.dart';

/// Editable account details for the signed-in user. Name/email come from the
/// Cognito session; phone and address are held locally (the pilot has no user
/// profile endpoint yet — multiple saved addresses are future scope).
class ProfileDetails {
  const ProfileDetails({
    required this.name,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.pincode,
  });

  final String name;
  final String phone;
  final String addressLine;
  final String city;
  final String pincode;

  String get fullAddress => '$addressLine, $city $pincode';

  ProfileDetails copyWith({
    String? name,
    String? phone,
    String? addressLine,
    String? city,
    String? pincode,
  }) =>
      ProfileDetails(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        addressLine: addressLine ?? this.addressLine,
        city: city ?? this.city,
        pincode: pincode ?? this.pincode,
      );
}

class ProfileDetailsController extends Notifier<ProfileDetails> {
  @override
  ProfileDetails build() {
    // Seed once from the session; edits below persist for the app session.
    final session = ref.read(sessionProvider);
    return ProfileDetails(
      name: session?.name ?? 'Guest',
      phone: '+91 90000 00000',
      addressLine: 'Gandhipuram Main Rd',
      city: 'Coimbatore',
      pincode: '641012',
    );
  }

  void update(ProfileDetails details) => state = details;
}

final profileDetailsProvider =
    NotifierProvider<ProfileDetailsController, ProfileDetails>(
        ProfileDetailsController.new);
