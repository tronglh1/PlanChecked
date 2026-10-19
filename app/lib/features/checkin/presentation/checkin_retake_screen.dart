import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../plan/presentation/plan_labels.dart';
import 'checkin_labels.dart';
import 'checkin_providers.dart';

/// Screen 15 "Ảnh chưa đủ rõ" (CHK-06): shown when the photo is rejected on
/// the device before upload, or when `ai-checkin` answers `status: retake`.
/// Without [info] (opened from the camera help button) it only lists tips.
class CheckinRetakeScreen extends ConsumerWidget {
  const CheckinRetakeScreen({super.key, required this.projectId, this.info});

  final String projectId;
  final RetakeInfo? info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    final renderer = watchRenderer(ref);
    final info = this.info;
    final hint = info == null
        ? null
        : retakeHintText(renderer, info.hintCode, lang);
    final tips = [
      l10n.checkinRetakeTip1,
      l10n.checkinRetakeTip2,
      l10n.checkinRetakeTip3,
    ];

    void back() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/projects/$projectId/checkin');
      }
    }

    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              key: const Key('retake-back'),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: back,
            ),
          ),
          Text(
            l10n.checkinRetakeTitle,
            style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          if (info != null) ...[
            Container(
              key: const Key('retake-preview'),
              height: 220,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.orangeTint,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: info.preview == null
                  ? const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: AppColors.orangeTintInk,
                      ),
                    )
                  : Image.memory(info.preview!, fit: BoxFit.cover),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              retakeReasonLabel(l10n, info.reason),
              key: const Key('retake-reason'),
              style: t.titleSmall?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                hint,
                key: const Key('retake-hint'),
                style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            l10n.checkinRetakeHeadline,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.checkinRetakeBody,
            style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.checkinRetakeTipsTitle,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final tip in tips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: AppColors.green,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(tip, style: t.bodyMedium)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GlowButton(
            key: const Key('retake-cta'),
            label: l10n.checkinRetakeCta,
            icon: Icons.photo_camera_rounded,
            onPressed: back,
          ),
        ],
      ),
    );
  }
}
