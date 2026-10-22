import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/share_service.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/household_models.dart';
import 'household_providers.dart';
import 'household_widgets.dart';

/// The shareable code card: one `invite` Edge Function call (channel `code`,
/// role member) per visit.
final inviteCodeProvider = FutureProvider.autoDispose<InviteResult>(
  (ref) => ref
      .watch(householdRepositoryProvider)
      .createInvite(channel: 'code', role: HouseholdRole.member),
);

final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Screen 18 (HSH-01/02): code card, share link, direct invite by email/phone.
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _target = TextEditingController();
  HouseholdRole _role = HouseholdRole.member;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  String _shareText(AppLocalizations l10n, Household? h, InviteResult inv) =>
      l10n.householdInviteShareText(
        h?.me?.name ?? '',
        h?.name ?? l10n.householdNameDefault,
        inv.code,
        inv.link,
      );

  Future<void> _copy(InviteResult inv) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: inv.code));
    messenger.showSnackBar(SnackBar(content: Text(l10n.householdInviteCopied)));
  }

  Future<void> _shareLink(InviteResult inv, Household? h) async {
    final l10n = AppLocalizations.of(context);
    await ref
        .read(shareServiceProvider)
        .shareText(
          _shareText(l10n, h, inv),
          subject: l10n.householdInviteTitle,
        );
  }

  Future<void> _sendDirect(Household? h) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final target = _target.text.trim();
    final isEmail = target.contains('@');
    final digits = target.replaceAll(RegExp(r'[\s.\-+()]'), '');
    final isPhone = RegExp(r'^\d{8,15}$').hasMatch(digits);
    if (target.isEmpty ||
        (isEmail && !_emailRe.hasMatch(target)) ||
        (!isEmail && !isPhone)) {
      setState(() => _error = l10n.householdInviteTargetInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(householdRepositoryProvider);
      final inv = await repo.createInvite(
        channel: isEmail ? 'email' : 'phone',
        target: target,
        role: _role,
      );
      if (isEmail && inv.emailSent) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.householdInviteEmailSent(target))),
        );
      } else {
        // Phone is never sent by the server and email may be unconfigured:
        // fall back to the OS share sheet.
        if (isEmail) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.householdInviteEmailFailed)),
          );
        }
        if (mounted) {
          await ref
              .read(shareServiceProvider)
              .shareText(
                _shareText(l10n, h, inv),
                subject: l10n.householdInviteTitle,
              );
        }
      }
      if (mounted) _target.clear();
    } on HouseholdFailure catch (e) {
      if (mounted) {
        setState(
          () => _error = e.code == HouseholdFailure.notOwner
              ? l10n.householdInviteOwnerOnly
              : l10n.householdErrorGeneric,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = l10n.householdErrorGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final household = ref.watch(householdProvider).value;
    final isOwner = household?.isOwner ?? false;
    final invite = isOwner ? ref.watch(inviteCodeProvider) : null;
    return GlassScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/household'),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                  ],
                ),
                Text(
                  l10n.householdInviteTitle,
                  style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (household != null && !isOwner)
                  Text(
                    l10n.householdInviteOwnerOnly,
                    key: const Key('invite-owner-only'),
                    style: t.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else ...[
                  _CodeCard(
                    householdName: household?.name,
                    invite: invite,
                    onCopy: _copy,
                    onShare: (inv) => _shareLink(inv, household),
                    onRetry: () => ref.invalidate(inviteCodeProvider),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Text(
                      l10n.householdInviteOr,
                      style: t.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GlassTextField(
                    key: const Key('invite-target'),
                    controller: _target,
                    label: l10n.householdInviteTargetLabel,
                    hint: l10n.householdInviteTargetHint,
                    errorText: _error,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.householdInviteRole,
                    style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _RoleOption(
                    key: const Key('role-member'),
                    title: l10n.householdRoleMember,
                    desc: l10n.householdInviteRoleMemberDesc,
                    selected: _role == HouseholdRole.member,
                    onTap: () => setState(() => _role = HouseholdRole.member),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _RoleOption(
                    key: const Key('role-owner'),
                    title: l10n.householdRoleOwner,
                    desc: l10n.householdInviteRoleOwnerDesc,
                    selected: _role == HouseholdRole.owner,
                    onTap: () => setState(() => _role = HouseholdRole.owner),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: InkButton(
                      key: const Key('invite-send'),
                      label: l10n.householdInviteSend,
                      busy: _busy,
                      onPressed: () => _sendDirect(household),
                    ),
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

class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.householdName,
    required this.invite,
    required this.onCopy,
    required this.onShare,
    required this.onRetry,
  });
  final String? householdName;
  final AsyncValue<InviteResult>? invite;
  final void Function(InviteResult) onCopy;
  final void Function(InviteResult) onShare;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final inv = invite?.value;
    return GlassCard(
      child: Column(
        children: [
          Text(
            l10n.householdInviteCodeLabel(
              householdName ?? l10n.householdNameDefault,
            ),
            style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (invite == null || invite!.isLoading)
            Text(l10n.householdInviteLoading)
          else if (invite!.hasError)
            TextButton(onPressed: onRetry, child: Text(l10n.commonRetry))
          else ...[
            Text(
              inv!.code,
              key: const Key('invite-code'),
              style: t.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
            Text(
              l10n.householdInviteExpires(inv.daysLeft(DateTime.now())),
              style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: GlowButton(
                    key: const Key('invite-copy'),
                    label: l10n.householdInviteCopy,
                    variant: GlowButtonVariant.secondary,
                    onPressed: () => onCopy(inv),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: GlowButton(
                    key: const Key('invite-share'),
                    label: l10n.householdInviteShareLink,
                    icon: Icons.share_rounded,
                    onPressed: () => onShare(inv),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    super.key,
    required this.title,
    required this.desc,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? AppColors.orangeTab : AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  desc,
                  style: t.bodySmall?.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
