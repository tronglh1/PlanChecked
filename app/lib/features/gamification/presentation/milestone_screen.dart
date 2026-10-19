import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/share_service.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/achievements_models.dart';
import 'gamification_providers.dart';

/// Screen 16 (GAM-01/03/04): `/projects/:id/milestone/:code`, dark `#14502F`.
/// Built-in confetti animation (plays once), medal, reward tiles, shareable
/// keepsake card rendered through a RepaintBoundary.
class MilestoneScreen extends ConsumerStatefulWidget {
  const MilestoneScreen({
    super.key,
    required this.projectId,
    required this.code,
  });
  final String projectId;
  final String code;

  @override
  ConsumerState<MilestoneScreen> createState() => _MilestoneScreenState();
}

class _MilestoneScreenState extends ConsumerState<MilestoneScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();
  final _keepsakeKey = GlobalKey();
  bool _sharing = false;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _share(MilestoneInfo info) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final share = ref.read(shareServiceProvider);
    final name = info.title ?? l10n.gamMilestoneUnknown;
    setState(() => _sharing = true);
    try {
      final boundary =
          _keepsakeKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('no boundary');
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('no bytes');
      await share.shareImage(
        data.buffer.asUint8List(),
        fileName: 'vuon-nha-${info.code.toLowerCase()}.png',
        text: l10n.gamShareText(info.projectName, name),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.gamShareError)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/projects/${widget.projectId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(
      milestoneProvider((projectId: widget.projectId, code: widget.code)),
    );
    return Scaffold(
      backgroundColor: AppColors.greenDeep,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, _) => CustomPaint(
                  key: const Key('confetti'),
                  painter: _ConfettiPainter(_anim.value),
                ),
              ),
            ),
          ),
          SafeArea(
            child: async.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (_, _) => _Fallback(
                message: l10n.gamLoadError,
                retry: l10n.commonRetry,
                onRetry: () => ref.invalidate(milestoneProvider),
                onClose: _close,
              ),
              data: (info) => info == null
                  ? _Fallback(
                      message: l10n.gamLoadError,
                      retry: l10n.commonRetry,
                      onRetry: () => ref.invalidate(milestoneProvider),
                      onClose: _close,
                    )
                  : _content(context, l10n, info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    MilestoneInfo i,
  ) {
    final t = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    final title = i.title ?? l10n.gamMilestoneUnknown;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  key: const Key('milestone-close'),
                  onPressed: _close,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
              Text(
                l10n.gamMilestoneEyebrow,
                style: t.labelLarge?.copyWith(
                  color: const Color(0xFF9FD3AE),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _anim,
                  curve: const Interval(0, 0.35, curve: Curves.elasticOut),
                ),
                child: const _Medal(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                key: const Key('milestone-title'),
                textAlign: TextAlign.center,
                style: t.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                i.photoConfirmed
                    ? l10n.gamMilestoneBody(i.projectName)
                    : l10n.gamMilestoneBodyPending(i.projectName),
                key: const Key('milestone-body'),
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: const Color(0xFFD2E6D8)),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _RewardTile(
                      key: const Key('reward-xp'),
                      value: i.photoConfirmed && i.xpAwarded > 0
                          ? l10n.gamRewardXp(i.xpAwarded)
                          : l10n.gamRewardPending,
                      label: l10n.gamRewardMilestone,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _RewardTile(
                      key: const Key('reward-badge'),
                      value: l10n.gamRewardBadge,
                      label: i.badge != null && i.badge!.earned
                          ? '“${i.badge!.name(lang)}”'
                          : l10n.gamRewardNoBadge,
                    ),
                  ),
                ],
              ),
              if (!i.photoConfirmed) ...[
                const SizedBox(height: AppSpacing.md),
                DecoratedBox(
                  key: const Key('milestone-pending-note'),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4D6),
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      l10n.gamPendingNote,
                      style: t.bodySmall?.copyWith(
                        color: const Color(0xFF6B4200),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.gamKeepsake,
                  style: t.labelLarge?.copyWith(color: const Color(0xFFB8C4BB)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RepaintBoundary(
                key: _keepsakeKey,
                child: KeepsakeCard(info: i, title: title, lang: lang),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('milestone-share'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orangeSolid,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  onPressed: _sharing ? null : () => _share(i),
                  icon: const Icon(Icons.share_rounded),
                  label: Text(l10n.gamShare),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: const Key('milestone-achievements'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF9FD3AE)),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  onPressed: () => context.go('/achievements'),
                  child: Text(l10n.gamViewAchievements),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.message,
    required this.retry,
    required this.onRetry,
    required this.onClose,
  });
  final String message;
  final String retry;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ),
        const Spacer(),
        Text(message, style: const TextStyle(color: Colors.white)),
        TextButton(onPressed: onRetry, child: Text(retry)),
        const Spacer(),
      ],
    );
  }
}

class _Medal extends StatelessWidget {
  const _Medal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.orangeSolid,
        boxShadow: [
          BoxShadow(
            color: AppColors.orangeSolid.withValues(alpha: 0.45),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 6,
        ),
      ),
      child: const Icon(
        Icons.emoji_events_rounded,
        size: 72,
        color: Colors.white,
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({super.key, required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.section),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: t.titleMedium?.copyWith(
              color: AppColors.orangeSolid,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: t.bodySmall?.copyWith(color: const Color(0xFFD2E6D8)),
          ),
        ],
      ),
    );
  }
}

/// The card that is captured to PNG and shared. Self-contained colors so the
/// image looks the same in light and dark contexts.
class KeepsakeCard extends StatelessWidget {
  const KeepsakeCard({
    super.key,
    required this.info,
    required this.title,
    required this.lang,
  });
  final MilestoneInfo info;
  final String title;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final date = info.reachedOn == null
        ? null
        : DateFormat('dd/MM/yyyy').format(info.reachedOn!);
    return Container(
      key: const Key('keepsake-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBF8EF), Color(0xFFEAF4EA)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            size: 44,
            color: AppColors.orangeMid,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: t.titleLarge?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            info.projectName,
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: AppColors.textTertiary),
          ),
          if (date != null)
            Text(
              date,
              style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          if (info.badge != null && info.badge!.earned) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '“${info.badge!.name(lang)}”',
              style: t.labelLarge?.copyWith(
                color: AppColors.orangeText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            '${l10n.appName} · ${l10n.gamKeepsakeCard}',
            style: t.labelSmall?.copyWith(color: AppColors.green),
          ),
        ],
      ),
    );
  }
}

/// Deterministic confetti: ~36 pieces falling and fading over one run.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);
  final double t;

  static const _colors = [
    Color(0xFFFF8A3D),
    Color(0xFF9FD3AE),
    Color(0xFFFFE6D6),
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final rnd = math.Random(7);
    for (var i = 0; i < 36; i++) {
      final x = rnd.nextDouble() * size.width;
      final delay = rnd.nextDouble() * 0.4;
      final speed = 0.6 + rnd.nextDouble() * 0.6;
      final p = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final y = -20 + p * speed * (size.height + 40);
      final sway = math.sin(p * math.pi * 3 + i) * 18;
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(
          alpha: (1 - p).clamp(0.0, 1.0) * 0.9,
        );
      canvas.save();
      canvas.translate(x + sway, y);
      canvas.rotate(p * math.pi * 4 + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -7, 8, 14),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
