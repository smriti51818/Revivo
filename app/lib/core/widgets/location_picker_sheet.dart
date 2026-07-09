import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../features/shared/application/profile_providers.dart';
import '../theme/app_colors.dart';

Future<void> showLocationPicker(BuildContext context, WidgetRef ref) {
  final details = ref.read(profileDetailsProvider);
  final cities = ['Coimbatore', 'Chennai', 'Bangalore', 'Kochi', 'Madurai'];

  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...cities.map((city) {
              final isSelected = details.city == city;
              return ListTile(
                title: Text(
                  city,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? const HugeIcon(
                        icon: HugeIcons.strokeRoundedTick01,
                        color: AppColors.primary,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  ref.read(profileDetailsProvider.notifier).update(
                        details.copyWith(city: city),
                      );
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    ),
  );
}
