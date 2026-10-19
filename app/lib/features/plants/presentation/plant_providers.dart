import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env.dart';
import '../data/plant_repository.dart';
import '../domain/plant.dart';

final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  if (!Env.isConfigured) throw StateError('Supabase is not configured');
  return SupabasePlantRepository();
});

/// The whole plant catalogue; search runs on-device (pure Dart).
final plantsProvider = FutureProvider<List<Plant>>(
  (ref) => ref.watch(plantRepositoryProvider).fetchPlants(),
);
