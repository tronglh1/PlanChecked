import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/plant.dart';
import '../domain/plant_search.dart';
import 'plant_providers.dart';

/// Screen 07 (PLT-01/02/03): search the plant catalogue.
class PlantSearchScreen extends ConsumerStatefulWidget {
  const PlantSearchScreen({super.key});

  @override
  ConsumerState<PlantSearchScreen> createState() => _PlantSearchScreenState();
}

class _PlantSearchScreenState extends ConsumerState<PlantSearchScreen> {
  final _controller = TextEditingController();
  PlantGroup? _group;
  String _query = '';
  String? _dismissedFor; // query for which "Không phải" was tapped

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openPlant(Plant p) => context.push(
    '${AppRoutes.projectContext}?plant=${Uri.encodeComponent(p.id)}',
  );

  void _openFreeText() => context.push(
    '${AppRoutes.projectContext}?name=${Uri.encodeComponent(_query.trim())}',
  );

  String _name(Plant p, String lang) =>
      (lang == 'en' && (p.nameEn?.isNotEmpty ?? false)) ? p.nameEn! : p.nameVi;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final t = Theme.of(context).textTheme;
    final plants = ref.watch(plantsProvider);
    final hasQuery = _query.trim().isNotEmpty;

    return GlassScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: Row(
              children: [
                IconButton(
                  key: const Key('search-close'),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.garden),
                ),
                Text(
                  l10n.searchEyebrow,
                  style: t.labelLarge?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              l10n.searchTitle,
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: GlassTextField(
              key: const Key('plant-search-field'),
              controller: _controller,
              hint: l10n.searchFieldLabel,
              semanticLabel: l10n.searchFieldLabel,
              prefixIcon: Icons.search_rounded,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                TagChip(
                  key: const Key('filter-all'),
                  label: l10n.filterAll,
                  selected: _group == null,
                  onTap: () => setState(() => _group = null),
                ),
                const SizedBox(width: AppSpacing.sm),
                TagChip(
                  key: const Key('filter-veg'),
                  label: l10n.filterVeg,
                  selected: _group == PlantGroup.rauQua,
                  onTap: () => setState(() => _group = PlantGroup.rauQua),
                ),
                const SizedBox(width: AppSpacing.sm),
                TagChip(
                  key: const Key('filter-ornamental'),
                  label: l10n.filterOrnamental,
                  selected: _group == PlantGroup.cayCanh,
                  onTap: () => setState(() => _group = PlantGroup.cayCanh),
                ),
              ],
            ),
          ),
          Expanded(
            child: plants.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => EmptyState(
                icon: Icons.cloud_off_rounded,
                title: l10n.searchLoadError,
                actionLabel: l10n.commonRetry,
                onAction: () => ref.invalidate(plantsProvider),
              ),
              data: (all) {
                final result = PlantSearch.search(all, _query, group: _group);
                final showSuggestions =
                    hasQuery &&
                    result.suggestions.isNotEmpty &&
                    _dismissedFor != _query;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  children: [
                    Text(
                      hasQuery
                          ? l10n.searchCount(
                              result.matches.length,
                              _query.trim(),
                            )
                          : l10n.searchCountAll(result.matches.length),
                      style: t.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final m in result.matches)
                      _PlantCard(
                        plant: m.plant,
                        name: _name(m.plant, lang),
                        l10n: l10n,
                        onTap: () => _openPlant(m.plant),
                      ),
                    if (hasQuery) ...[
                      const SizedBox(height: AppSpacing.md),
                      GlassCard(
                        key: const Key('fallback-card'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.searchNotFoundTitle,
                              style: t.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (showSuggestions) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l10n.searchDidYouMean(_query.trim()),
                                style: t.bodyMedium,
                              ),
                              for (final s in result.suggestions)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.sm,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _name(s.plant, lang),
                                          style: t.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        key: Key('suggest-yes-${s.plant.id}'),
                                        onPressed: () => _openPlant(s.plant),
                                        child: Text(l10n.searchYes),
                                      ),
                                    ],
                                  ),
                                ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  key: const Key('suggest-no'),
                                  onPressed: () =>
                                      setState(() => _dismissedFor = _query),
                                  child: Text(l10n.searchNo),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l10n.searchFreeTextHint,
                                style: t.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              GlowButton(
                                key: const Key('free-text-button'),
                                label: l10n.searchFreeText(_query.trim()),
                                onPressed: _openFreeText,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  const _PlantCard({
    required this.plant,
    required this.name,
    required this.l10n,
    required this.onTap,
  });

  final Plant plant;
  final String name;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  String? _difficulty() => switch (plant.difficulty) {
    'easy' => l10n.diffEasy,
    'medium' => l10n.diffMedium,
    'hard' => l10n.diffHard,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final diff = _difficulty();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        key: Key('plant-${plant.id}'),
        onTap: onTap,
        radius: 16,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.greenSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                plant.group == PlantGroup.cayCanh
                    ? Icons.local_florist_rounded
                    : Icons.eco_rounded,
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (plant.scientificName != null)
                    Text(
                      plant.scientificName!,
                      style: t.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (diff != null) _Pill(diff, tinted: true),
                      if (plant.daysToHarvest != null)
                        _Pill(l10n.harvestDays(plant.daysToHarvest!)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.tinted = false});
  final String text;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tinted ? AppColors.greenSoft : AppColors.cream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tinted ? AppColors.green : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
