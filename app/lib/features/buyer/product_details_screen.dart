import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/discovery/vendor_directory.dart';
import '../../core/format.dart';
import '../../core/models/freshness.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/band_chip.dart';
import '../../core/widgets/freshness_countdown.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/produce_image.dart';
import 'application/cart_providers.dart';
import 'domain/offer.dart';
import 'widgets/cart_bar.dart';
import 'widgets/favorite_heart.dart';
import 'widgets/quality_card.dart';
import 'widgets/trust_badges.dart';

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
    final topInset = MediaQuery.of(context).padding.top;
    final unitPrice = offer.livePrice();
    final total = _qty * unitPrice;
    final saved = _qty * offer.liveSavingsPerKg();

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _bottomBar(total, saved),
      body: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          _imageHero(topInset),
          // The content sheet rises over the bottom of the photo — the signature
          // grocery-app curve where the info panel overlaps the hero.
          Transform.translate(
            offset: const Offset(0, -AppRadius.xl),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.xl,
                AppSpacing.screen,
                140,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleAndBadges(),
                  const SizedBox(height: AppSpacing.lg),
                  FadeSlideIn(child: _priceBlock()),
                  const SizedBox(height: AppSpacing.md),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: offer.hasClock ? _clockHero() : _freshnessCard(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: _vendorRow(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 180),
                    child: QualityCard(vendorName: offer.vendorName),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Full-bleed product photo with a soft scrim, the floating back / save
  /// controls, and the live band/countdown pill — the immersive hero at the top
  /// of the page.
  Widget _imageHero(double topInset) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'offer-${offer.id}',
            child: ProduceImage(
              imageUrl: offer.imageUrl,
              tint: _tint,
              iconSize: 84,
            ),
          ),
          // Top scrim so the white controls stay legible on bright photos.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Color(0x33000000), Color(0x00000000)],
              ),
            ),
          ),
          Positioned(
            top: topInset + 8,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleButton(
                  HugeIcons.strokeRoundedArrowLeft01,
                  onTap: () => context.pop(),
                ),
                FavoriteHeart(offerId: offer.id),
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            bottom: AppSpacing.xl + AppRadius.xl,
            child: offer.hasClock
                ? FreshnessCountdownPill(
                    expiresAt: offer.expiresAt!,
                    totalHours: offer.totalHours!,
                    showBandLabel: true,
                  )
                : BandChip(band: offer.band, timeRange: offer.timeRange),
          ),
        ],
      ),
    );
  }

  /// A white circular control (back button) with a soft lift — matches the
  /// FavoriteHeart backdrop so the two corners feel like a set.
  Widget _circleButton(dynamic icon, {required VoidCallback onTap}) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppShadows.card,
        ),
        child: Center(
          child: HugeIcon(icon: icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _titleAndBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          offer.vegetable,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (offer.organic) _badge(HugeIcons.strokeRoundedLeaf02, 'Organic'),
            if (vendorInfo(offer.vendorName).trusted)
              _badge(HugeIcons.strokeRoundedCheckmarkBadge01, 'Trusted vendor'),
            _badge(HugeIcons.strokeRoundedPackage,
                '${formatKg(offer.availableKg)} available'),
          ],
        ),
      ],
    );
  }

  Widget _badge(dynamic icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 13, color: AppColors.primaryDark),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  /// Tappable vendor row — avatar, name, rating, distance — routes to the vendor
  /// page.
  Widget _vendorRow() {
    final info = vendorInfo(offer.vendorName);
    final initial =
        offer.vendorName.trim().isEmpty ? '?' : offer.vendorName.trim()[0];
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      onTap: () => context.push('/buyer/vendor', extra: offer.vendorName),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial.toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.vendorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    RatingPill(
                        rating: info.rating, reviews: info.reviews, dense: true),
                    if (offer.distanceKm > 0) ...[
                      const SizedBox(width: 10),
                      const HugeIcon(
                          icon: HugeIcons.strokeRoundedLocation01,
                          size: 13,
                          color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Text(
                        '${offer.distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              color: AppColors.textMuted),
        ],
      ),
    );
  }

  /// The price block: the live per-kg price (large), the struck market price it
  /// beats, and how far below market that is. All read straight off the live
  /// Offer methods — never a projected or hardcoded figure.
  Widget _priceBlock() {
    final unitPrice = offer.livePrice();
    final savingsPct = offer.liveSavingsPct();
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatMoney(unitPrice),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 3, bottom: 3),
                      child: Text('/ kg',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          )),
                    ),
                    if (savingsPct > 0) ...[
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          formatMoney(offer.marketPrice),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Market price shown struck through',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (savingsPct > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  Text(
                    '$savingsPct%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'below market',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// The ticking centerpiece: a live countdown to the end of the usable window
  /// and the current freshness band. It states the time left honestly and never
  /// projects a future price — the live price above is the single source of
  /// truth, and it only eases downward as the produce ages toward rescue.
  Widget _clockHero() {
    // A small accent color per band (icon + numbers only) — the card itself
    // stays neutral so the countdown doesn't read as an alarming red banner.
    Color accent(FreshnessBand band) => switch (band) {
          FreshnessBand.good => AppColors.success,
          FreshnessBand.useSoon => AppColors.warning,
          FreshnessBand.rescue => AppColors.danger,
        };

    return FreshnessTicker(
      expiresAt: offer.expiresAt!,
      totalHours: offer.totalHours!,
      builder: (context, remaining, band) {
        final fg = accent(band);
        final expired = remaining.inSeconds <= 0;

        // An honest, unambiguous note about how freshness relates to price —
        // fresher costs more; the price only eases as the window runs out.
        final String note = expired
            ? 'This freshness window has closed.'
            : switch (band) {
                FreshnessBand.good =>
                  'Freshest band — priced closest to market. The rate only eases as it ages.',
                FreshnessBand.useSoon =>
                  'Ripening fast — already priced below market while still good to use.',
                FreshnessBand.rescue =>
                  'Final window — lowest price, best for same-day cooking.',
              };

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HugeIcon(
                      icon: band == FreshnessBand.rescue
                          ? HugeIcons.strokeRoundedFlash
                          : HugeIcons.strokeRoundedClock01,
                      size: 18,
                      color: fg),
                  const SizedBox(width: 6),
                  Text(
                    expired
                        ? 'Freshness window closed'
                        : '${band.label} · time left in window',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
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
                  color: fg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                note,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
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
          const HugeIcon(
              icon: HugeIcons.strokeRoundedClock01,
              size: 20,
              color: AppColors.textSecondary),
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

  /// Sticky bottom action area: the persistent "view cart" pill (only when the
  /// cart has items) sitting above a compact quantity stepper + add-to-cart CTA
  /// — the Blinkit / Instamart pattern. The CartBar keeps its own logic; we only
  /// strip its bottom safe-area inset so our own bar owns the gesture zone.
  Widget _bottomBar(double total, double saved) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: const CartBar(),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (saved > 0)
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm, left: 2, right: 2),
                      child: Row(
                        children: [
                          const HugeIcon(
                              icon: HugeIcons.strokeRoundedTag01,
                              size: 14,
                              color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(
                            'You save ${formatMoney(saved)} vs market',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${formatKg(offer.availableKg)} in stock',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      _stepper(),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _addButton(total)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepper() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(HugeIcons.strokeRoundedMinusSign, () => _stepQty(-1),
              enabled: _qty > 1),
          SizedBox(
            width: 46,
            child: Text(
              formatKg(_qty),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          _stepBtn(HugeIcons.strokeRoundedPlusSign, () => _stepQty(1),
              enabled: _qty < offer.availableKg),
        ],
      ),
    );
  }

  Widget _stepBtn(dynamic icon, VoidCallback onTap, {required bool enabled}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: SizedBox(
        width: 42,
        height: 54,
        child: Center(
          child: HugeIcon(
              icon: icon,
              size: 20,
              color: enabled ? AppColors.primaryDark : AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _addButton(double total) {
    return Pressable(
      onTap: _addToCart,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const HugeIcon(
                icon: HugeIcons.strokeRoundedShoppingBag01,
                color: Colors.white,
                size: 20),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Add to cart',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              formatMoney(total),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
