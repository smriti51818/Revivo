import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/band_chip.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_chip.dart';
import 'application/order_requests_providers.dart';
import 'domain/order_request.dart';

class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(orderRequestsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(orderRequestsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              const Text(
                'Order requests',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Approve buyers before their freshness window closes',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              requests.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(child: Text('Could not load requests: $e')),
                ),
                data: (items) => _content(context, ref, items),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(
      BuildContext context, WidgetRef ref, List<OrderRequest> items) {
    final pending =
        items.where((r) => r.status == RequestStatus.pending).toList();
    final resolved =
        items.where((r) => r.status != RequestStatus.pending).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Pending (${pending.length})'),
        const SizedBox(height: AppSpacing.md),
        if (pending.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text('No pending requests right now.',
                style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          for (final r in pending) ...[
            _RequestCard(
              request: r,
              onAccept: () async {
                await ref.read(orderRequestsProvider.notifier).accept(r.id);
                if (context.mounted) _toast(context, 'Order accepted');
              },
              onDecline: () async {
                await ref.read(orderRequestsProvider.notifier).decline(r.id);
                if (context.mounted) _toast(context, 'Request declined');
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        if (resolved.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          const SectionHeader(title: 'History'),
          const SizedBox(height: AppSpacing.md),
          for (final r in resolved) ...[
            _RequestCard(request: r),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ],
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, this.onAccept, this.onDecline});

  final OrderRequest request;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onDecline;

  ChipTone get _tone => switch (request.status) {
        RequestStatus.pending => ChipTone.warning,
        RequestStatus.accepted => ChipTone.success,
        RequestStatus.declined => ChipTone.danger,
        RequestStatus.completed => ChipTone.neutral,
      };

  @override
  Widget build(BuildContext context) {
    final pending = request.status == RequestStatus.pending;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.buyerName,
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.buyerType,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              StatusChip(label: request.status.label, tone: _tone),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.vegetable,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    BandChip(band: request.band),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(request.total),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${formatKg(request.quantityKg)} · ${formatMoney(request.pricePerKg)}/kg',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          if (pending) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
