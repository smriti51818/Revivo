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
    // Seed the name from the Cognito session; phone/address are left blank for
    // the user to fill (the pilot has no profile endpoint) so we never present a
    // fabricated phone/address as their saved details. City defaults to the
    // pilot city and stays editable.
    final session = ref.read(sessionProvider);
    return ProfileDetails(
      name: session?.name ?? 'Guest',
      phone: '',
      addressLine: '',
      city: 'Coimbatore',
      pincode: '',
    );
  }

  void update(ProfileDetails details) => state = details;
}

final profileDetailsProvider =
    NotifierProvider<ProfileDetailsController, ProfileDetails>(
        ProfileDetailsController.new);
