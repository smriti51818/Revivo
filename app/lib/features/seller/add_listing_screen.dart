import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/format.dart';
import '../../core/models/freshness.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import 'application/listings_providers.dart';
import 'domain/freshness_analysis.dart';
import 'domain/listing.dart';

const _vegetables = [
  'Tomato', 'Potato', 'Onion', 'Spinach', 'Coriander', 'Carrot',
  'Bell Pepper', 'Cabbage', 'Cauliflower', 'Brinjal', 'Okra',
  'Green Chilli', 'Cucumber', 'Beans', 'Beetroot', 'Radish',
  'Pumpkin', 'Drumstick', 'Curry Leaves', 'Mint',
];

const _purchaseOptions = [
  (label: 'Just now', hours: 0),
  (label: '1 day ago', hours: 24),
  (label: '2-3 days', hours: 48),
  (label: '3-5 days', hours: 96),
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
  int _currentStep = 1;

  // Form states pre-filled with mockup data
  final _quantity = TextEditingController(text: '25.0');
  final _priceController = TextEditingController(text: '28.00');
  final _variety = TextEditingController(text: 'Hybrid Tomato');
  final _description = TextEditingController(
      text: 'Fresh, firm and juicy tomatoes. Handpicked and sorted for best quality. Ideal for cooking, salads and sauces.');
  final _pickupInstructions = TextEditingController(
      text: 'Please call before arriving. Gate number: 12. Contact: Rahul - 98765 43210');

  XFile? _photo;
  String _imageKey = '';
  bool _photoBusy = false;
  String? _photoResult;

  String? _vegetable = 'Tomato';
  StorageCondition _storage = StorageCondition.refrigerated;
  int _purchaseIdx = 0;
  String _quality = 'Excellent';
  bool _organic = true;
  String _grade = 'Grade A';
  String _priceType = 'Per kg';
  String _pickupPreference = 'Self Pickup';

  String _availFromDate = '13 May 2025';
  String _availFromTime = '09:00 AM';
  String _availUntilDate = '14 May 2025';
  String _availUntilTime = '06:00 PM';
  String _location = 'Indiranagar, Bengaluru, Karnataka 560038';
  bool _stockVisibility = true;

  FreshnessAnalysis? _analysis;
  bool _analyzing = false;
  bool _submitting = false;
  Timer? _debounce;

  DateTime get _purchasedAt => DateTime.now()
      .subtract(Duration(hours: _purchaseOptions[_purchaseIdx].hours));

  double? get _qty => double.tryParse(_quantity.text.trim());
  bool get _qtyOk => _qty != null && _qty! >= _minQty && _qty! <= _maxQty;

  @override
  void initState() {
    super.initState();
    _scheduleAnalyze();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _quantity.dispose();
    _priceController.dispose();
    _variety.dispose();
    _description.dispose();
    _pickupInstructions.dispose();
    super.dispose();
  }

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

  void _setQty(double value) {
    final v = value.clamp(_minQty, _maxQty);
    _quantity.text = v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(1);
    _scheduleAnalyze();
    setState(() {});
  }

  void _bumpQty(double delta) {
    final cur = _qty ?? 0.0;
    _setQty(cur + delta);
  }

  void _bumpPrice(double delta) {
    final cur = double.tryParse(_priceController.text) ?? 0.0;
    final res = (cur + delta).clamp(1.0, 999.0);
    _priceController.text = res.toStringAsFixed(2);
    setState(() {});
  }

  void _scheduleAnalyze() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 380), _analyze);
  }

  Future<void> _analyze() async {
    if (_vegetable == null || !_qtyOk) return;
    if (mounted) setState(() => _analyzing = true);
    try {
      final a = await ref.read(listingsProvider.notifier).analyze(
            vegetable: _vegetable!,
            quantityKg: _qty!,
            storage: _storage,
            purchasedAt: _purchasedAt,
          );
      if (mounted) {
        setState(() {
          _analysis = a;
        });
      }
    } catch (_) {} finally {
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
    final finalPrice = double.tryParse(_priceController.text) ?? a?.recommendedPrice ?? 0.0;

    final listing = Listing(
      id: 'lst_${DateTime.now().millisecondsSinceEpoch}',
      vegetable: _vegetable!,
      quantityKg: _qty!,
      basePrice: a?.marketPrice ?? 0,
      recommendedPrice: finalPrice,
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
    _resetForm();
    _toast('Listing published successfully!');
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
      _vegetable = 'Tomato';
      _storage = StorageCondition.refrigerated;
      _purchaseIdx = 0;
      _organic = true;
      _analysis = null;
      _analyzing = false;
      _submitting = false;
      _currentStep = 1;
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
      body: Column(
        children: [
          _buildGreenHeader(),
          _buildStepper(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: 16),
              children: [
                if (_currentStep == 1) ..._buildStep1(),
                if (_currentStep == 2) ..._buildStep2(),
                if (_currentStep == 3) ..._buildStep3(),
                if (_currentStep == 4) ..._buildStep4(),
              ],
            ),
          ),
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  Widget _buildGreenHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 20,
        left: AppSpacing.screen,
        right: AppSpacing.screen,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: Colors.white,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Listing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentStep == 4 ? 'Review your details before publishing' : 'List your surplus produce and help reduce food waste',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              _toast('Draft Saved Successfully');
              context.pop();
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              side: const BorderSide(color: Colors.white38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedInvoice01, color: Colors.white, size: 15),
            label: const Text('Save Draft', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final steps = ['Product Info', 'Pricing', 'Availability', 'Review'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 16,
                right: 16,
                child: Container(
                  height: 2.5,
                  color: AppColors.border,
                ),
              ),
              Positioned(
                left: 16,
                width: MediaQuery.of(context).size.width * 0.25 * (_currentStep - 1),
                child: Container(
                  height: 2.5,
                  color: AppColors.primary,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  final stepNum = index + 1;
                  final isDone = stepNum < _currentStep;
                  final isActive = stepNum == _currentStep;
                  return Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDone || isActive ? AppColors.primary : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone || isActive ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isDone
                        ? const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle02, size: 14, color: Colors.white)
                        : Text(
                            '$stepNum',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDone || isActive ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              final stepName = steps[index];
              final isActive = (index + 1) == _currentStep;
              return SizedBox(
                width: 68,
                child: Text(
                  stepName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive ? AppColors.primaryDark : AppColors.textMuted,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Product Info ─────────────────────────────────────────────
  List<Widget> _buildStep1() {
    return [
      _buildSectionHeader('Identify Your Produce', 'Take a clear photo and we\'ll identify it for you'),
      const SizedBox(height: 12),
      _buildPhotoSelectorCard(),
      const SizedBox(height: 20),
      _buildInputContainer(
        'Quantity *',
        'How much produce do you have to sell?',
        _buildQtyCounter(),
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildInputContainer(
              'When was it harvested/purchased? *',
              'Select how recent it is',
              _buildHarvestChips(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInputContainer(
              'Storage condition *',
              'How is produce stored?',
              _buildStorageDropdown(),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildInputContainer(
        'Organic',
        'Grown without synthetic chemicals',
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Organic', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            Transform.scale(
              scale: 0.9,
              child: Switch(
                value: _organic,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _organic = v),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _buildInputContainer(
        'Description *',
        'Add key details about your produce',
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _description,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: 'Enter description...',
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            Text(
              '${_description.text.length}/300',
              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildInputContainer(String title, String subtitle, Widget child) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildPhotoSelectorCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _takePhoto,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _photo != null
                        ? Image.file(File(_photo!.path), fit: BoxFit.cover, width: 90, height: 90)
                        : Image.asset('assets/images/tomato.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                            return Container(color: AppColors.primarySurface);
                          }),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(icon: HugeIcons.strokeRoundedCamera01, size: 16, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDFBF4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle02, size: 10, color: Color(0xFF27AE60)),
                      SizedBox(width: 4),
                      Text('Identified', style: TextStyle(color: Color(0xFF27AE60), fontSize: 10, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _vegetable ?? 'Unknown',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                const Text('Looks correct?', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickVegetable,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit01, color: AppColors.textSecondary, size: 12),
                  label: const Text('Change', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 80, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Not correct?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                const Text('Search and select manually', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickVegetable,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    side: const BorderSide(color: Color(0xFF27AE60)),
                    backgroundColor: const Color(0xFFEDFBF4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: Color(0xFF27AE60), size: 14),
                  label: const Text('Choose Produce', style: TextStyle(color: Color(0xFF27AE60), fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyCounter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _counterBtn(HugeIcons.strokeRoundedMinusSign, () => _bumpQty(-1)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IntrinsicWidth(
                      child: TextField(
                        controller: _quantity,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          border: InputBorder.none,
                          filled: false,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Text('kg', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
            _counterBtn(HugeIcons.strokeRoundedPlusSign, () => _bumpQty(1)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _quickQty.map((q) {
            final active = _qty == q;
            return GestureDetector(
              onTap: () => _setQty(q),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFEDFBF4) : Colors.white,
                  border: Border.all(color: active ? const Color(0xFF27AE60) : AppColors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${q.toInt()} kg',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: active ? const Color(0xFF27AE60) : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        const Text('Min 0.1 kg  •  Max 500 kg', style: TextStyle(fontSize: 8.5, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _counterBtn(List<List<dynamic>> icon, VoidCallback onTap) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: HugeIcon(icon: icon, color: AppColors.textPrimary, size: 14),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      value: 'Kilogram (kg)',
      isExpanded: true,
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        isDense: true,
      ),
      items: ['Kilogram (kg)', 'Gram (g)'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 11.5)))).toList(),
      onChanged: (_) {},
    );
  }

  Widget _buildPackagingDropdown() {
    return DropdownButtonFormField<String>(
      value: 'Loose/Unpacked',
      isExpanded: true,
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        isDense: true,
      ),
      items: ['Loose/Unpacked', 'Crates', 'Bags'].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 11.5)))).toList(),
      onChanged: (_) {},
    );
  }

  Widget _buildHarvestChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(_purchaseOptions.length, (idx) {
        final opt = _purchaseOptions[idx];
        final active = _purchaseIdx == idx;
        return GestureDetector(
          onTap: () => setState(() {
            _purchaseIdx = idx;
            _scheduleAnalyze();
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFEDFBF4) : Colors.white,
              border: Border.all(color: active ? const Color(0xFF27AE60) : AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              opt.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: active ? const Color(0xFF27AE60) : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }

  String _getStorageLabel(StorageCondition condition) {
    return switch (condition) {
      StorageCondition.refrigerated => 'Refrigerated (2-8°C)',
      StorageCondition.coldStorage => 'Cold Storage (<0°C)',
      StorageCondition.room => 'Room Temp',
    };
  }

  Widget _buildStorageDropdown() {
    return DropdownButtonFormField<StorageCondition>(
      value: _storage,
      isExpanded: true,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        isDense: true,
      ),
      items: StorageCondition.values
          .map((s) => DropdownMenuItem(value: s, child: Text(_getStorageLabel(s), style: const TextStyle(fontSize: 10, overflow: TextOverflow.ellipsis))))
          .toList(),
      onChanged: (v) {
        setState(() => _storage = v ?? _storage);
        _scheduleAnalyze();
      },
    );
  }

  Widget _buildQualityRating() {
    final ratings = [
      ('Excellent', '90-100%', const Color(0xFF27AE60)),
      ('Good', '70-89%', const Color(0xFF27AE60)),
      ('Average', '50-69%', const Color(0xFFF2994A)),
      ('Fair', '30-49%', const Color(0xFFF23E3E)),
    ];
    return Column(
      children: ratings.map((r) {
        final active = _quality == r.$1;
        return GestureDetector(
          onTap: () => setState(() => _quality = r.$1),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: active ? r.$3.withOpacity(0.08) : Colors.white,
              border: Border.all(color: active ? r.$3 : AppColors.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text(r.$1, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: active ? r.$3 : AppColors.textPrimary)),
                Text(r.$2, style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Step 2: Pricing ──────────────────────────────────────────────────
  List<Widget> _buildStep2() {
    final marketPrice = _analysis?.marketPrice ?? 40.0;
    return [
      _buildHeaderPreviewCard(),
      const SizedBox(height: 16),
      _buildSectionHeader('Set Your Price', 'We suggest a fair price based on market rate and quality.'),
      const SizedBox(height: 12),
      _buildPricingSuggestionBox(marketPrice),
      const SizedBox(height: 16),
      _buildInputContainer(
        'Your Selling Price (per kg) *',
        'Suggested range: ₹24 – ₹32/kg',
        _buildSellingPriceCounter(),
      ),
      const SizedBox(height: 16),
      _buildPriceTypeCards(),
      const SizedBox(height: 16),
      _buildImpactSummaryCard(marketPrice),
    ];
  }

  Widget _buildHeaderPreviewCard() {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: _photo != null
                  ? Image.file(File(_photo!.path), fit: BoxFit.cover)
                  : Image.asset('assets/images/tomato.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                      return Container(color: AppColors.primarySurface);
                    }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _vegetable ?? 'Unknown',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Quantity: ${_qty?.toInt() ?? 0} kg   •   Storage: ${_storage.label}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => setState(() => _currentStep = 1),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 28),
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit01, color: AppColors.textSecondary, size: 12),
            label: const Text('Edit', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSuggestionBox(double marketPrice) {
    final suggested = _analysis?.recommendedPrice ?? 28.0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Suggested Price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDFBF4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedRefresh, size: 10, color: Color(0xFF27AE60)),
                    SizedBox(width: 4),
                    Text('Auto-calculated', style: TextStyle(color: Color(0xFF27AE60), fontSize: 10, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recommended Price', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Text('₹${suggested.toInt()}/kg', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF27AE60))),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDFBF4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('30% better price for quick sale', style: TextStyle(color: Color(0xFF27AE60), fontSize: 8, fontWeight: FontWeight.w800)),
                        ),
                        const HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, size: 11, color: AppColors.textMuted),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 60, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Freshness Rating', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDFBF4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_analysis != null ? '${_analysis?.band.label}' : 'Excellent (90-100%)', style: const TextStyle(color: Color(0xFF27AE60), fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Text('Market Price ₹${marketPrice.toInt()}/kg', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        const HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, size: 11, color: AppColors.textMuted),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSellingPriceCounter() {
    return Column(
      children: [
        Row(
          children: [
            _counterBtn(HugeIcons.strokeRoundedMinusSign, () => _bumpPrice(-1)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _priceController,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(
                    suffixText: '₹/kg',
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            _counterBtn(HugeIcons.strokeRoundedPlusSign, () => _bumpPrice(1)),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceTypeCards() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _priceType = 'Per kg'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _priceType == 'Per kg' ? const Color(0xFFEDFBF4) : Colors.white,
                border: Border.all(color: _priceType == 'Per kg' ? const Color(0xFF27AE60) : AppColors.border, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: 'Per kg',
                    groupValue: _priceType,
                    activeColor: const Color(0xFF27AE60),
                    onChanged: (v) => setState(() => _priceType = v!),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Per kg', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                        Text('Price per kilogram', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _priceType = 'Fixed Price'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _priceType == 'Fixed Price' ? const Color(0xFFEDFBF4) : Colors.white,
                border: Border.all(color: _priceType == 'Fixed Price' ? const Color(0xFF27AE60) : AppColors.border, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: 'Fixed Price',
                    groupValue: _priceType,
                    activeColor: const Color(0xFF27AE60),
                    onChanged: (v) => setState(() => _priceType = v!),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fixed Price', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                        Text('Set a fixed total price', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImpactSummaryCard(double marketPrice) {
    final price = double.tryParse(_priceController.text) ?? 28.0;
    final totalValue = price * (_qty ?? 0.0);
    final saves = (marketPrice - price).clamp(0, 999.0) * (_qty ?? 0.0);
    final meals = (totalValue / 11.2).toInt();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7EE),
            border: Border.all(color: const Color(0xFFFFEAD1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, size: 14, color: Color(0xFFF2994A)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tip: Pricing slightly lower helps you sell faster and reduces food waste.',
                  style: TextStyle(color: Color(0xFFD6751D), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Earnings & Impact', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              const Text('See how your listing creates value and impact.', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _impactMetric(HugeIcons.strokeRoundedMoneyBag01, 'Listing Value', '₹${totalValue.toInt()}', 'You earn'),
                  Container(width: 1, height: 50, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 8)),
                  _impactMetric(HugeIcons.strokeRoundedUserGroup, 'Buyer Saves', '₹${saves.toInt()}', 'vs market price'),
                  Container(width: 1, height: 50, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 8)),
                  _impactMetric(HugeIcons.strokeRoundedDish01, 'Meal Equivalent', '$meals', 'Meals saved'),
                ],
              ),
              const Divider(height: 24),
              const Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedLeaf02, color: Color(0xFF27AE60), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'By listing this produce, you\'re helping reduce food waste and support sustainability.',
                      style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _impactMetric(List<List<dynamic>> icon, String label, String value, String sub) {
    return Expanded(
      child: Column(
        children: [
          HugeIcon(icon: icon, color: const Color(0xFF27AE60), size: 20),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // ── Step 3: Availability ─────────────────────────────────────────────
  List<Widget> _buildStep3() {
    return [
      _buildHeaderPreviewCard(),
      const SizedBox(height: 16),
      _buildSectionHeader('Pickup Preference *', 'Choose when and how buyers can pick up the produce.'),
      const SizedBox(height: 12),
      _buildPickupTypeCards(),
      const SizedBox(height: 16),
      _buildInputContainer(
        'Available From *',
        'Date & Time select',
        _buildDateTimeRow(
          _availFromDate,
          _availFromTime,
          () {},
          () {},
        ),
      ),
      const SizedBox(height: 12),
      _buildInputContainer(
        'Available Until (Optional)',
        'Date & Time select',
        _buildDateTimeRow(
          _availUntilDate,
          _availUntilTime,
          () {},
          () {},
        ),
      ),
      const SizedBox(height: 16),
      _buildInputContainer(
        'Pickup Instructions (Optional)',
        'Any special instructions for buyers',
        TextField(
          controller: _pickupInstructions,
          maxLines: 2,
          maxLength: 150,
          decoration: const InputDecoration(
            counterText: '',
            hintText: 'e.g. gate code, phone contact...',
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      const SizedBox(height: 10),
      const Row(
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedDeliveryTruck02, color: Color(0xFF27AE60), size: 14),
          SizedBox(width: 6),
          Text('Faster pickups, happier buyers!', style: TextStyle(color: Color(0xFF27AE60), fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
      const SizedBox(height: 16),
      _buildInputContainer(
        'Location *',
        'Pickup address',
        Row(
          children: [
            const HugeIcon(icon: HugeIcons.strokeRoundedLocation01, color: Color(0xFF27AE60), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_location, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () {},
                    child: const Text('Change location', style: TextStyle(fontSize: 11.5, color: Color(0xFF27AE60), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {},
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedLocation01, size: 15),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _buildInputContainer(
        'Stock Visibility',
        'Show available quantity to buyers',
        Column(
          children: [
            Row(
              children: [
                const Text('Stock Visibility', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const Spacer(),
                Switch(
                  value: _stockVisibility,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _stockVisibility = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFEDFBF4), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const HugeIcon(icon: HugeIcons.strokeRoundedEye, size: 12, color: Color(0xFF27AE60)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Displaying stock builds trust and can increase order chances.',
                      style: TextStyle(color: const Color(0xFF27AE60), fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildPickupTypeCards() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _pickupPreference = 'Self Pickup'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _pickupPreference == 'Self Pickup' ? const Color(0xFFEDFBF4) : Colors.white,
                border: Border.all(color: _pickupPreference == 'Self Pickup' ? const Color(0xFF27AE60) : AppColors.border, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: 'Self Pickup',
                    groupValue: _pickupPreference,
                    activeColor: const Color(0xFF27AE60),
                    onChanged: (v) => setState(() => _pickupPreference = v!),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Self Pickup', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                        Text('Buyers will pickup', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _pickupPreference = 'Request Pickup'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _pickupPreference == 'Request Pickup' ? const Color(0xFFEDFBF4) : Colors.white,
                border: Border.all(color: _pickupPreference == 'Request Pickup' ? const Color(0xFF27AE60) : AppColors.border, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: 'Request Pickup',
                    groupValue: _pickupPreference,
                    activeColor: const Color(0xFF27AE60),
                    onChanged: (v) => setState(() => _pickupPreference = v!),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Request Pickup', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                        Text('We will arrange pickup', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow(
    String dateValue,
    String timeValue,
    VoidCallback onDateTap,
    VoidCallback onTimeTap,
  ) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const HugeIcon(icon: HugeIcons.strokeRoundedCalendar01, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dateValue,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01, color: AppColors.textSecondary, size: 16),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: onTimeTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const HugeIcon(icon: HugeIcons.strokeRoundedClock01, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      timeValue,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01, color: AppColors.textSecondary, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSelector(String val, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  // ── Step 4: Review ───────────────────────────────────────────────────
  List<Widget> _buildStep4() {
    return [
      _buildSectionHeader('Almost there!', 'Please review all details before publishing your listing.'),
      const SizedBox(height: 12),
      _buildReviewHeaderCard(),
      const SizedBox(height: 16),
      _buildReviewSectionCard(
        'Product Information',
        [
          ('Quantity', '${_qty?.toInt()} kg'),
          ('When harvested/purchased', _purchaseOptions[_purchaseIdx].label),
          ('Storage condition', _storage.label),
          ('Organic', _organic ? 'Yes' : 'No'),
          ('Description', _description.text),
        ],
        1,
      ),
      const SizedBox(height: 16),
      _buildReviewSectionCard(
        'Pricing & Impact',
        [
          ('Your Selling Price', '₹${double.tryParse(_priceController.text)?.toInt() ?? 28}/kg'),
          ('Listing Value', '₹${((double.tryParse(_priceController.text) ?? 28) * (_qty ?? 25)).toInt()}'),
          ('Buyer Saves', '₹${((40 - (double.tryParse(_priceController.text) ?? 28)) * (_qty ?? 25)).toInt()}'),
          ('Meal Equivalent', '${(((double.tryParse(_priceController.text) ?? 28) * (_qty ?? 25)) / 11.2).toInt()} meals saved'),
        ],
        2,
      ),
      const SizedBox(height: 16),
      _buildReviewSectionCard(
        'Availability & Pickup',
        [
          ('Pickup Type', _pickupPreference),
          ('Available From', '$_availFromDate, $_availFromTime'),
          ('Available Until', '$_availUntilDate, $_availUntilTime'),
          ('Pickup Instructions', _pickupInstructions.text),
          ('Location', _location),
          ('Stock Visibility', _stockVisibility ? 'On' : 'Off'),
        ],
        3,
      ),
    ];
  }

  Widget _buildReviewHeaderCard() {
    final price = double.tryParse(_priceController.text) ?? 28.0;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: _photo != null
                  ? Image.file(File(_photo!.path), fit: BoxFit.cover)
                  : Image.asset('assets/images/tomato.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                      return Container(color: AppColors.primarySurface);
                    }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _vegetable ?? 'Unknown',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                Text(
                  '${_qty?.toInt() ?? 0} kg   •   ₹${price.toInt()}/kg   •   Storage: ${_storage.label}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFEDFBF4), borderRadius: BorderRadius.circular(4)),
                  child: Text(_analysis != null ? '${_analysis?.band.label}' : 'Excellent (90-100%)', style: const TextStyle(color: Color(0xFF27AE60), fontSize: 9.5, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => setState(() => _currentStep = 1),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 28),
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit01, color: AppColors.textSecondary, size: 12),
            label: const Text('Edit', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSectionCard(String title, List<(String, String)> items, int stepToGoBack) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              GestureDetector(
                onTap: () => setState(() => _currentStep = stepToGoBack),
                child: const Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit01, color: Color(0xFF27AE60), size: 13),
                    SizedBox(width: 4),
                    Text('Edit', style: TextStyle(color: Color(0xFF27AE60), fontSize: 12, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          for (final item in items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(item.$1, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(item.$2, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Bottom Nav Bar ───────────────────────────────────────────────────
  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_currentStep > 1) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.textPrimary, size: 16),
                label: const Text('Back', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () {
                if (_currentStep < 4) {
                  if (_currentStep == 1) {
                    final err = _validate();
                    if (err != null) return _toast(err);
                  }
                  setState(() => _currentStep++);
                } else {
                  _submit();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F8A5F),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep == 4
                        ? 'Publish Listing'
                        : _currentStep == 3
                            ? 'Next: Review'
                            : _currentStep == 2
                                ? 'Next: Availability'
                                : 'Next: Pricing',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 6),
                  HugeIcon(
                    icon: _currentStep == 4 ? HugeIcons.strokeRoundedSent : HugeIcons.strokeRoundedArrowRight01,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final list = _query.isEmpty
        ? _vegetables
        : _vegetables
            .where((v) => v.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        child: Column(
          children: [
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search…',
                prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final v = list[i];
                  final sel = v == widget.selected;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const HugeIcon(icon: HugeIcons.strokeRoundedLeaf02,
                        color: AppColors.primary, size: 20),
                    title: Text(v,
                        style: TextStyle(
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w500)),
                    trailing: sel
                        ? const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                            color: AppColors.primary, size: 20)
                        : null,
                    onTap: () => Navigator.of(context).pop(v),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
