import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Displays a produce photo from [imageUrl], falling back to a tinted eco
/// placeholder when there's no image, while loading, or if the load fails.
/// Meant to fill its parent (e.g. inside a `Positioned.fill`).
class ProduceImage extends StatelessWidget {
  const ProduceImage({
    super.key,
    required this.imageUrl,
    required this.tint,
    this.iconSize = 44,
  });

  final String? imageUrl;
  final Color tint;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return _placeholder();
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => _placeholder(),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(loading: true),
    );
  }

  Widget _placeholder({bool loading = false}) {
    return Container(
      color: tint,
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          : Icon(
              Icons.eco,
              size: iconSize,
              color: AppColors.primary.withValues(alpha: 0.55),
            ),
    );
  }
}
