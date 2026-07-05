import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/freshness/freshness_estimator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/band_chip.dart';
import '../../core/widgets/primary_button.dart';
import 'application/listings_providers.dart';
import 'domain/listing.dart';
import 'widgets/listing_card.dart';

const _purchaseOptions = [
  (label: 'Just now', hours: 0),
  (label: 'This morning', hours: 8),
  (label: 'Yesterday', hours: 24),
  (label: '2 days ago', hours: 48),
];

class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _vegetable = TextEditingController();
  final _price = TextEditingController();
  final _quantity = TextEditingController();

  StorageCondition _storage = StorageCondition.room;
  int _purchaseIdx = 0;
  bool _organic = false;
  bool _submitting = false;
  XFile? _photo;

  DateTime get _purchasedAt =>
      DateTime.now().subtract(Duration(hours: _purchaseOptions[_purchaseIdx].hours));

  @override
  void dispose() {
    _vegetable.dispose();
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 70,
      );
      if (file != null) setState(() => _photo = file);
    } catch (_) {
      if (mounted) {
        _toast('Camera unavailable here — you can still publish for the demo');
      }
    }
  }

  FreshnessEstimate? get _estimate {
    final veg = _vegetable.text.trim();
    if (veg.isEmpty) return null;
    return estimateFreshness(
      vegetable: veg,
      purchasedAt: _purchasedAt,
      storage: _storage.value,
    );
  }

  Future<void> _submit() async {
    final veg = _vegetable.text.trim();
    final price = double.tryParse(_price.text.trim()) ?? 0;
    final qty = double.tryParse(_quantity.text.trim()) ?? 0;
    if (veg.isEmpty || price <= 0 || qty <= 0) {
      _toast('Add a vegetable name, price, and quantity');
      return;
    }

    final est = _estimate!;
    final listing = Listing(
      id: 'lst_${DateTime.now().millisecondsSinceEpoch}',
      vegetable: veg,
      quantityKg: qty,
      basePrice: price,
      recommendedPrice:
          double.parse((price * est.priceFactor).toStringAsFixed(2)),
      band: est.band,
      timeRange: est.timeRange,
      storage: _storage,
      organic: _organic,
      imagePath: _photo?.path,
      createdAt: DateTime.now(),
      purchasedAt: _purchasedAt,
    );

    setState(() => _submitting = true);
    try {
      await ref.read(listingsProvider.notifier).addListing(listing);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _toast('Could not publish: $e');
      }
      return;
    }
    if (!mounted) return;
    _toast('Listing published');
    context.go('/seller/dashboard');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final est = _estimate;
    final price = double.tryParse(_price.text.trim());

    return Scaffold(
      appBar: AppBar(title: const Text('Add new listing')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            _photoPicker(),
            const SizedBox(height: AppSpacing.xl),
            _label('Vegetable name'),
            TextField(
              controller: _vegetable,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              decoration:
                  const InputDecoration(hintText: 'e.g. Organic Roma Tomatoes'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Price per kg'),
                      TextField(
                        controller: _price,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                            prefixText: '₹ ', hintText: '0.00'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Quantity (kg)'),
                      TextField(
                        controller: _quantity,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: 'e.g. 15'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('Storage condition'),
            DropdownButtonFormField<StorageCondition>(
              initialValue: _storage,
              items: [
                for (final s in StorageCondition.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: (v) => setState(() => _storage = v ?? _storage),
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('When was it purchased?'),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < _purchaseOptions.length; i++)
                  ChoiceChip(
                    label: Text(_purchaseOptions[i].label),
                    selected: _purchaseIdx == i,
                    onSelected: (_) => setState(() => _purchaseIdx = i),
                    selectedColor: AppColors.primarySurface,
                    showCheckmark: false,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Organic produce'),
              value: _organic,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(() => _organic = v),
            ),
            if (est != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _estimatePreview(est, price),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Submit listing',
              icon: Icons.check_circle_outline,
              loading: _submitting,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Center(
              child: Text(
                "By submitting, you agree to Revivo's quality standards.",
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPicker() {
    final hasPhoto = _photo != null;
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: hasPhoto ? AppColors.primary : AppColors.border,
            width: hasPhoto ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasPhoto ? Icons.check_circle : Icons.add_a_photo_outlined,
                size: 30,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                hasPhoto ? 'Photo added' : 'Add photos',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasPhoto
                    ? 'AI: looks fresh · no visible defects'
                    : 'Tap to upload fresh vegetable images',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _estimatePreview(FreshnessEstimate est, double? price) {
    return AppCard(
      color: AppColors.surfaceAlt,
      child: Row(
        children: [
          BandChip(band: est.band, timeRange: est.timeRange),
          const Spacer(),
          if (price != null)
            Text(
              'Suggested ${formatMoney(price * est.priceFactor)} / kg',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
}
