import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/failed_payment.dart';

/// In-session record of checkout attempts whose payment failed. Newest first.
/// Cleared on sign-out with the rest of the session state is out of scope for
/// the pilot — these live only as long as the app is open.
class FailedPaymentsController extends Notifier<List<FailedPayment>> {
  @override
  List<FailedPayment> build() => const [];

  void add(FailedPayment payment) => state = [payment, ...state];

  void remove(String id) =>
      state = state.where((p) => p.id != id).toList();

  void clear() => state = const [];
}

final failedPaymentsProvider =
    NotifierProvider<FailedPaymentsController, List<FailedPayment>>(
        FailedPaymentsController.new);
