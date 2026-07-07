import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A compact "live" chip: an emoji that bobs up and down next to a wall-clock
/// that ticks every second. Reinforces Revivo's thesis that surplus is a
/// decaying asset — the clock is literally always running.
class LiveClockChip extends StatefulWidget {
  const LiveClockChip({
    super.key,
    this.emoji = '🥬',
    this.label = 'LIVE',
  });

  final String emoji;
  final String label;

  @override
  State<LiveClockChip> createState() => _LiveClockChipState();
}

class _LiveClockChipState extends State<LiveClockChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob;
  Timer? _tick;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _bob.dispose();
    _tick?.cancel();
    super.dispose();
  }

  String get _time {
    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final m = _now.minute.toString().padLeft(2, '0');
    final s = _now.second.toString().padLeft(2, '0');
    final ap = _now.hour < 12 ? 'AM' : 'PM';
    return '$h:$m:$s $ap';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _bob,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -3 * _bob.value),
              child: child,
            ),
            child: Text(widget.emoji, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 6),
          _blinkingDot(),
          const SizedBox(width: 5),
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _time,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blinkingDot() {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_bob),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.danger,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
