import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../data/http_insights_repository.dart';
import '../data/insights_repository.dart';
import '../domain/seller_insights.dart';

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  final config = ref.read(appConfigProvider);
  if (!config.useLiveApi) return InMemoryInsightsRepository();
  return HttpInsightsRepository(ref.read(apiClientProvider));
});

final sellerInsightsProvider = FutureProvider<SellerInsightsData>((ref) {
  return ref.read(insightsRepositoryProvider).fetch();
});
