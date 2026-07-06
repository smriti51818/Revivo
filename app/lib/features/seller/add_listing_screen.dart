import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/format.dart';
import '../../core/models/freshness.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/band_chip.dart';
import '../../core/widgets/primary_button.dart';
import 'application/listings_providers.dart';
import 'domain/freshness_analysis.dart';
import 'domain/listing.dart';

/// Vegetables the freshness engine has shelf-life data for (keys in the
/// backend shelf_life table). Sellers pick from these so every listing gets a
/// real analysis.
const _vegetables = [
  'Tomato', 'Potato', 'Onion', 'Spinach', 'Coriander', 'Carrot',
  'Bell Pepper', 'Cabbage', 'Cauliflower', 'Brinjal', 'Okra',
  'Green Chilli', 'Cucumber', 'Beans', 'Beetroot', 'Radish',
  'Pumpkin', 'Drumstick', 'Curry Leaves', 'Mint',
];

const _purchaseOptions = [
  (label: 'Just now', hours: 0),
  (label: 'This morning', hours: 8),
  (label: 'Yesterday', hours: 24),
  (label: '2 days ago', hours: 48),
  (label: '3 days ago', hours: 72),
  (label: '4 days ago', hours: 96),
  (label: '5 days ago', hours: 120),
  (label: 'A week ago', hours: 168),
];

// Input limits (client-side guardrails; the server validates too).
const _minPrice = 1.0, _maxPrice = 10000.0;
const _minQty = 0.1, _maxQty = 500.0;

class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _price = TextEditingController();
  final _quantity = TextEditingController();

  String? _vegetable;
  StorageCondition _storage = StorageCondition.room;
  int _purchaseIdx = 0;
  bool _organic = false;
  bool _submitting = false;
  bool _analyzing = false;
  XFile? _photo;
  FreshnessAnalysis? _analysis;

  DateTime get _purchasedAt => DateTime.now()
      .subtract(Duration(hours: _purchaseOptions[_purchaseIdx].hours));

  @override
  void dispose() {
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  /// Any input change invalidates a prior analysis.
  void _invalidate() => setState(() => _analysis = null);

  bool get _priceOk {
    final p = double.tryParse(_price.text.trim());
    return p != null && p >= _minPrice && p <= _maxPrice;
  }

  bool get _qtyOk {
    final q = double.tryParse(_quantity.text.trim());
    return q != null && q >= _minQty && q <= _maxQty;
  }

  Future<void> _takePhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
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

  String? _validate() {
    if (_vegetable == null) return 'Choose a vegetable';
    if (!_priceOk) return 'Enter a price between ₹1 and ₹10,000/kg';
    if (!_qtyOk) return 'Enter a quantity between 0.1 and 500 kg';
    return null;
  }

  Future<void> _analyze() async {
    final err = _validate();
    if (err != null) return _toast(err);

    setState(() => _analyzing = true);
    try {
      final result = await ref.read(listingsProvider.notifier).analyze(
            vegetable: _vegetable!,
            basePrice: double.parse(_price.text.trim()),
            quantityKg: double.parse(_quantity.text.trim()),
            storage: _storage,
            purchasedAt: _purchasedAt,
          );
      if (mounted) setState(() => _analysis = result);
    } catch (e) {
      if (mounted) _toast('Could not analyze: $e');
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) return _toast(err);

    final a = _analysis;
    final price = double.parse(_price.text.trim());
    // Band/price here are optimistic; the server recomputes them on publish.
    final listing = Listing(
      id: 'lst_${DateTime.now().millisecondsSinceEpoch}',
      vegetable: _vegetable!,
      quantityKg: double.parse(_quantity.text.trim()),
      basePrice: price,
      recommendedPrice: a?.recommendedPrice ?? price,
      band: a?.band ?? FreshnessBand.good,
      timeRange: a?.timeRange ?? '',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add new listing')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            _photoPicker(),
            const SizedBox(height: AppSpacing.xl),
            _label('Vegetable'),
            DropdownButtonFormField<String>(
              initialValue: _vegetable,
              isExpanded: true,
              hint: const Text('Select a vegetable'),
              items: [
                for (final v in _vegetables)
                  DropdownMenuItem(value: v, child: Text(v)),
              ],
              onChanged: (v) => setState(() {
                _vegetable = v;
                _analysis = null;
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Price per kg'),
                      TextField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: _numberFormatters(maxLen: 7),
                        onChanged: (_) => _invalidate(),
                        decoration: const InputDecoration(
                          prefixText: '₹ ',
                          hintText: '1 – 10000',
                        ),
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
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: _numberFormatters(maxLen: 6),
                        onChanged: (_) => _invalidate(),
                        decoration: const InputDecoration(
                          hintText: '0.1 – 500',
                        ),
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
              onChanged: (v) => setState(() {
                _storage = v ?? _storage;
                _analysis = null;
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('When was it purchased?'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (var i = 0; i < _purchaseOptions.length; i++)
                  ChoiceChip(
                    label: Text(_purchaseOptions[i].label),
                    selected: _purchaseIdx == i,
                    onSelected: (_) => setState(() {
                      _purchaseIdx = i;
                      _analysis = null;
                    }),
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
            const SizedBox(height: AppSpacing.sm),
            _analysisSection(),
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

  List<TextInputFormatter> _numberFormatters({required int maxLen}) => [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        LengthLimitingTextInputFormatter(maxLen),
      ];

  Widget _photoPicker() {
    final hasPhoto = _photo != null;
    return GestureDetector(
      onTap: _takePhoto,
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
                hasPhoto ? Icons.check_circle : Icons.photo_camera_outlined,
                size: 30,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                hasPhoto ? 'Photo captured' : 'Take a photo',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasPhoto ? 'Tap to retake' : 'Camera only — snap the produce',
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

  /// Genuine freshness analysis fetched from AWS (POST /listings/analyze).
  /// Placeholder until the seller runs it; no fabricated on-device result.
  Widget _analysisSection() {
    final a = _analysis;
    return AppCard(
      color: AppColors.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined,
                  size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'FRESHNESS ANALYSIS',
                style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (a == null) ...[
            const Text(
              'Get the freshness band, a safe time window, and a fair price — '
              'computed on Revivo\'s servers from the shelf-life engine.',
              style: TextStyle(
                  fontSize: 12.5, height: 1.4, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _analyzing ? null : _analyze,
              icon: _analyzing
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(_analyzing ? 'Analyzing…' : 'Analyze freshness'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ] else ...[
            Row(
              children: [
                BandChip(band: a.band, timeRange: a.timeRange),
                const Spacer(),
                Text(
                  'Fair price ${formatMoney(a.recommendedPrice)}/kg',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.cloud_done_outlined,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                const Text(
                  'Analyzed on Revivo servers',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _analyzing ? null : _analyze,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Re-run'),
                ),
              ],
            ),
          ],
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
