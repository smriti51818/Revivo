import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Meals a cook logged as served for each delivered rescue — the "Meals Served"
/// step that closes the Sell → Rescue → Transform loop (spec's three-tap cook
/// workflow). In-memory for the pilot; a real build uploads a meal photo to S3.
class MealLogController extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};

  void log(String rescueId, int meals) {
    if (meals <= 0) return;
    state = {...state, rescueId: meals};
  }

  int? served(String rescueId) => state[rescueId];

  int get totalMeals => state.values.fold(0, (s, m) => s + m);
}

final mealLogProvider =
    NotifierProvider<MealLogController, Map<String, int>>(
        MealLogController.new);
