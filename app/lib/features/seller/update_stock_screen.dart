import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import 'application/listings_providers.dart';
import 'domain/listing.dart';

class UpdateStockScreen extends ConsumerStatefulWidget {
  const UpdateStockScreen({super.key, required this.listing});
  final Listing listing;

  @override
  ConsumerState<UpdateStockScreen> createState() => _UpdateStockScreenState();
}

class _UpdateStockScreenState extends ConsumerState<UpdateStockScreen> {
  late final TextEditingController _qty =
      TextEditingController(text: _fmt(widget.listing.quantityKg));
  late final TextEditingController _description =
      TextEditingController(text: 'Fresh, firm and juicy tomatoes. Handpicked and sorted for best quality. Ideal for cooking, salads and sauces.');

  String _unitType = 'Kilogram (kg)';
  String _packagingType = 'Loose/Unpacked';
  StorageCondition _storageCondition = StorageCondition.refrigerated;
  String _qualityFreshness = 'Excellent (90-100%)';
  String _harvestedTime = 'Just now';
  String _organic = 'Yes';
  bool _stockVisibility = true;

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
    _description.dispose();
    super.dispose();
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  Widget _fallbackImage() {
    return Image.asset(
      'assets/images/tomato.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: AppColors.primarySurface),
    );
  }

  Future<void> _save() async {
    try {
      await ref.read(listingsProvider.notifier).updateStock(widget.listing.id, _value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _value <= 0
                ? '${widget.listing.vegetable} marked sold out'
                : 'Stock updated to ${formatKg(_value)}',
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listDate = widget.listing.createdAt;
    final formattedDate = '${listDate.day} ${_months[listDate.month - 1]} ${listDate.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          _buildGreenHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProductPreviewCard(formattedDate),
                  const SizedBox(height: 12),
                  _buildAlertBanner(),
                  const SizedBox(height: 16),
                  _buildQuantityCard(),
                  const SizedBox(height: 16),
                  _buildDetailsCard(),
                  const SizedBox(height: 16),
                  _buildStockVisibilityCard(),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Save Changes',
                    onPressed: _save,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Stock',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Update quantity and details of your listing',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _save,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              side: const BorderSide(color: Colors.white38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedInvoice01, color: Colors.white, size: 15),
            label: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPreviewCard(String formattedDate) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: widget.listing.imagePath != null && widget.listing.imagePath!.isNotEmpty
                  ? Image.file(File(widget.listing.imagePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackImage())
                  : widget.listing.imageUrl != null && widget.listing.imageUrl!.isNotEmpty
                      ? Image.network(widget.listing.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackImage())
                      : _fallbackImage(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.listing.vegetable,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Listed on $formattedDate  •  Freshness: ${widget.listing.band.label}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedEye, size: 13, color: Color(0xFF27AE60)),
                    SizedBox(width: 4),
                    Text(
                      'View Listing',
                      style: TextStyle(color: Color(0xFF27AE60), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDFBF4),
        border: Border.all(color: const Color(0xFF27AE60).withOpacity(0.15)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, size: 14, color: Color(0xFF27AE60)),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Update the quantity and any details that have changed.',
              style: TextStyle(fontSize: 10.5, color: Color(0xFF27AE60), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadgeHeader(1, 'Quantity & Unit'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quantity Selector
              Expanded(
                flex: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Quantity *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const Text('How much produce do you have now?', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _counterBtn(HugeIcons.strokeRoundedMinusSign, () => _bump(-1)),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IntrinsicWidth(
                                  child: TextField(
                                    controller: _qty,
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
                        _counterBtn(HugeIcons.strokeRoundedPlusSign, () => _bump(1)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [5, 10, 25, 30, 50].map((val) {
                        final active = _value == val.toDouble();
                        return GestureDetector(
                          onTap: () {
                            _qty.text = _fmt(val.toDouble());
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: active ? const Color(0xFFEDFBF4) : Colors.white,
                              border: Border.all(color: active ? const Color(0xFF27AE60) : AppColors.border),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$val kg',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
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
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 110, color: AppColors.border),
              const SizedBox(width: 12),
              // Unit Type Dropdown
              Expanded(
                flex: 9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Unit Type *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const Text('Select the unit of measurement', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _unitType,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedNote01, size: 14, color: AppColors.textSecondary),
                        isDense: true,
                      ),
                      items: ['Kilogram (kg)', 'Gram (g)'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 11)))).toList(),
                      onChanged: (v) => setState(() => _unitType = v!),
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

  Widget _buildDetailsCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadgeHeader(2, 'Update Details (Optional)'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Packaging Type', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _packagingType,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedPackage, size: 14, color: AppColors.textSecondary),
                        isDense: true,
                      ),
                      items: ['Loose/Unpacked', 'Crates', 'Bags'].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 11)))).toList(),
                      onChanged: (v) => setState(() => _packagingType = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Storage Condition', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<StorageCondition>(
                      value: _storageCondition,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedTemperature, size: 14, color: AppColors.textSecondary),
                        isDense: true,
                      ),
                      items: StorageCondition.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label, style: const TextStyle(fontSize: 10.5)))).toList(),
                      onChanged: (v) => setState(() => _storageCondition = v!),
                    ),
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
                    const Text('Quality / Freshness', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _qualityFreshness,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedChartLineData01, size: 14, color: AppColors.textSecondary),
                        isDense: true,
                      ),
                      items: ['Excellent (90-100%)', 'Good (70-89%)', 'Average (50-69%)', 'Fair (30-49%)'].map((q) => DropdownMenuItem(value: q, child: Text(q, style: const TextStyle(fontSize: 11)))).toList(),
                      onChanged: (v) => setState(() => _qualityFreshness = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('When was it harvested/purchased?', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _harvestedTime,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedCalendar01, size: 14, color: AppColors.textSecondary),
                        isDense: true,
                      ),
                      items: ['Just now', '1 day ago', '2-3 days ago', '3-5 days ago', 'A week ago'].map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 11)))).toList(),
                      onChanged: (v) => setState(() => _harvestedTime = v!),
                    ),
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
                    const Text('Organic', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _organic,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedLeaf02, size: 14, color: AppColors.textSecondary),
                        isDense: true,
                      ),
                      items: ['Yes', 'No'].map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 11)))).toList(),
                      onChanged: (v) => setState(() => _organic = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Description (Optional)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const Text('Update description if needed', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _description,
                maxLines: 3,
                maxLength: 300,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Enter description...',
                  counterText: '',
                  contentPadding: EdgeInsets.all(12),
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
        ],
      ),
    );
  }

  Widget _buildStockVisibilityCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildBadgeHeader(3, 'Stock Visibility'),
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
                    'Displaying updated stock builds trust and increases order chances.',
                    style: TextStyle(color: const Color(0xFF27AE60), fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeHeader(int num, String label) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF27AE60),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$num',
            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _counterBtn(List<List<dynamic>> icon, VoidCallback onTap) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: HugeIcon(icon: icon, color: AppColors.textPrimary, size: 16),
        ),
      ),
    );
  }
}
