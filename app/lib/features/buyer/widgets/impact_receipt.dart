import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/order.dart';

/// FAO/UNEP-style conversion factors, matching the backend impact engine.
const double _mealsPerKg = 2.5; // ~0.4 kg produce per served meal
const double _co2PerKg = 2.5; // kg CO2e kept out of landfill per kg

/// A shareable "impact receipt" — what this rescue meant, in money saved,
/// meals enabled, and emissions avoided. Shown once an order is completed.
class ImpactReceipt extends StatelessWidget {
  const ImpactReceipt({super.key, required this.order});

  final Order order;

  int get _meals => (order.quantityKg * _mealsPerKg).round();
  double get _co2 => order.quantityKg * _co2PerKg;

  String get _shareText =>
      'I just rescued ${formatKg(order.quantityKg)} of ${order.vegetable} on '
      'Revivo — saved ${formatMoney(order.saved)}, enough for ~$_meals meals, '
      'and kept ${_co2.toStringAsFixed(1)} kg CO₂ out of landfill. 🌱';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text('Your rescue impact',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _stat(formatMoney(order.saved), 'saved'),
              _divider(),
              _stat('$_meals', 'meals'),
              _divider(),
              _stat('${_co2.toStringAsFixed(1)} kg', 'CO₂ avoided'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _shareText));
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(
                        content: Text('Impact copied — share it anywhere')));
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Share impact'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 1),
            Text(label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      );

  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: Colors.white.withValues(alpha: 0.25),
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      );
}
