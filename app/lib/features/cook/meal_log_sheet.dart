import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/uploads/image_uploader.dart';
import '../../core/widgets/primary_button.dart';
import '../rescue/application/rescue_providers.dart';
import '../rescue/domain/rescue.dart';

/// Bottom sheet where a cook records how many meals a delivered rescue became —
/// the "Meals Served" step that turns rescued kg into measurable, persisted
/// impact. An optional proof photo (camera → S3) makes it fundable/auditable.
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
  late int _meals = widget.rescue.mealsServed ?? widget.rescue.estimatedMeals;
  XFile? _photo;
  bool _saving = false;

  void _step(int delta) =>
      setState(() => _meals = (_meals + delta).clamp(0, 100000));

  Future<void> _capture() async {
    final shot = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (shot != null) setState(() => _photo = shot);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      var photoKey = '';
      if (_photo != null) {
        photoKey = await ref.read(imageUploaderProvider).upload(_photo!.path);
      }
      await ref.read(rescuesProvider.notifier).logMeal(
            widget.rescue.id,
            meals: _meals,
            photoKey: photoKey,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text('$_meals meals logged — Meal Hero 🌱')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rescue;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.md,
          AppSpacing.screen,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
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
            Text(
                '${r.vegetable} · ${r.quantityKg.toStringAsFixed(0)} kg from ${r.vendorName}',
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
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
            _photoField(),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Save · $_meals meals served',
              icon: Icons.restaurant_rounded,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoField() {
    if (_photo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          children: [
            Image.file(File(_photo!.path),
                width: double.infinity, height: 150, fit: BoxFit.cover),
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  iconSize: 18,
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: Colors.white),
                  onPressed: () => setState(() => _photo = null),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: _capture,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.border),
      ),
      icon: const HugeIcon(icon: HugeIcons.strokeRoundedCamera01, size: 18),
      label: const Text('Add a meal photo (optional)'),
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
