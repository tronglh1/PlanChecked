import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env.dart';
import '../../plan/presentation/plan_providers.dart';
import '../data/project_repository.dart';
import '../domain/project.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  if (!Env.isConfigured) throw StateError('Supabase is not configured');
  return SupabaseProjectRepository();
});

/// Project list (screen 06). Invalidate after create / approve.
final projectListProvider = FutureProvider.autoDispose<List<ProjectSummary>>((
  ref,
) {
  final today = ref.watch(projectsTodayProvider);
  return ref.watch(projectRepositoryProvider).listProjects(today);
});

final projectDetailProvider = FutureProvider.autoDispose
    .family<ProjectDetail, String>(
      (ref, id) => ref.watch(projectRepositoryProvider).getProject(id),
    );

final taskHistoryProvider = FutureProvider.autoDispose
    .family<List<TaskHistoryEntry>, String>(
      (ref, id) => ref.watch(projectRepositoryProvider).taskHistory(id),
    );

/// Creates projects (screen 08 submit).
class CreateProjectController extends Notifier<AsyncValue<Project?>> {
  @override
  AsyncValue<Project?> build() => const AsyncData(null);

  Future<Project?> submit(NewProject input) async {
    state = const AsyncLoading();
    try {
      final p = await ref.read(projectRepositoryProvider).createProject(input);
      state = AsyncData(p);
      ref.invalidate(projectListProvider);
      return p;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final createProjectProvider =
    NotifierProvider<CreateProjectController, AsyncValue<Project?>>(
      CreateProjectController.new,
    );
