import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/models/freshness.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/band_chip.dart';
import '../../core/widgets/freshness_countdown.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/produce_image.dart';
import 'application/cart_providers.dart';
import 'domain/offer.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({super.key, required this.offer});

  final Offer offer;

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  late double _qty = widget.offer.availableKg >= 5 ? 5 : 1;

  Offer get offer => widget.offer;

  Color get _tint => switch (offer.liveBand()) {
        FreshnessBand.good => AppColors.successSurface,
        FreshnessBand.useSoon => AppColors.warningSurface,
        FreshnessBand.rescue => AppColors.dangerSurface,
      };

  void _stepQty(double delta) {
    final next = (_qty + delta).clamp(1, offer.availableKg).toDouble();
    setState(() => _qty = next);
  }

  void _addToCart() {
    ref.read(cartProvider.notifier).add(offer, _qty);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${formatKg(_qty)} ${offer.vegetable} added to cart'),
          action: SnackBarAction(
            label: 'View cart',
            onPressed: () => context.push('/buyer/cart'),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final unitPrice = offer.livePrice();
    final savingsPct = offer.liveSavingsPct();
    final total = _qty * unitPrice;
    final saved = _qty * offer.liveSavingsPerKg();

    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ProduceImage(
                        imageUrl: offer.imageUrl,
                        tint: _tint,
                        iconSize: 64,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: offer.hasClock
                          ? FreshnessCountdownPill(
                              expiresAt: offer.expiresAt!,
                              totalHours: offer.totalHours!,
                              showBandLabel: true,
                            )
                          : BandChip(
                              band: offer.band, timeRange: offer.timeRange),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text(
                  offer.vendorName,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                if (offer.distanceKm > 0) ...[
                  const Icon(Icons.place_outlined,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Text(
                    '${offer.distanceKm.toStringAsFixed(1)} km away',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              offer.vegetable,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatMoney(unitPrice)} / kg',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                if (savingsPct > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      formatMoney(offer.marketPrice),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                const Spacer(),
                if (savingsPct > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '$savingsPct% below market',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            offer.hasClock ? _clockHero() : _freshnessCard(),
            const SizedBox(height: AppSpacing.lg),
            _quantityCard(),
            const SizedBox(height: AppSpacing.lg),
            _summaryRow('Subtotal', formatMoney(total)),
            const SizedBox(height: 6),
            if (saved > 0)
              _summaryRow('You save vs market', formatMoney(saved),
                  highlight: true),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Add to cart · ${formatMoney(total)}',
              icon: Icons.add_shopping_cart_outlined,
              onPressed: _addToCart,
            ),
          ],
        ),
      ),
    );
  }

  /// The ticking centerpiece: a live countdown to the end of the usable window,
  /// the current band, and when/how far the price will drop next.
  Widget _clockHero() {
    ({Color fg, Color bg}) tones(FreshnessBand band) => switch (band) {
          FreshnessBand.good =>
            (fg: AppColors.success, bg: AppColors.successSurface),
          FreshnessBand.useSoon =>
            (fg: AppColors.warning, bg: AppColors.warningSurface),
          FreshnessBand.rescue =>
            (fg: AppColors.danger, bg: AppColors.dangerSurface),
        };

    return FreshnessTicker(
      expiresAt: offer.expiresAt!,
      totalHours: offer.totalHours!,
      builder: (context, remaining, band) {
        final t = tones(band);
        final expired = remaining.inSeconds <= 0;
        final totalH = offer.totalHours!;
        final remH = remaining.inSeconds / 3600.0;

        // Where the price steps down next, and how long until then.
        double? nextRatio, nextFactor;
        if (band == FreshnessBand.good) {
          nextRatio = 0.5;
          nextFactor = 0.7;
        } else if (band == FreshnessBand.useSoon) {
          nextRatio = 0.2;
          nextFactor = 0.4;
        }
        String dropLine;
        if (expired) {
          dropLine = 'This window has closed';
        } else if (nextRatio != null) {
          final dropIn = Duration(
              seconds: ((remH - nextRatio * totalH) * 3600).round());
          final nextPrice = double.parse(
              (offer.marketPrice * nextFactor!).toStringAsFixed(2));
          dropLine =
              'Drops to ${formatMoney(nextPrice)}/kg in ${formatCountdown(dropIn)}';
        } else {
          dropLine = 'Final window — lowest price right now';
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: t.bg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: t.fg.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(band == FreshnessBand.rescue
                      ? Icons.bolt
                      : Icons.timelapse, size: 18, color: t.fg),
                  const SizedBox(width: 6),
                  Text(
                    expired
                        ? 'Freshness window closed'
                        : 'Usable for ${band.label} · live',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: t.fg,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                expired ? 'Expired' : formatCountdown(remaining),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: t.fg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.trending_down,
                      size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dropLine,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _freshnessCard() {
    return AppCard(
      color: AppColors.surfaceAlt,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best used within ${offer.timeRange}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  offer.band.meaning,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityCard() {
    return AppCard(
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quantity',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                '${formatKg(offer.availableKg)} available',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const Spacer(),
          _stepBtn(Icons.remove, () => _stepQty(-1),
              enabled: _qty > 1),
          SizedBox(
            width: 56,
            child: Text(
              formatKg(_qty),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          _stepBtn(Icons.add, () => _stepQty(1),
              enabled: _qty < offer.availableKg),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap, {required bool enabled}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primarySurface : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon,
            size: 20,
            color: enabled ? AppColors.primaryDark : AppColors.textMuted),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: highlight ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
