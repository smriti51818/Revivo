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

/// Period-keyed insights: 'week' | 'month' | 'year'. Switching the filter
/// refetches from AWS so every number (revenue, chart, impact, AI recs) is
/// computed on the backend for that range.
final sellerInsightsProvider =
    FutureProvider.family<SellerInsightsData, String>((ref, period) {
  return ref.read(insightsRepositoryProvider).fetch(period: period);
});
