import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env.dart';
import '../../../core/utils/date_only.dart';
import '../../plants/presentation/plant_providers.dart';
import '../../settings/presentation/locale_provider.dart';
import '../data/plan_repository.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/plan_bundle.dart';
import '../domain/template_renderer.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  if (!Env.isConfigured) throw StateError('Supabase is not configured');
  return SupabasePlanRepository();
});

/// Today as a date-only value. Overridden in tests.
final projectsTodayProvider = Provider<DateTime>(
  (ref) => dateOnly(DateTime.now()),
);

/// How long the generating screen waits for `ai-plan` before it falls back
/// (spec: target <= 20 s; a little slack for the network).
final aiPlanTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 25),
);

/// Interval at which the generating screen ticks its progress steps.
final aiPlanStepIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 2),
);

/// Task / milestone / safety text from `text_templates` for the app locale
/// (Vietnamese fills any gap).
final templateRendererProvider = FutureProvider<TemplateRenderer>((ref) async {
  final lang = ref.watch(localeProvider).languageCode;
  final repo = ref.watch(plantRepositoryProvider);
  final langs = {lang, 'vi'};
  final rows = <TextTemplate>[];
  for (final l in langs) {
    final fetched = await repo.fetchTextTemplates(l);
    rows.addAll(
      fetched.map(
        (t) => TextTemplate(
          kind: t.kind,
          code: t.code,
          lang: l,
          field: t.field,
          body: t.body,
        ),
      ),
    );
  }
  return TemplateRenderer(rows);
});

final planBundleProvider = FutureProvider.autoDispose
    .family<PlanBundle?, String>(
      (ref, projectId) => ref.watch(planRepositoryProvider).loadPlan(projectId),
    );

final taskCodesProvider = FutureProvider<List<TaskCodeInfo>>(
  (ref) => ref.watch(planRepositoryProvider).fetchTaskCodes(),
);

/// Plan mutations (PLN-05, approve). Each one refreshes the loaded plan.
class PlanActions {
  PlanActions(this._ref);
  final Ref _ref;

  PlanRepository get _repo => _ref.read(planRepositoryProvider);

  Future<void> approve(String projectId, String planId) async {
    await _repo.approvePlan(planId);
    _ref.invalidate(planBundleProvider(projectId));
  }

  Future<void> addTask(NewTask input) async {
    await _repo.addTask(input);
    _ref.invalidate(planBundleProvider(input.projectId));
  }

  Future<void> updateTask(Task task) async {
    await _repo.updateTask(task);
    _ref.invalidate(planBundleProvider(task.projectId));
  }

  Future<void> deleteTask(Task task) async {
    await _repo.deleteTask(task.id);
    _ref.invalidate(planBundleProvider(task.projectId));
  }
}

final planActionsProvider = Provider<PlanActions>(PlanActions.new);

// --- Generation (screen 09) -------------------------------------------------

enum GenerationPhase { running, done, failed }

class GenerationState {
  const GenerationState({
    this.phase = GenerationPhase.running,
    this.completedSteps = 0,
    this.planId,
    this.fallbackReason = FallbackReason.none,
    this.fallbackDetail,
  });

  final GenerationPhase phase;

  /// 0..4 of the four progress steps shown on screen.
  final int completedSteps;
  final String? planId;
  final FallbackReason fallbackReason;

  /// Why the AI failed, as reported by the server (may be null).
  final String? fallbackDetail;

  bool get usedFallback => fallbackReason != FallbackReason.none;

  GenerationState copyWith({
    GenerationPhase? phase,
    int? completedSteps,
    String? planId,
    FallbackReason? fallbackReason,
  }) => GenerationState(
    phase: phase ?? this.phase,
    completedSteps: completedSteps ?? this.completedSteps,
    planId: planId ?? this.planId,
    fallbackReason: fallbackReason ?? this.fallbackReason,
    fallbackDetail: fallbackDetail,
  );
}

/// Family argument of [generationControllerProvider].
class GenerationArgs {
  const GenerationArgs(this.projectId, [this.plantGroup]);
  final String projectId;

  /// Only for free-text plants (`rau_qua` | `cay_canh`).
  final String? plantGroup;

  @override
  bool operator ==(Object other) =>
      other is GenerationArgs &&
      other.projectId == projectId &&
      other.plantGroup == plantGroup;

  @override
  int get hashCode => Object.hash(projectId, plantGroup);
}

class GenerationController extends Notifier<GenerationState> {
  GenerationController(this.args);
  final GenerationArgs args;

  Timer? _ticker;
  bool _disposed = false;
  int _run = 0;

  @override
  GenerationState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _ticker?.cancel();
    });
    Future.microtask(_start);
    return const GenerationState();
  }

  void retry() => _start();

  Future<void> _start() async {
    if (_disposed) return;
    final run = ++_run;
    state = const GenerationState();
    _ticker?.cancel();
    _ticker = Timer.periodic(ref.read(aiPlanStepIntervalProvider), (_) {
      if (_disposed || run != _run) return;
      if (state.phase == GenerationPhase.running && state.completedSteps < 3) {
        state = state.copyWith(completedSteps: state.completedSteps + 1);
      }
    });

    final repo = ref.read(planRepositoryProvider);
    final timeout = ref.read(aiPlanTimeoutProvider);

    AiPlanResult? result;
    var reason = FallbackReason.none;
    try {
      result = await repo
          .generatePlan(args.projectId, plantGroup: args.plantGroup)
          .timeout(timeout);
    } catch (_) {
      reason = FallbackReason.aiFailure;
    }
    if (_disposed || run != _run) return;
    _ticker?.cancel();

    var planId = result?.planId;
    if (result != null) {
      if (result.fallbackReason != FallbackReason.none) {
        reason = result.fallbackReason;
      } else if (result.source == PlanSource.fallback) {
        reason = FallbackReason.aiFailure;
      }
    }
    if (planId == null) {
      // Timeout / error: the server may still have stored a draft plan.
      try {
        final existing = await repo.loadPlan(args.projectId);
        planId = existing?.plan.id;
        if (planId != null && reason == FallbackReason.none) {
          reason = FallbackReason.aiFailure;
        }
      } catch (_) {}
    }
    if (_disposed || run != _run) return;
    if (planId == null) {
      state = GenerationState(
        phase: GenerationPhase.failed,
        completedSteps: state.completedSteps,
        fallbackReason: reason == FallbackReason.none
            ? FallbackReason.aiFailure
            : reason,
      );
    } else {
      state = GenerationState(
        phase: GenerationPhase.done,
        completedSteps: 4,
        planId: planId,
        fallbackReason: reason,
        fallbackDetail: result?.fallbackDetail,
      );
    }
  }
}

final generationControllerProvider = NotifierProvider.autoDispose
    .family<GenerationController, GenerationState, GenerationArgs>(
      GenerationController.new,
    );
