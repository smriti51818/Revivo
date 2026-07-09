import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/models/freshness.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import 'application/listings_providers.dart';
import 'domain/listing.dart';

/// Single-page "Edit Listing" screen — a clean, scannable form modelled on
/// modern vendor apps (product preview → photos → quantity → key details →
/// Save). Quantity is the one field persisted today (via [updateStock]); the
/// other controls are captured in-screen and shown, ready for a future model
/// change. Photos can be changed/added locally so the upload UX feels real.
class UpdateStockScreen extends ConsumerStatefulWidget {
  const UpdateStockScreen({super.key, required this.listing});
  final Listing listing;

  @override
  ConsumerState<UpdateStockScreen> createState() => _UpdateStockScreenState();
}

class _UpdateStockScreenState extends ConsumerState<UpdateStockScreen> {
  late final TextEditingController _qty =
      TextEditingController(text: _fmt(widget.listing.quantityKg));

  // Preloaded from the actual listing so the form reflects real stored state.
  late StorageCondition _storageCondition = widget.listing.storage;
  late bool _organic = widget.listing.organic;
  String _qualityFreshness = 'Excellent (90-100%)';

  // Up to two locally-picked photos: slot 0 = close-up, slot 1 = whole produce.
  // Null means "not changed" — slot 0 falls back to the listing's own image.
  final List<String?> _photos = [null, null];
  bool _photosEdited = false;

  final ImagePicker _picker = ImagePicker();
  bool _saving = false;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  double get _value => double.tryParse(_qty.text.trim()) ?? 0;

  void _bump(double delta) {
    final next = (_value + delta).clamp(0.1, 500.0).toDouble();
    _qty.text = _fmt(next);
    setState(() {});
  }

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  // ---------------------------------------------------------------------------
  // Photos
  // ---------------------------------------------------------------------------

  Future<void> _pickPhoto(int index, ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return; // user cancelled
      if (!mounted) return;
      setState(() {
        _photos[index] = picked.path;
        _photosEdited = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add photo: $e')),
      );
    }
  }

  void _choosePhotoSource(int index) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              _sheetTile(
                ctx,
                HugeIcons.strokeRoundedCamera01,
                'Take a photo',
                () => _pickPhoto(index, ImageSource.camera),
              ),
              _sheetTile(
                ctx,
                HugeIcons.strokeRoundedImage01,
                'Choose from gallery',
                () => _pickPhoto(index, ImageSource.gallery),
              ),
              if (_photos[index] != null)
                _sheetTile(
                  ctx,
                  HugeIcons.strokeRoundedDelete02,
                  'Remove photo',
                  () => setState(() {
                    _photos[index] = null;
                    _photosEdited = true;
                  }),
                  danger: true,
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetTile(
    BuildContext ctx,
    List<List<dynamic>> icon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;
    return ListTile(
      leading: HugeIcon(icon: icon, size: 20, color: color),
      title: Text(
        label,
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: color),
      ),
      onTap: () {
        Navigator.of(ctx).pop();
        onTap();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // If the seller changed a photo, upload it first so its new key can be
      // saved onto the listing (otherwise the image would never update).
      String? imageKey;
      final newPhoto = _photos.firstWhere(
        (p) => p != null && p.isNotEmpty,
        orElse: () => null,
      );
      if (_photosEdited && newPhoto != null) {
        imageKey =
            await ref.read(listingsProvider.notifier).uploadPhoto(newPhoto);
      }
      if (!mounted) return;
      await ref
          .read(listingsProvider.notifier)
          .updateStock(widget.listing.id, _value, imageKey: imageKey);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _value <= 0
                ? '${widget.listing.vegetable} marked sold out'
                : _photosEdited && imageKey != null && imageKey.isNotEmpty
                    ? 'Listing updated — photo & stock saved'
                    : 'Stock updated to ${formatKg(_value)}',
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update: $e')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final listDate = widget.listing.createdAt;
    final formattedDate =
        '${listDate.day} ${_months[listDate.month - 1]} ${listDate.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _buildPreviewCard(formattedDate),
                  const SizedBox(height: AppSpacing.md),
                  _buildPhotosCard(),
                  const SizedBox(height: AppSpacing.md),
                  _buildQuantityCard(),
                  const SizedBox(height: AppSpacing.md),
                  _buildDetailsCard(),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Save Changes',
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    loading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
                  'Edit Listing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.listing.vegetable,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Product preview -------------------------------------------------------

  Widget _buildPreviewCard(String formattedDate) {
    final band = widget.listing.liveBand();
    final pricePerKg = widget.listing.livePricePerKg();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 68,
              height: 68,
              child: _slotImage(0, small: true),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.listing.vegetable,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _bandChip(band),
                    const SizedBox(width: 8),
                    Text(
                      '${formatMoney(pricePerKg)}/kg',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Listed on $formattedDate',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bandChip(FreshnessBand band) {
    final (Color fg, Color bg) = switch (band) {
      FreshnessBand.good => (AppColors.primaryDark, AppColors.successSurface),
      FreshnessBand.useSoon => (AppColors.warning, AppColors.warningSurface),
      FreshnessBand.rescue => (AppColors.danger, AppColors.dangerSurface),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        band.label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  // ---- Photos ---------------------------------------------------------------

  /// Builds the image shown for a photo slot. Slot 0 falls back to the
  /// listing's stored photo (file or network) when nothing new is picked.
  Widget _slotImage(int index, {bool small = false}) {
    final picked = _photos[index];
    if (picked != null && picked.isNotEmpty) {
      return Image.file(File(picked),
          fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallbackImage());
    }
    if (index == 0) {
      final path = widget.listing.imagePath;
      final url = widget.listing.imageUrl;
      if (path != null && path.isNotEmpty) {
        return Image.file(File(path),
            fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallbackImage());
      }
      if (url != null && url.isNotEmpty) {
        return Image.network(url,
            fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallbackImage());
      }
    }
    return _emptySlot(small: small);
  }

  Widget _fallbackImage() {
    return Container(
      color: AppColors.primarySurface,
      alignment: Alignment.center,
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedLeaf02,
        size: 28,
        color: AppColors.primary.withValues(alpha: 0.55),
      ),
    );
  }

  Widget _emptySlot({bool small = false}) {
    return Container(
      color: AppColors.surfaceAlt,
      alignment: Alignment.center,
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedImageAdd01,
        size: small ? 24 : 30,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _buildPhotosCard() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(
                  icon: HugeIcons.strokeRoundedCamera01,
                  size: 18,
                  color: AppColors.textPrimary),
              const SizedBox(width: 8),
              const Text('Photos',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const Spacer(),
              if (_photosEdited)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                          icon: HugeIcons.strokeRoundedPencilEdit01,
                          size: 11,
                          color: AppColors.warning),
                      SizedBox(width: 3),
                      Text('Edited',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.warning)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Add a close-up and one of the whole batch — clear photos sell faster.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _photoSlot(0, 'Close-up')),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _photoSlot(1, 'Whole produce')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoSlot(int index, String caption) {
    final hasPhoto = _photos[index] != null ||
        (index == 0 &&
            ((widget.listing.imagePath?.isNotEmpty ?? false) ||
                (widget.listing.imageUrl?.isNotEmpty ?? false)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _choosePhotoSource(index),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasPhoto ? AppColors.border : AppColors.borderStrong,
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _slotImage(index),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.card,
                      ),
                      child: HugeIcon(
                        icon: hasPhoto
                            ? HugeIcons.strokeRoundedPencilEdit01
                            : HugeIcons.strokeRoundedPlusSign,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ---- Quantity -------------------------------------------------------------

  Widget _buildQuantityCard() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedPackage,
                  size: 18,
                  color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text('Quantity available',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('How much produce do you have now?',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _counterBtn(HugeIcons.strokeRoundedMinusSign, () => _bump(-1)),
              Expanded(
                child: Container(
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IntrinsicWidth(
                        child: TextField(
                          controller: _qty,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            border: InputBorder.none,
                            filled: false,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('kg',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              _counterBtn(HugeIcons.strokeRoundedPlusSign, () => _bump(1)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [5, 10, 25, 30, 50].map((val) {
              final active = _value == val.toDouble();
              return GestureDetector(
                onTap: () {
                  _qty.text = _fmt(val.toDouble());
                  setState(() {});
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primarySurface : AppColors.surface,
                    border: Border.all(
                        color: active ? AppColors.primary : AppColors.border),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$val kg',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: active
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          const Text('Min 0.1 kg  •  Max 500 kg',
              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // ---- Key details ----------------------------------------------------------

  Widget _buildDetailsCard() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedNote01,
                  size: 18,
                  color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text('Details',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _fieldLabel('Storage condition'),
          const SizedBox(height: 6),
          DropdownButtonFormField<StorageCondition>(
            initialValue: _storageCondition,
            isExpanded: true,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
            decoration: _fieldDecoration(HugeIcons.strokeRoundedTemperature),
            items: StorageCondition.values
                .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.label,
                        style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (v) => setState(() => _storageCondition = v!),
          ),
          const SizedBox(height: AppSpacing.md),
          _fieldLabel('Quality / freshness'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _qualityFreshness,
            isExpanded: true,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
            decoration:
                _fieldDecoration(HugeIcons.strokeRoundedChartLineData01),
            items: const [
              'Excellent (90-100%)',
              'Good (70-89%)',
              'Average (50-69%)',
              'Fair (30-49%)'
            ]
                .map((q) => DropdownMenuItem(
                    value: q,
                    child:
                        Text(q, style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (v) => setState(() => _qualityFreshness = v!),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const HugeIcon(
                    icon: HugeIcons.strokeRoundedLeaf02,
                    size: 18,
                    color: AppColors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Organically grown',
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      Text('Shown as an organic badge to buyers',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Switch(
                  value: _organic,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _organic = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary),
      );

  InputDecoration _fieldDecoration(List<List<dynamic>> icon) {
    return InputDecoration(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 10, right: 8),
        child: HugeIcon(icon: icon, size: 16, color: AppColors.textSecondary),
      ),
      prefixIconConstraints:
          const BoxConstraints(minWidth: 36, minHeight: 36),
      isDense: true,
    );
  }

  Widget _counterBtn(List<List<dynamic>> icon, VoidCallback onTap) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: HugeIcon(icon: icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }
}
