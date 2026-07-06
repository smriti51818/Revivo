import 'dart:async';
import 'dart:io';

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

/// The 20 produce types the shelf-life + pricing engine knows.
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

const _quickQty = [2.0, 5.0, 10.0, 25.0, 50.0];
const _minQty = 0.1, _maxQty = 500.0;

class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _quantity = TextEditingController();

  XFile? _photo;
  String _imageKey = '';
  bool _photoBusy = false;
  String? _photoResult; // identify outcome message

  String? _vegetable;
  StorageCondition _storage = StorageCondition.room;
  int _purchaseIdx = 0;
  bool _organic = false;

  FreshnessAnalysis? _analysis;
  bool _analyzing = false;
  bool _submitting = false;
  Timer? _debounce;

  DateTime get _purchasedAt => DateTime.now()
      .subtract(Duration(hours: _purchaseOptions[_purchaseIdx].hours));

  double? get _qty => double.tryParse(_quantity.text.trim());
  bool get _qtyOk => _qty != null && _qty! >= _minQty && _qty! <= _maxQty;

  @override
  void dispose() {
    _debounce?.cancel();
    _quantity.dispose();
    super.dispose();
  }

  // ── Photo: capture → upload → Rekognition identify ──────────────────
  Future<void> _takePhoto() async {
    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        imageQuality: 70,
      );
    } catch (_) {
      if (mounted && _photo == null) {
        _toast('Camera unavailable here — pick the vegetable manually');
      }
      return;
    }
    if (file == null) return;

    setState(() {
      _photo = file;
      _imageKey = '';
      _photoBusy = true;
      _photoResult = null;
    });

    final notifier = ref.read(listingsProvider.notifier);
    final key = await notifier.uploadPhoto(file.path);
    if (!mounted) return;
    setState(() => _imageKey = key);

    final veg = key.isEmpty ? null : await notifier.identify(key);
    if (!mounted) return;
    setState(() {
      _photoBusy = false;
      if (veg != null) {
        _vegetable = veg;
        _photoResult = 'Identified as $veg';
        _analysis = null;
      } else {
        _photoResult = 'Not sure — choose below';
      }
    });
    _scheduleAnalyze();
  }

  // ── Vegetable picker (searchable sheet) ─────────────────────────────
  Future<void> _pickVegetable() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _VegetableSheet(selected: _vegetable),
    );
    if (picked != null && mounted) {
      setState(() {
        _vegetable = picked;
        _analysis = null;
      });
      _scheduleAnalyze();
    }
  }

  // ── Quantity ────────────────────────────────────────────────────────
  void _setQty(double value) {
    final v = value.clamp(_minQty, _maxQty);
    _quantity.text = v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(1);
    _scheduleAnalyze();
    setState(() {});
  }

  void _bumpQty(double delta) => _setQty((_qty ?? 0) + delta);

  // ── Auto price (debounced) ──────────────────────────────────────────
  void _scheduleAnalyze() {
    _debounce?.cancel();
    if (_vegetable == null || !_qtyOk) {
      if (_analysis != null) setState(() => _analysis = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), _analyze);
  }

  Future<void> _analyze() async {
    if (_vegetable == null || !_qtyOk) return;
    setState(() => _analyzing = true);
    try {
      final result = await ref.read(listingsProvider.notifier).analyze(
            vegetable: _vegetable!,
            quantityKg: _qty!,
            storage: _storage,
            purchasedAt: _purchasedAt,
          );
      if (mounted) setState(() => _analysis = result);
    } catch (_) {
      // Price still computed server-side at publish; keep the form usable.
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  String? _validate() {
    if (_vegetable == null) return 'Choose a vegetable';
    if (!_qtyOk) return 'Enter a quantity between 0.1 and 500 kg';
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) return _toast(err);

    final a = _analysis;
    final listing = Listing(
      id: 'lst_${DateTime.now().millisecondsSinceEpoch}',
      vegetable: _vegetable!,
      quantityKg: _qty!,
      basePrice: a?.marketPrice ?? 0,
      recommendedPrice: a?.recommendedPrice ?? 0,
      band: a?.band ?? FreshnessBand.good,
      timeRange: a?.timeRange ?? '',
      storage: _storage,
      organic: _organic,
      imagePath: _photo?.path,
      imageKey: _imageKey.isEmpty ? null : _imageKey,
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
    _resetForm(); // so the tab opens fresh next time (shell keeps it alive)
    _toast('Listing published');
    context.go('/seller/dashboard');
  }

  void _resetForm() {
    _debounce?.cancel();
    _quantity.clear();
    setState(() {
      _photo = null;
      _imageKey = '';
      _photoBusy = false;
      _photoResult = null;
      _vegetable = null;
      _storage = StorageCondition.room;
      _purchaseIdx = 0;
      _organic = false;
      _analysis = null;
      _analyzing = false;
      _submitting = false;
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New listing')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            _photoCard(),
            const SizedBox(height: AppSpacing.xl),
            _label('Vegetable'),
            _vegetableField(),
            const SizedBox(height: AppSpacing.lg),
            _label('Quantity'),
            _quantityRow(),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final q in _quickQty)
                  ActionChip(
                    label: Text('${q.toStringAsFixed(0)} kg'),
                    onPressed: () => _setQty(q),
                    backgroundColor: AppColors.surfaceAlt,
                    side: const BorderSide(color: AppColors.border),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('When was it purchased?'),
            _purchaseChips(),
            const SizedBox(height: AppSpacing.lg),
            _label('Storage condition'),
            DropdownButtonFormField<StorageCondition>(
              initialValue: _storage,
              items: [
                for (final s in StorageCondition.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: (v) {
                setState(() {
                  _storage = v ?? _storage;
                  _analysis = null;
                });
                _scheduleAnalyze();
              },
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
            _priceCard(),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Publish listing',
              icon: Icons.check_circle_outline,
              loading: _submitting,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Center(
              child: Text(
                "Price is set automatically from the market rate and freshness.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ─────────────────────────────────────────────────────────
  Widget _photoCard() {
    final hasPhoto = _photo != null;
    return Container(
      height: 190,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: hasPhoto ? AppColors.primary : AppColors.border,
          width: hasPhoto ? 1.5 : 1,
        ),
      ),
      child: hasPhoto
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.file(File(_photo!.path), fit: BoxFit.cover),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _takePhoto,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.camera_alt_outlined,
                            size: 18, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ),
                Positioned(left: 10, bottom: 10, child: _photoStatus()),
              ],
            )
          : InkWell(
              onTap: _takePhoto,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_camera_outlined,
                        size: 34, color: AppColors.primary),
                    SizedBox(height: 10),
                    Text('Take a photo of the produce',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    SizedBox(height: 2),
                    Text('Amazon Rekognition will identify it',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _photoStatus() {
    if (!_photoBusy && _photoResult == null) return const SizedBox.shrink();
    final identified = _photoResult?.startsWith('Identified') ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_photoBusy)
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          else
            Icon(identified ? Icons.auto_awesome : Icons.info_outline,
                size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            _photoBusy ? 'Analyzing photo…' : _photoResult!,
            style: const TextStyle(
                color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _vegetableField() {
    final has = _vegetable != null;
    return InkWell(
      onTap: _pickVegetable,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Row(
          children: [
            const Icon(Icons.eco_outlined, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                has ? _vegetable! : 'Select vegetable',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: has ? FontWeight.w600 : FontWeight.w400,
                  color: has ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _quantityRow() {
    return Row(
      children: [
        _stepButton(Icons.remove, () => _bumpQty(-1)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: _quantity,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) {
              _scheduleAnalyze();
              setState(() {});
            },
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(hintText: '0', suffixText: 'kg'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _stepButton(Icons.add, () => _bumpQty(1)),
      ],
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _purchaseChips() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (var i = 0; i < _purchaseOptions.length; i++)
          ChoiceChip(
            label: Text(_purchaseOptions[i].label),
            selected: _purchaseIdx == i,
            onSelected: (_) {
              setState(() {
                _purchaseIdx = i;
                _analysis = null;
              });
              _scheduleAnalyze();
            },
            selectedColor: AppColors.primarySurface,
            showCheckmark: false,
          ),
      ],
    );
  }

  Widget _priceCard() {
    final a = _analysis;
    final qty = _qty ?? 0;
    return AppCard(
      color: AppColors.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text('REVIVO PRICING',
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          if (a == null)
            Row(
              children: [
                if (_analyzing) ...[
                  const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  const Text('Calculating fair price…',
                      style: TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                ] else
                  const Expanded(
                    child: Text(
                      'Pick a vegetable and quantity — the price is set '
                      'automatically from the market rate and freshness.',
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColors.textSecondary),
                    ),
                  ),
              ],
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${formatMoney(a.marketPrice)}/kg',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        BandChip(band: a.band, timeRange: a.timeRange),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatMoney(a.recommendedPrice)}/kg',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: AppSpacing.xl),
            Row(
              children: [
                _metric('Listing value', formatMoney(a.recommendedPrice * qty)),
                _metric('Buyer saves', formatMoney(a.savingPerKg * qty)),
                _metric('≈ Meals', '${(qty / 0.4).round()}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.cloud_done_outlined, size: 12, color: AppColors.textMuted),
                SizedBox(width: 4),
                Text('Priced on Revivo servers',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9.5,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              )),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );
}

/// Searchable bottom-sheet picker for the vegetable — pops the chosen name.
class _VegetableSheet extends StatefulWidget {
  const _VegetableSheet({required this.selected});
  final String? selected;

  @override
  State<_VegetableSheet> createState() => _VegetableSheetState();
}

class _VegetableSheetState extends State<_VegetableSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final matches = _vegetables
        .where((v) => v.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose vegetable',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.md),
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search…',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: matches.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text('No matches',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: matches.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final v = matches[i];
                      final sel = v == widget.selected;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.eco_outlined,
                            color: AppColors.primary, size: 20),
                        title: Text(v,
                            style: TextStyle(
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.w500)),
                        trailing: sel
                            ? const Icon(Icons.check_circle,
                                color: AppColors.primary, size: 20)
                            : null,
                        onTap: () => Navigator.of(context).pop(v),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
