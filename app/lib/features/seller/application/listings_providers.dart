import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../data/http_listings_repository.dart';
import '../data/listings_repository.dart';
import '../domain/listing.dart';

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  final config = ref.read(appConfigProvider);
  if (!config.useLiveApi) return InMemoryListingsRepository();
  return HttpListingsRepository(ref.read(apiClientProvider));
});

/// Holds the seller's listings. Async so the swap to a live API is seamless.
class ListingsController extends AsyncNotifier<List<Listing>> {
  @override
  Future<List<Listing>> build() {
    return ref.read(listingsRepositoryProvider).fetchListings();
  }

  Future<void> addListing(Listing draft) async {
    final created =
        await ref.read(listingsRepositoryProvider).createListing(draft);
    final current = state.valueOrNull ?? const <Listing>[];
    state = AsyncData([created, ...current]);
  }
}

final listingsProvider =
    AsyncNotifierProvider<ListingsController, List<Listing>>(
  ListingsController.new,
);
