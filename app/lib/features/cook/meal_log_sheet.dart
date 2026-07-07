import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_button.dart';
import '../rescue/application/meal_log_providers.dart';
import '../rescue/domain/rescue.dart';

/// Bottom sheet where a cook records how many meals a delivered rescue became —
/// the "Meals Served" step that turns rescued kg into measurable impact.
Future<void> showMealLogSheet(
    BuildContext context, WidgetRef ref, Rescue rescue) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _MealLogSheet(rescue: rescue),
  );
}

class _MealLogSheet extends ConsumerStatefulWidget {
  const _MealLogSheet({required this.rescue});
  final Rescue rescue;

  @override
  ConsumerState<_MealLogSheet> createState() => _MealLogSheetState();
}

class _MealLogSheetState extends ConsumerState<_MealLogSheet> {
  late int _meals =
      ref.read(mealLogProvider)[widget.rescue.id] ?? widget.rescue.estimatedMeals;

  void _step(int delta) =>
      setState(() => _meals = (_meals + delta).clamp(0, 100000));

  @override
  Widget build(BuildContext context) {
    final r = widget.rescue;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md,
            AppSpacing.screen, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Log the meal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('${r.vegetable} · ${r.quantityKg.toStringAsFixed(0)} kg from ${r.vendorName}',
                style:
                    const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                const Expanded(
                  child: Text('Meals served',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                _stepBtn(Icons.remove, () => _step(-5)),
                SizedBox(
                  width: 64,
                  child: Text('$_meals',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                ),
                _stepBtn(Icons.add, () => _step(5)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Save · $_meals meals served',
              icon: Icons.restaurant_rounded,
              onPressed: () {
                ref.read(mealLogProvider.notifier).log(r.id, _meals);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                      content: Text('$_meals meals logged — Meal Hero 🌱')));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: 20, color: AppColors.primaryDark),
      ),
    );
  }
}
