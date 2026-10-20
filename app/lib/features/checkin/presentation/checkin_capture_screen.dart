import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../plan/presentation/plan_labels.dart';
import '../../projects/presentation/projects_providers.dart';
import '../domain/checkin_models.dart';
import 'checkin_labels.dart';
import 'checkin_providers.dart';

/// Screen 13 "Check-in: chụp ảnh" (CHK-01, CHK-02, CHK-03). Dark screen with
/// guided shot types, quick condition tags, a short note and the analyzing /
/// quota / error states.
class CheckinCaptureScreen extends ConsumerStatefulWidget {
  const CheckinCaptureScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<CheckinCaptureScreen> createState() =>
      _CheckinCaptureScreenState();
}

class _CheckinCaptureScreenState extends ConsumerState<CheckinCaptureScreen> {
  final _note = TextEditingController();

  String get _base => '/projects/${widget.projectId}';

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  CaptureController get _ctrl =>
      ref.read(captureControllerProvider(widget.projectId).notifier);

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_base);
    }
  }

  Future<void> _pick({required bool gallery}) async {
    final source = ref.read(checkinImageSourceProvider);
    final Uint8List? raw;
    try {
      raw = gallery ? await source.pickFromGallery() : await source.takePhoto();
    } catch (e) {
      // Without this the tap did nothing visible when the camera/picker failed.
      if (!mounted) return;
      final detail = e is PlatformException
          ? (e.message ?? e.code)
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).checkinPickError(
              detail.length > 160 ? '${detail.substring(0, 160)}…' : detail,
            ),
          ),
        ),
      );
      return;
    }
    if (raw == null || !mounted) return;
    final retake = await _ctrl.addPhoto(raw);
    if (!mounted) return;
    if (retake != null) {
      context.push('$_base/checkin/retake', extra: retake);
    }
  }

  Future<void> _submit() async {
    final result = await _ctrl.submit();
    if (!mounted) return;
    switch (result) {
      case SubmitDone(:final checkinId):
        context.pushReplacement('$_base/checkin/$checkinId');
      case SubmitRetake(:final info):
        context.push('$_base/checkin/retake', extra: info);
      case SubmitStopped():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(captureControllerProvider(widget.projectId));
    final detail = ref.watch(projectDetailProvider(widget.projectId)).value;
    final lang = Localizations.localeOf(context).languageCode;
    final plant = detail?.plantName(lang) ?? '';
    final t = Theme.of(context).textTheme;
    final index = ShotType.values.indexOf(state.active) + 1;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: t.apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      child: Scaffold(
        backgroundColor: AppColors.cameraDark,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('checkin-close'),
                      tooltip: l10n.checkinClose,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _close,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.checkinTitle(plant),
                            style: t.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            l10n.checkinShotProgress(
                              index,
                              ShotType.values.length,
                              shotLabel(l10n, state.active),
                            ),
                            style: t.bodySmall?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('checkin-tips'),
                      tooltip: l10n.checkinTips,
                      icon: const Icon(
                        Icons.help_outline_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => context.push('$_base/checkin/retake'),
                    ),
                  ],
                ),
              ),
              Expanded(child: _body(l10n, state, lang)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, CaptureState state, String lang) {
    switch (state.phase) {
      case CapturePhase.analyzing:
        return _Analyzing(step: state.step);
      case CapturePhase.quotaExceeded:
        return _StopPanel(
          key: const Key('checkin-quota'),
          icon: Icons.hourglass_bottom_rounded,
          title: l10n.checkinQuotaTitle,
          body: state.quotaUsed != null && state.quotaCap != null
              ? l10n.checkinQuotaBody(state.quotaUsed!, state.quotaCap!)
              : l10n.checkinQuotaBodyPlain,
          primaryLabel: l10n.checkinClose,
          onPrimary: _close,
        );
      case CapturePhase.aiUnavailable:
        return _StopPanel(
          key: const Key('checkin-ai-down'),
          icon: Icons.cloud_off_rounded,
          title: l10n.checkinAiDownTitle,
          body: l10n.checkinAiDownBody,
          primaryLabel: l10n.commonRetry,
          onPrimary: _submit,
          secondaryLabel: l10n.checkinClose,
          onSecondary: _close,
        );
      case CapturePhase.failed:
        return _StopPanel(
          key: const Key('checkin-failed'),
          icon: Icons.wifi_off_rounded,
          title: l10n.checkinFailedTitle,
          body: l10n.checkinFailedBody,
          primaryLabel: l10n.commonRetry,
          onPrimary: _submit,
          secondaryLabel: l10n.checkinBackToCapture,
          onSecondary: _ctrl.dismissStop,
        );
      case CapturePhase.skippedRecent:
        final prev = state.previousCheckinId;
        return _StopPanel(
          key: const Key('checkin-skipped'),
          icon: Icons.event_available_rounded,
          title: l10n.checkinSkippedTitle,
          body: l10n.checkinSkippedBody,
          primaryLabel: prev == null
              ? l10n.checkinClose
              : l10n.checkinSkippedView,
          onPrimary: prev == null
              ? _close
              : () => context.pushReplacement('$_base/checkin/$prev'),
          secondaryLabel: l10n.checkinBackToCapture,
          onSecondary: _ctrl.dismissStop,
        );
      case CapturePhase.capturing:
      case CapturePhase.processing:
        return _capturing(l10n, state, lang);
    }
  }

  Widget _capturing(AppLocalizations l10n, CaptureState state, String lang) {
    final t = Theme.of(context).textTheme;
    final renderer = watchRenderer(ref);
    final busy = state.phase == CapturePhase.processing;
    final shot = state.shots[state.active];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          key: const Key('viewfinder'),
          height: 340,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: Colors.white24),
          ),
          child: busy
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.checkinProcessing,
                        style: t.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                )
              : shot != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(shot.jpeg, fit: BoxFit.cover),
                    Positioned(
                      right: AppSpacing.sm,
                      top: AppSpacing.sm,
                      child: IconButton.filled(
                        key: const Key('remove-shot'),
                        tooltip: l10n.checkinRetakeShot,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => _ctrl.removeShot(state.active),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Container(
                    width: 190,
                    height: 250,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(120),
                      border: Border.all(color: Colors.white54, width: 1.5),
                    ),
                    child: Text(
                      l10n.checkinFrameHint,
                      textAlign: TextAlign.center,
                      style: t.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (i, s) in ShotType.values.indexed) ...[
                _ShotPill(
                  key: Key('shot-${s.code}'),
                  label: '${i + 1} · ${shotLabel(l10n, s)}',
                  selected: state.active == s,
                  done: state.shots.containsKey(s),
                  onTap: () => _ctrl.selectShot(s),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.checkinQuickTags,
          style: t.labelLarge?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final tag in kConditionTags)
              TagChip(
                key: Key('tag-$tag'),
                label: tagLabel(l10n, renderer, tag, lang),
                selected: state.tags.contains(tag),
                onTap: () => _ctrl.toggleTag(tag),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GlassTextField(
          controller: _note,
          hint: l10n.checkinNoteHint,
          maxLength: kCheckinNoteMax,
          onChanged: _ctrl.setNote,
          semanticLabel: l10n.checkinNoteHint,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              key: const Key('pick-gallery'),
              tooltip: l10n.checkinGallery,
              iconSize: 30,
              icon: const Icon(
                Icons.photo_library_outlined,
                color: Colors.white,
              ),
              onPressed: busy ? null : () => _pick(gallery: true),
            ),
            Semantics(
              button: true,
              label: l10n.checkinTakePhoto,
              child: GestureDetector(
                key: const Key('shutter'),
                onTap: busy ? null : () => _pick(gallery: false),
                child: Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Text(
              l10n.checkinShotsTaken(state.shots.length, kMaxShots),
              style: t.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        GlowButton(
          key: const Key('analyze'),
          label: l10n.checkinAnalyze,
          icon: Icons.auto_awesome_rounded,
          onPressed: state.canSubmit && !busy ? _submit : null,
        ),
      ],
    );
  }
}

class _ShotPill extends StatelessWidget {
  const _ShotPill({
    super.key,
    required this.label,
    required this.selected,
    required this.done,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.white12,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (done) ...[
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: selected ? AppColors.green : Colors.white70,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? AppColors.text : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Analyzing state (AI-08, target <= 15 s): progress bar that fills over
/// about 15 s and two steps.
class _Analyzing extends StatelessWidget {
  const _Analyzing({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    Widget row(int i, String text) {
      final done = step > i;
      final active = step == i;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : active
                  ? Icons.autorenew_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: done ? AppColors.orangeLight : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              text,
              style: t.bodyMedium?.copyWith(
                color: active || done ? Colors.white : Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      key: const Key('checkin-analyzing'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.orangeLight,
              size: 44,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.checkinAnalyzingTitle,
              style: t.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.checkinAnalyzingSub,
              style: t.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.lg),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 0.92),
              duration: const Duration(seconds: 15),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => AppProgressBar(value: v),
            ),
            const SizedBox(height: AppSpacing.lg),
            row(0, l10n.checkinStepUpload),
            row(1, l10n.checkinStepAnalyze),
          ],
        ),
      ),
    );
  }
}

class _StopPanel extends StatelessWidget {
  const _StopPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.orangeLight, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: t.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.xl),
            GlowButton(
              key: const Key('stop-primary'),
              label: primaryLabel,
              onPressed: onPrimary,
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                key: const Key('stop-secondary'),
                onPressed: onSecondary,
                child: Text(
                  secondaryLabel!,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
