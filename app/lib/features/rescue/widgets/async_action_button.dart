import 'package:flutter/material.dart';

import '../../../core/widgets/primary_button.dart';

/// A [PrimaryButton] that manages its own loading state around an async action,
/// so screens can fire a repository mutation without local state plumbing.
class AsyncActionButton extends StatefulWidget {
  const AsyncActionButton({
    super.key,
    required this.label,
    required this.onRun,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final Future<void> Function() onRun;

  @override
  State<AsyncActionButton> createState() => _AsyncActionButtonState();
}

class _AsyncActionButtonState extends State<AsyncActionButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await widget.onRun();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: widget.label,
      icon: widget.icon,
      loading: _busy,
      onPressed: _run,
    );
  }
}
