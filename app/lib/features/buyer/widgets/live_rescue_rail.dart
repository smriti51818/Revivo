import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/models/freshness.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/freshness_countdown.dart';
import '../../../core/widgets/produce_image.dart';
import '../domain/offer.dart';

/// A continuously scrolling "deals ending soon" rail for the hotel dashboard —
/// the Zomato live-carousel treatment applied to surplus whose freshness window
/// is closing. The list is rendered twice so the marquee loops seamlessly.
class LiveRescueRail extends StatefulWidget {
  const LiveRescueRail({super.key, required this.offers, required this.onTap});

  final List<Offer> offers;
  final void Function(Offer) onTap;

  @override
  State<LiveRescueRail> createState() => _LiveRescueRailState();
}

class _LiveRescueRailState extends State<LiveRescueRail> {
  static const double _cardW = 184;
  static const double _gap = AppSpacing.md;

  final _ctrl = ScrollController();
  Timer? _timer;

  double get _copyWidth => widget.offers.length * (_cardW + _gap);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_ctrl.hasClients) return;
      if (_ctrl.position.maxScrollExtent <= 0) return;
      var next = _ctrl.offset + 0.4;
      if (next >= _copyWidth) next -= _copyWidth;
      _ctrl.jumpTo(next.clamp(0, _ctrl.position.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Duplicate the list for the seamless loop.
    final loop = [...widget.offers, ...widget.offers];
    return SizedBox(
      height: 168,
      child: ListView.separated(
        controller: _ctrl,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        itemCount: loop.length,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (context, i) => _RailCard(
          offer: loop[i],
          width: _cardW,
          onTap: () => widget.onTap(loop[i]),
        ),
      ),
    );
  }
}

class _RailCard extends StatelessWidget {
  const _RailCard({
    required this.offer,
    required this.width,
    required this.onTap,
  });

  final Offer offer;
  final double width;
  final VoidCallback onTap;

  Color get _tint => switch (offer.liveBand()) {
        FreshnessBand.good => AppColors.successSurface,
        FreshnessBand.useSoon => AppColors.warningSurface,
        FreshnessBand.rescue => AppColors.dangerSurface,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg)),
                  child: SizedBox(
                    height: 84,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ProduceImage(
                              imageUrl: offer.imageUrl, tint: _tint),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: offer.hasClock
                              ? FreshnessCountdownPill(
                                  expiresAt: offer.expiresAt!,
                                  totalHours: offer.totalHours!,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.vegetable,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        offer.vendorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10.5, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      FreshnessTicker(
                        expiresAt: offer.expiresAt ??
                            DateTime.now().add(const Duration(hours: 12)),
                        totalHours: offer.totalHours ?? 24,
                        builder: (context, _, _) => Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${formatMoney(offer.livePrice())}/kg',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (offer.liveSavingsPct() > 0)
                              Text(
                                formatMoney(offer.marketPrice),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
