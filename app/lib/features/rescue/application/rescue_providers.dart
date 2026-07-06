import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../data/http_rescue_repository.dart';
import '../data/rescue_repository.dart';
import '../domain/rescue.dart';

final rescueRepositoryProvider = Provider<RescueRepository>((ref) {
  final config = ref.read(appConfigProvider);
  if (!config.useLiveApi) return InMemoryRescueRepository();
  return HttpRescueRepository(ref.read(apiClientProvider));
});

/// The rescue board. The Cook/NGO inbox watches this and drives each item
/// through its lifecycle.
class RescuesController extends AsyncNotifier<List<Rescue>> {
  @override
  Future<List<Rescue>> build() {
    return ref.read(rescueRepositoryProvider).fetchRescues();
  }

  Future<void> _apply(String id,
      {required RescueStatus status, String? ngoName}) async {
    final updated = await ref
        .read(rescueRepositoryProvider)
        .updateStatus(id, status: status, ngoName: ngoName);
    final current = state.valueOrNull ?? const <Rescue>[];
    state = AsyncData([
      for (final r in current) r.id == id ? updated : r,
    ]);
  }

  /// Cook/NGO accepts an offered rescue.
  Future<void> accept(String id, {required String ngoName}) =>
      _apply(id, status: RescueStatus.accepted, ngoName: ngoName);

  /// Cook/NGO starts the pickup for an accepted rescue.
  Future<void> claimPickup(String id) =>
      _apply(id, status: RescueStatus.assigned);

  /// Cook/NGO marks produce collected from the vendor.
  Future<void> markPickedUp(String id) =>
      _apply(id, status: RescueStatus.pickedUp);

  /// Cook/NGO marks produce delivered to the kitchen.
  Future<void> markDelivered(String id) =>
      _apply(id, status: RescueStatus.delivered);

  /// AI "why rescue this?" explanation for a rescue (read-only; no state change).
  Future<String> explain(String id) =>
      ref.read(rescueRepositoryProvider).explain(id);
}

final rescuesProvider =
    AsyncNotifierProvider<RescuesController, List<Rescue>>(
  RescuesController.new,
);
