import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../data/http_impact_repository.dart';
import '../data/impact_repository.dart';
import '../domain/impact.dart';

final impactRepositoryProvider = Provider<ImpactRepository>((ref) {
  final config = ref.read(appConfigProvider);
  if (!config.useLiveApi) return InMemoryImpactRepository();
  return HttpImpactRepository(ref.read(apiClientProvider));
});

final impactProvider = FutureProvider<ImpactData>(
  (ref) => ref.read(impactRepositoryProvider).fetchImpact(),
);
