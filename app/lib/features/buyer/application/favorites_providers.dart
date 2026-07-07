import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Saved offers, by listing id. In-memory for the pilot (no backend favourites
/// endpoint yet); persist to shared_preferences when that ships.
class FavoritesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String offerId) {
    final next = {...state};
    if (!next.remove(offerId)) next.add(offerId);
    state = next;
  }

  bool isFavorite(String offerId) => state.contains(offerId);
}

final favoritesProvider =
    NotifierProvider<FavoritesController, Set<String>>(FavoritesController.new);
