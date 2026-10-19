import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/date_only.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../gamification/domain/xp.dart';
import '../../plan/domain/enums.dart';
import '../domain/today_builder.dart';
import 'today_providers.dart';

/// Done: one tap. The outbox write happens first, then a toast previews XP.
Future<void> markDone(
  BuildContext context,
  WidgetRef ref,
  TodayItem item,
) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(todayModelProvider.notifier);
  final award = notifier.previewDone(item);
  try {
    await notifier.act(item, TaskAction.done);
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.todayActionError)));
    return;
  }
  final text = switch (award.outcome) {
    XpOutcome.late => l.todayXpToastLate,
    XpOutcome.capReached => l.todayXpToastCap,
    _ => l.todayXpToast(award.amount),
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: const Key('xp-toast'),
        content: Text(text),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// Skip with an optional reason.
Future<void> skipWithSheet(
  BuildContext context,
  WidgetRef ref,
  TodayItem item,
) async {
  final picked = await showModalBottomSheet<_SkipChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _SkipSheet(),
  );
  if (picked == null) return;
  await ref
      .read(todayModelProvider.notifier)
      .act(item, TaskAction.skip, skipReason: picked.reason);
}

/// Snooze to tomorrow / in 2 days / next week.
Future<void> snoozeWithSheet(
  BuildContext context,
  WidgetRef ref,
  TodayItem item,
) async {
  final today = ref.read(todayModelProvider).today;
  final until = await showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _SnoozeSheet(today: today),
  );
  if (until == null) return;
  await ref
      .read(todayModelProvider.notifier)
      .act(item, TaskAction.snooze, snoozeUntil: until);
}

class _SkipChoice {
  const _SkipChoice(this.reason);
  final String? reason;
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SkipSheet extends StatefulWidget {
  const _SkipSheet();

  @override
  State<_SkipSheet> createState() => _SkipSheetState();
}

class _SkipSheetState extends State<_SkipSheet> {
  String? _reason;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reasons = [
      l.taskSkipReasonRain,
      l.taskSkipReasonAway,
      l.taskSkipReasonNotNeeded,
      l.taskSkipReasonOther,
    ];
    return _SheetFrame(
      title: l.taskSkipTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.taskSkipReasonHint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final r in reasons)
                TagChip(
                  label: r,
                  selected: _reason == r,
                  onTap: () => setState(() => _reason = _reason == r ? null : r),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GlowButton(
            key: const Key('skip-confirm'),
            label: l.taskSkipConfirm,
            onPressed: () => Navigator.of(context).pop(_SkipChoice(_reason)),
          ),
        ],
      ),
    );
  }
}

class _SnoozeSheet extends StatelessWidget {
  const _SnoozeSheet({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final options = <(String, int)>[
      (l.taskSnoozeTomorrow, 1),
      (l.taskSnooze2Days, 2),
      (l.taskSnoozeNextWeek, 7),
    ];
    return _SheetFrame(
      title: l.taskSnoozeTitle,
      child: Column(
        children: [
          for (final o in options)
            ListTile(
              key: Key('snooze-${o.$2}'),
              contentPadding: EdgeInsets.zero,
              title: Text(o.$1),
              trailing: Text(
                _fmt(addDays(today, o.$2)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () => Navigator.of(context).pop(addDays(today, o.$2)),
            ),
        ],
      ),
    );
  }
}

String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// dd/MM label shared by Today and detail.
String shortDate(DateTime d) => _fmt(d);
