import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/date_only.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../plan/presentation/plan_labels.dart';
import '../../plants/domain/plant.dart';
import '../../plants/presentation/plant_providers.dart';
import '../../plan/presentation/plan_providers.dart';
import '../domain/project.dart';
import 'projects_providers.dart';

/// Screen 08 (PRJ-02/03): project name, start date, pots, start stage, space,
/// sun, pot/soil, watering, optional cover. Receives the chosen catalogue
/// plant id (`plant`) or a free-text plant name (`name`).
class ProjectContextScreen extends ConsumerStatefulWidget {
  const ProjectContextScreen({super.key, this.plantId, this.freeText});

  final String? plantId;
  final String? freeText;

  @override
  ConsumerState<ProjectContextScreen> createState() =>
      _ProjectContextScreenState();
}

class _ProjectContextScreenState extends ConsumerState<ProjectContextScreen> {
  final _name = TextEditingController();
  late final TextEditingController _pot;
  bool _nameEdited = false;
  late DateTime _start;
  int _pots = 1;
  StartStage _stage = StartStage.seed;
  Space _space = Space.balcony;
  SunLevel _sun = SunLevel.medium;
  Watering _watering = Watering.manual;
  Uint8List? _cover;
  bool _nameMissing = false;
  bool _error = false;
  bool _init = false;

  @override
  void initState() {
    super.initState();
    _start = dateOnly(ref.read(projectsTodayProvider));
    _pot = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _pot.dispose();
    super.dispose();
  }

  Plant? _plant() {
    final id = widget.plantId;
    if (id == null) return null;
    final all = ref.read(plantsProvider).value ?? const <Plant>[];
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  String _plantLabel(String lang) {
    final p = _plant();
    if (p != null) {
      return (lang == 'en' && (p.nameEn?.isNotEmpty ?? false))
          ? p.nameEn!
          : p.nameVi;
    }
    return widget.freeText ?? '';
  }

  void _syncDefaultName(AppLocalizations l10n, String lang) {
    if (_nameEdited) return;
    final label = _plantLabel(lang);
    final text = label.isEmpty
        ? ''
        : l10n.projectsDefaultName(label, _start.month, _start.year);
    if (_name.text != text) _name.text = text;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(_start.year - 1),
      lastDate: DateTime(_start.year + 2),
    );
    if (picked != null) {
      setState(() => _start = dateOnly(picked));
    }
  }

  Future<void> _pickCover() async {
    try {
      final f = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (mounted) setState(() => _cover = bytes);
    } catch (_) {
      // Cover is optional; ignore picker failures.
    }
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameMissing = true);
      return;
    }
    setState(() {
      _nameMissing = false;
      _error = false;
    });
    String? coverPath;
    if (_cover != null) {
      try {
        coverPath = await ref
            .read(projectRepositoryProvider)
            .uploadCover(_cover!);
      } catch (_) {
        coverPath = null; // optional; continue without it
      }
    }
    final plant = _plant();
    final project = await ref
        .read(createProjectProvider.notifier)
        .submit(
          NewProject(
            plantId: plant?.id ?? widget.plantId,
            plantName: plant == null ? widget.freeText : null,
            name: name,
            startDate: _start,
            startStage: _stage,
            potCount: _pots,
            space: _space,
            sunLevel: _sun,
            potType: _pot.text.trim().isEmpty ? null : _pot.text.trim(),
            watering: _watering,
            coverPath: coverPath,
          ),
        );
    if (!mounted) return;
    if (project == null) {
      setState(() => _error = true);
      return;
    }
    context.go('/projects/${project.id}/generating');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    ref.watch(plantsProvider); // rebuild when the catalogue arrives
    if (!_init) {
      _init = true;
      _pot.text = l10n.projectsPotDefault;
    }
    _syncDefaultName(l10n, lang);
    final creating = ref.watch(createProjectProvider).isLoading;
    final plantLabel = _plantLabel(lang);

    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Text(s, style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
    );

    Widget options<T>(
      List<T> values,
      T selected,
      String Function(T) text,
      void Function(T) set,
      String keyPrefix,
      String Function(T) keyOf,
    ) => Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final v in values)
          TagChip(
            key: Key('$keyPrefix-${keyOf(v)}'),
            label: text(v),
            selected: v == selected,
            onTap: () => setState(() => set(v)),
          ),
      ],
    );

    return GlassScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('context-back'),
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => context.pop(),
              ),
              Text(
                l10n.projectsContextEyebrow,
                style: t.labelLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                Text(
                  plantLabel.isEmpty
                      ? l10n.projectsContextTitleNoPlant
                      : l10n.projectsContextTitle(plantLabel),
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                label(l10n.projectsFieldName),
                GlassTextField(
                  key: const Key('project-name'),
                  controller: _name,
                  semanticLabel: l10n.projectsFieldName,
                  errorText: _nameMissing ? l10n.projectsNameRequired : null,
                  onChanged: (_) => _nameEdited = true,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label(l10n.projectsFieldStartDate),
                          GlassCard(
                            key: const Key('start-date'),
                            radius: AppRadius.chip,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            onTap: _pickDate,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.event_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  '${shortDate(_start)}/${_start.year}',
                                  style: t.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label(l10n.projectsFieldPots),
                        Row(
                          children: [
                            IconButton(
                              key: const Key('pots-minus'),
                              tooltip: l10n.projectsPotsMinus,
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: _pots > 1
                                  ? () => setState(() => _pots--)
                                  : null,
                            ),
                            Text(
                              '$_pots',
                              key: const Key('pots-value'),
                              style: t.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              key: const Key('pots-plus'),
                              tooltip: l10n.projectsPotsPlus,
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: _pots < 99
                                  ? () => setState(() => _pots++)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                label(l10n.projectsFieldStartStage),
                options<StartStage>(
                  StartStage.values,
                  _stage,
                  (v) => switch (v) {
                    StartStage.seed => l10n.projectsStartSeed,
                    StartStage.seedling => l10n.projectsStartSeedling,
                    StartStage.mature => l10n.projectsStartMature,
                  },
                  (v) => _stage = v,
                  'stage',
                  (v) => v.db,
                ),
                label(l10n.projectsFieldSpace),
                options<Space>(
                  Space.values,
                  _space,
                  (v) => switch (v) {
                    Space.indoor => l10n.projectsSpaceIndoor,
                    Space.balcony => l10n.projectsSpaceBalcony,
                    Space.yard => l10n.projectsSpaceYard,
                    Space.rooftop => l10n.projectsSpaceRooftop,
                  },
                  (v) => _space = v,
                  'space',
                  (v) => v.db,
                ),
                label(l10n.projectsFieldSun),
                options<SunLevel>(
                  SunLevel.values,
                  _sun,
                  (v) => switch (v) {
                    SunLevel.low => l10n.projectsSunLow,
                    SunLevel.medium => l10n.projectsSunMedium,
                    SunLevel.high => l10n.projectsSunHigh,
                  },
                  (v) => _sun = v,
                  'sun',
                  (v) => '${v.db}',
                ),
                label(l10n.projectsFieldPot),
                GlassTextField(
                  key: const Key('pot-type'),
                  controller: _pot,
                  semanticLabel: l10n.projectsFieldPot,
                ),
                label(l10n.projectsFieldWatering),
                options<Watering>(
                  Watering.values,
                  _watering,
                  (v) => switch (v) {
                    Watering.manual => l10n.projectsWateringManual,
                    Watering.auto => l10n.projectsWateringAuto,
                  },
                  (v) => _watering = v,
                  'watering',
                  (v) => v.db,
                ),
                const SizedBox(height: AppSpacing.lg),
                GlassCard(
                  key: const Key('cover-picker'),
                  radius: AppRadius.button,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  onTap: _pickCover,
                  child: Row(
                    children: [
                      Icon(
                        _cover == null
                            ? Icons.add_photo_alternate_outlined
                            : Icons.check_circle_rounded,
                        color: _cover == null
                            ? AppColors.textSecondary
                            : AppColors.green,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          _cover == null
                              ? l10n.projectsCoverAdd
                              : l10n.projectsCoverAdded,
                          style: t.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      l10n.projectsCreateError,
                      key: const Key('create-error'),
                      style: t.bodyMedium?.copyWith(color: AppColors.danger),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                GlowButton(
                  key: const Key('create-plan'),
                  label: l10n.projectsCreatePlan,
                  icon: Icons.auto_awesome_rounded,
                  onPressed: creating ? null : () => _submit(l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
