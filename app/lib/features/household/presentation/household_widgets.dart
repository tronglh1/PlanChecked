import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/household_models.dart';
import 'household_providers.dart';

String householdErrorText(AppLocalizations l10n, JoinError e) => switch (e) {
  JoinError.invalid => l10n.householdErrorInvalidCode,
  JoinError.expired => l10n.householdErrorExpired,
  JoinError.alreadyInHousehold => l10n.householdErrorAlreadyIn,
  JoinError.tooManyAttempts => l10n.householdErrorTooMany,
  JoinError.unknown => l10n.householdErrorGeneric,
};

/// Round avatar with the first letter of [name].
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.name, this.radius = 22});
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.greenSoft,
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: AppColors.green, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Small pill: Owner = green tint, Member = neutral (spec §1.1).
class RoleChip extends StatelessWidget {
  const RoleChip({super.key, required this.role});
  final HouseholdRole role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final owner = role == HouseholdRole.owner;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: owner ? AppColors.greenTint : AppColors.dividerSoft,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          owner ? l10n.householdRoleOwner : l10n.householdRoleMember,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: owner ? AppColors.greenDeep : AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Dark "Vào" style button (spec §1.4 dark blocks).
class InkButton extends StatelessWidget {
  const InkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.text,
        foregroundColor: Colors.white,
        minimumSize: const Size(72, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}

/// "Tạo gia đình mới" card. Asks for a name, then calls `create_household`.
/// [onCreated] runs after the household exists.
class CreateHouseholdCard extends ConsumerStatefulWidget {
  const CreateHouseholdCard({super.key, required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<CreateHouseholdCard> createState() =>
      _CreateHouseholdCardState();
}

class _CreateHouseholdCardState extends ConsumerState<CreateHouseholdCard> {
  bool _busy = false;

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NameDialog(),
    );
    if (name == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(householdRepositoryProvider)
          .createHousehold(name.isEmpty ? l10n.householdNameDefault : name);
      await ref.read(householdProvider.notifier).reload();
      if (mounted) widget.onCreated();
    } on HouseholdFailure catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.code == HouseholdFailure.alreadyInHousehold
                ? l10n.householdErrorAlreadyIn
                : l10n.householdErrorGeneric,
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.householdErrorGeneric)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return GlassCard(
      key: const Key('create-household'),
      onTap: _busy ? null : _create,
      child: Row(
        children: [
          const Icon(Icons.add_home_rounded, color: AppColors.orangeMid),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.householdCreateTitle,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  l10n.householdCreateSub,
                  style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (_busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}

/// "Tham gia bằng mã mời" card: code field + dark "Vào" button.
class JoinCodeCard extends ConsumerStatefulWidget {
  const JoinCodeCard({super.key, required this.onJoined, this.initialCode});
  final VoidCallback onJoined;
  final String? initialCode;

  @override
  ConsumerState<JoinCodeCard> createState() => _JoinCodeCardState();
}

class _JoinCodeCardState extends ConsumerState<JoinCodeCard> {
  late final TextEditingController _code = TextEditingController(
    text: widget.initialCode ?? '',
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final l10n = AppLocalizations.of(context);
    final code = normalizeInviteCode(_code.text);
    if (!isValidInviteCode(code)) {
      setState(() => _error = l10n.householdErrorCodeFormat);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await ref
          .read(householdRepositoryProvider)
          .acceptInvite(code);
      if (!mounted) return;
      if (res.ok) {
        ref.read(pendingJoinCodeProvider.notifier).set(null);
        await ref.read(householdProvider.notifier).reload();
        if (mounted) widget.onJoined();
      } else {
        setState(() => _error = householdErrorText(l10n, res.error!));
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
    return GlassCard(
      key: const Key('join-household'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.householdJoinTitle,
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            l10n.householdJoinSub,
            style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GlassTextField(
                  key: const Key('join-code-field'),
                  controller: _code,
                  hint: l10n.householdJoinHint,
                  errorText: _error,
                  maxLength: 12,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _join(),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: InkButton(
                  key: const Key('join-submit'),
                  label: l10n.householdJoinAction,
                  busy: _busy,
                  onPressed: _join,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Owns its controller so it is disposed only after the route is gone.
class _NameDialog extends StatefulWidget {
  const _NameDialog();

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  TextEditingController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller ??= TextEditingController(
      text: l10n.householdNameDefault,
    );
    return AlertDialog(
      title: Text(l10n.householdCreateTitle),
      content: TextField(
        key: const Key('household-name-field'),
        controller: controller,
        maxLength: 40,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.householdNameLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          key: const Key('household-create-confirm'),
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: Text(l10n.householdCreateAction),
        ),
      ],
    );
  }
}
