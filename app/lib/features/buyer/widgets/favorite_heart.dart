import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/app_colors.dart';
import '../application/favorites_providers.dart';

/// A tappable heart that saves/unsaves an offer. Self-contained (its own
/// Consumer) so it can drop onto any card without making the parent stateful.
class FavoriteHeart extends ConsumerWidget {
  const FavoriteHeart({super.key, required this.offerId, this.onSurface = true});

  final String offerId;

  /// When true the heart sits on a photo (white pill backdrop for contrast).
  final bool onSurface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(favoritesProvider).contains(offerId);
    final heart = HugeIcon(
      icon: HugeIcons.strokeRoundedFavourite,
      size: 18,
      color: saved ? AppColors.danger : AppColors.textSecondary,
    );
    return GestureDetector(
      onTap: () => ref.read(favoritesProvider.notifier).toggle(offerId),
      behavior: HitTestBehavior.opaque,
      child: onSurface
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: heart,
            )
          : Padding(padding: const EdgeInsets.all(4), child: heart),
    );
  }
}
