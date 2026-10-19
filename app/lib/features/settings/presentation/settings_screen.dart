import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_state.dart';
import '../../household/presentation/household_providers.dart';
import '../../household/presentation/leave_household.dart';
import '../../profile/domain/provinces.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/notification_settings.dart';
import 'locale_provider.dart';
import 'settings_providers.dart';

/// Screen 21 (tab 5).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _setLang(WidgetRef ref, String lang) async {
    await ref.read(localeProvider.notifier).set(lang);
    try {
      await ref.read(profileProvider.notifier).updateLang(lang);
    } catch (_) {
      // Offline: the local choice still applies.
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    required String cancel,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final first = await _confirm(
      context,
      title: l10n.deleteConfirm1Title,
      body: l10n.deleteConfirm1Body,
      action: l10n.commonContinue,
      cancel: l10n.commonCancel,
    );
    if (!first || !context.mounted) return;
    final second = await _confirm(
      context,
      title: l10n.deleteConfirm2Title,
      body: l10n.deleteConfirm2Body,
      action: l10n.deleteConfirmAction,
      cancel: l10n.commonCancel,
    );
    if (!second) return;
    try {
      // Signing out afterwards flips auth state; the router goes to /login.
      await ref.read(authRepositoryProvider).deleteMyAccount();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.deleteError)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileProvider).value;
    final notif = ref.watch(notificationSettingsProvider);
    final locale = ref.watch(localeProvider);
    final household = ref.watch(householdProvider).value;
    final province = provinceByCode(profile?.provinceCode);
    final name = profile?.displayName ?? '';
    final langName = locale.languageCode == 'en' ? l10n.langEn : l10n.langVi;
    final subtitle = [?province?.name, langName].join(' · ');

    Widget toggle(String label, bool value, ValueChanged<bool> onChanged) {
      return InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Expanded(child: Text(label, style: t.bodyMedium)),
              Switch(
                value: value,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.green,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      );
    }

    final notifier = ref.read(notificationSettingsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        120,
      ),
      children: [
        Text(
          l10n.tabSettings,
          style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.greenSoft,
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: t.titleMedium?.copyWith(
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: t.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const Key('edit-profile'),
                onPressed: () => context.push('/onboarding/profile'),
                child: Text(l10n.settingsEdit),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionLabel(l10n.settingsNotifications),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              toggle(
                l10n.notifTask,
                notif.isEnabled(NotifType.taskReminder),
                (v) => notifier.setType(NotifType.taskReminder, v),
              ),
              const Divider(height: 1),
              toggle(
                l10n.notifCheckin,
                notif.isEnabled(NotifType.checkinReminder),
                (v) => notifier.setType(NotifType.checkinReminder, v),
              ),
              const Divider(height: 1),
              toggle(
                l10n.notifAssignment,
                notif.isEnabled(NotifType.assignment),
                (v) => notifier.setType(NotifType.assignment, v),
              ),
              const Divider(height: 1),
              toggle(
                l10n.notifAchievement,
                notif.isEnabled(NotifType.achievement),
                (v) => notifier.setType(NotifType.achievement, v),
              ),
              const Divider(height: 1),
              toggle(l10n.notifBundle, notif.bundleDaily, notifier.setBundle),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionLabel(l10n.settingsOther),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.settingsLanguage, style: t.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  TagChip(
                    key: const Key('settings-lang-vi'),
                    label: l10n.langVi,
                    selected: locale.languageCode == 'vi',
                    onTap: () => _setLang(ref, 'vi'),
                  ),
                  TagChip(
                    key: const Key('settings-lang-en'),
                    label: l10n.langEn,
                    selected: locale.languageCode == 'en',
                    onTap: () => _setLang(ref, 'en'),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.xl),
              if (household != null)
                InkWell(
                  key: const Key('leave-household'),
                  onTap: () => confirmLeaveHousehold(context, ref),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.householdLeaveRow(household.name),
                            style: t.bodyMedium?.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        GlowButton(
          key: const Key('sign-out'),
          label: l10n.settingsSignOut,
          variant: GlowButtonVariant.secondary,
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          key: const Key('delete-account'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          onPressed: () => _deleteAccount(context, ref),
          child: Text(
            l10n.settingsDeleteAccount,
            style: t.titleSmall?.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
