import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/impact_repository.dart';
import '../domain/impact.dart';

final impactRepositoryProvider = Provider<ImpactRepository>(
  (ref) => InMemoryImpactRepository(),
);

final impactProvider = FutureProvider<ImpactData>(
  (ref) => ref.read(impactRepositoryProvider).fetchImpact(),
);
