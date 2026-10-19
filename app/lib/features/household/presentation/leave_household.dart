import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import 'household_providers.dart';

/// HSH-09: confirm, then `leave_household()`. Owners are told who inherits
/// the Owner role (the longest-standing member, decided server-side) or that
/// the household is deleted when they are the last member.
Future<bool> confirmLeaveHousehold(BuildContext context, WidgetRef ref) async {
  final h = ref.read(householdProvider).value;
  if (h == null) return false;
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final successor = h.successor;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.householdLeaveTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.householdLeaveBody),
          if (h.isOwner) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              key: const Key('leave-owner-note'),
              successor == null
                  ? l10n.householdLeaveLast
                  : l10n.householdLeaveOwnerBody(successor.name),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          key: const Key('leave-confirm'),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.householdLeaveAction),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  try {
    await ref.read(householdRepositoryProvider).leaveHousehold();
    // Leaving is a deliberate choice: do not push onboarding step 2 again.
    await ref.read(householdSkipProvider.notifier).skip();
    await ref.read(householdProvider.notifier).reload();
    messenger.showSnackBar(SnackBar(content: Text(l10n.householdLeft)));
    return true;
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.householdErrorGeneric)));
    return false;
  }
}
