import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_role.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import 'application/profile_providers.dart';

/// Account details — name, phone number, and pickup/delivery address. Editable
/// in place. Multiple saved addresses (branches per login) are future scope.
class AccountDetailsScreen extends ConsumerStatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  ConsumerState<AccountDetailsScreen> createState() =>
      _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _pincode;

  @override
  void initState() {
    super.initState();
    final d = ref.read(profileDetailsProvider);
    _name = TextEditingController(text: d.name);
    _phone = TextEditingController(text: d.phone);
    _address = TextEditingController(text: d.addressLine);
    _city = TextEditingController(text: d.city);
    _pincode = TextEditingController(text: d.pincode);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _pincode.dispose();
    super.dispose();
  }

  void _save() {
    final current = ref.read(profileDetailsProvider);
    ref.read(profileDetailsProvider.notifier).update(
          current.copyWith(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            addressLine: _address.text.trim(),
            city: _city.text.trim(),
            pincode: _pincode.text.trim(),
          ),
        );
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Account details saved')));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final email = session?.email ?? '';
    final role = session?.role ?? UserRole.buyer;

    return Scaffold(
      appBar: AppBar(title: const Text('Account details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            _avatar(),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Profile'),
            const SizedBox(height: AppSpacing.sm),
            _field('Full name', _name, icon: Icons.person_outline),
            const SizedBox(height: AppSpacing.md),
            _field('Phone number', _phone,
                icon: Icons.call_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: AppSpacing.md),
            _readonlyField(
                'Email', email.isEmpty ? '—' : email, Icons.mail_outline),
            const SizedBox(height: AppSpacing.md),
            _readonlyField('Role', role.label, Icons.badge_outlined),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Address'),
            const SizedBox(height: AppSpacing.sm),
            _field('Address line', _address, icon: Icons.home_outlined),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _field('City', _city, icon: Icons.location_city)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _field('Pincode', _pincode,
                      icon: Icons.pin_drop_outlined,
                      keyboardType: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _multiAddressHint(),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Save changes',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    final name = _name.text.isEmpty ? '?' : _name.text[0].toUpperCase();
    return Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {IconData? icon, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
      ),
    );
  }

  Widget _readonlyField(String label, String value, IconData icon) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 14),
      color: AppColors.surfaceAlt,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 9.5,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _multiAddressHint() {
    return AppCard(
      color: AppColors.infoSurface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.add_location_alt_outlined,
              size: 20, color: AppColors.info),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text(
              'Multiple saved addresses (branches per login) are coming soon.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
