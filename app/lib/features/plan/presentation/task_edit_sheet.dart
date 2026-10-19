import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/plan_bundle.dart';
import 'plan_labels.dart';
import 'plan_providers.dart';

/// Opens the add / edit task sheet (PLN-05). Pass [task] to edit (frequency,
/// window, reminder, delete) or leave it null to add a manual task.
Future<void> showTaskEditor(
  BuildContext context, {
  required String projectId,
  required List<Stage> stages,
  Task? task,
  String? stageId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TaskEditorSheet(
      projectId: projectId,
      stages: stages,
      task: task,
      stageId: stageId,
    ),
  );
}

class _TaskEditorSheet extends ConsumerStatefulWidget {
  const _TaskEditorSheet({
    required this.projectId,
    required this.stages,
    this.task,
    this.stageId,
  });

  final String projectId;
  final List<Stage> stages;
  final Task? task;
  final String? stageId;

  @override
  ConsumerState<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends ConsumerState<_TaskEditorSheet> {
  String? _code;
  String? _stageId;
  late TaskWindow _window;
  late Frequency _frequency;
  late final TextEditingController _interval;
  String? _reminder;
  bool _busy = false;
  bool _error = false;

  bool get _editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _code = t?.taskCode;
    _stageId = t?.stageId ?? widget.stageId;
    if (_stageId == null && widget.stages.isNotEmpty && t == null) {
      _stageId = widget.stages.first.id;
    }
    _window = t?.window ?? TaskWindow.morning;
    _frequency = t?.frequency ?? Frequency.everyNDays;
    _interval = TextEditingController(text: '${t?.intervalDays ?? 2}');
    _reminder = t?.reminderTime;
  }

  @override
  void dispose() {
    _interval.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final parts = (_reminder ?? '07:00').split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 7,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      ),
    );
    if (picked != null) {
      setState(() {
        _reminder =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  int? get _intervalValue {
    final n = int.tryParse(_interval.text.trim());
    return (n == null || n < 1) ? null : n;
  }

  Future<void> _save() async {
    final code = _code;
    if (code == null) return;
    final needsN =
        _frequency == Frequency.everyNDays ||
        _frequency == Frequency.fixedDate;
    final n = needsN ? (_intervalValue ?? 1) : null;
    setState(() {
      _busy = true;
      _error = false;
    });
    try {
      final actions = ref.read(planActionsProvider);
      final t = widget.task;
      if (t == null) {
        await actions.addTask(
          NewTask(
            projectId: widget.projectId,
            stageId: _stageId,
            taskCode: code,
            window: _window,
            frequency: _frequency,
            intervalDays: n,
            reminderTime: _reminder,
          ),
        );
      } else {
        await actions.updateTask(
          Task(
            id: t.id,
            projectId: t.projectId,
            stageId: t.stageId,
            taskCode: t.taskCode,
            window: _window,
            frequency: _frequency,
            intervalDays: n,
            fixedDate: _frequency == Frequency.fixedDate ? t.fixedDate : null,
            reminderTime: _reminder,
            assigneeId: t.assigneeId,
            assignmentMode: t.assignmentMode,
            rotationOrder: t.rotationOrder,
            source: t.source,
            status: t.status,
            xp: t.xp,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _delete() async {
    final t = widget.task;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(planActionsProvider).deleteTask(t);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final renderer = watchRenderer(ref);
    final codes = ref.watch(taskCodesProvider).value ?? const <TaskCodeInfo>[];

    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Text(s, style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgTop,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _editing ? l10n.planTaskEditTitle : l10n.planTaskAddTitle,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                label(l10n.planTaskCode),
                if (_editing)
                  Text(
                    renderer.taskName(
                      _code!,
                      lang: Localizations.localeOf(context).languageCode,
                    ),
                    style: t.bodyLarge,
                  )
                else
                  DropdownButtonFormField<String>(
                    key: const Key('task-code-field'),
                    initialValue: _code,
                    isExpanded: true,
                    items: [
                      for (final c in codes)
                        DropdownMenuItem(
                          value: c.code,
                          child: Text(
                            renderer.taskName(
                              c.code,
                              lang: Localizations.localeOf(
                                context,
                              ).languageCode,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      final info = codes.where((c) => c.code == v).firstOrNull;
                      setState(() {
                        _code = v;
                        if (info != null) {
                          _window = info.defaultWindow;
                          _frequency = info.defaultFrequency;
                        }
                      });
                    },
                  ),
                if (!_editing && widget.stages.isNotEmpty) ...[
                  label(l10n.planTaskStage),
                  DropdownButtonFormField<String>(
                    key: const Key('task-stage-field'),
                    initialValue: _stageId,
                    isExpanded: true,
                    items: [
                      for (final s in widget.stages)
                        DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            s.name.isEmpty ? s.code : s.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _stageId = v),
                  ),
                ],
                label(l10n.planTaskWindow),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final w in TaskWindow.values)
                      TagChip(
                        key: Key('window-${w.db}'),
                        label: windowLabel(l10n, w),
                        selected: _window == w,
                        onTap: () => setState(() => _window = w),
                      ),
                  ],
                ),
                label(l10n.planTaskFrequency),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    TagChip(
                      key: const Key('freq-once'),
                      label: l10n.planFreqOnce,
                      selected: _frequency == Frequency.once,
                      onTap: () => setState(() => _frequency = Frequency.once),
                    ),
                    TagChip(
                      key: const Key('freq-daily'),
                      label: l10n.planFreqDaily,
                      selected: _frequency == Frequency.daily,
                      onTap: () => setState(() => _frequency = Frequency.daily),
                    ),
                    TagChip(
                      key: const Key('freq-every'),
                      label: l10n.planFreqEveryN(
                        _intervalValue ?? (widget.task?.intervalDays ?? 2),
                      ),
                      selected: _frequency == Frequency.everyNDays,
                      onTap: () =>
                          setState(() => _frequency = Frequency.everyNDays),
                    ),
                    TagChip(
                      key: const Key('freq-fixed'),
                      label: l10n.planTaskFixedDay,
                      selected: _frequency == Frequency.fixedDate,
                      onTap: () =>
                          setState(() => _frequency = Frequency.fixedDate),
                    ),
                  ],
                ),
                if (_frequency == Frequency.everyNDays ||
                    _frequency == Frequency.fixedDate) ...[
                  label(
                    _frequency == Frequency.everyNDays
                        ? l10n.planTaskInterval
                        : l10n.planTaskFixedDay,
                  ),
                  GlassTextField(
                    key: const Key('interval-field'),
                    controller: _interval,
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                label(l10n.planTaskReminder),
                Row(
                  children: [
                    TagChip(
                      key: const Key('reminder-chip'),
                      label: _reminder ?? l10n.planTaskNoReminder,
                      icon: Icons.alarm_rounded,
                      selected: _reminder != null,
                      onTap: _pickTime,
                    ),
                    if (_reminder != null)
                      IconButton(
                        key: const Key('reminder-clear'),
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _reminder = null),
                      ),
                  ],
                ),
                if (_error) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.planTaskSaveError,
                    style: t.bodyMedium?.copyWith(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                GlowButton(
                  key: const Key('task-save'),
                  label: l10n.commonSave,
                  onPressed: (_busy || _code == null) ? null : _save,
                ),
                if (_editing) ...[
                  const SizedBox(height: AppSpacing.sm),
                  GlowButton(
                    key: const Key('task-delete'),
                    label: l10n.planTaskDelete,
                    variant: GlowButtonVariant.secondary,
                    icon: Icons.delete_outline_rounded,
                    onPressed: _busy ? null : _delete,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
