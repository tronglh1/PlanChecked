import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_state.dart';
import '../../today/data/push_service.dart';
import '../../today/presentation/today_providers.dart';

/// Signs out: first deletes this device's `push_tokens` row (needs the live
/// session), then ends the session. Push clean-up is best effort and bounded
/// so a flaky network can never block signing out.
final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    try {
      await removeDeviceToken(
        messaging: ref.read(pushMessagingProvider),
        tokens: ref.read(pushTokenRepositoryProvider),
      ).timeout(const Duration(seconds: 4), onTimeout: () => false);
    } catch (_) {}
    await ref.read(authRepositoryProvider).signOut();
  };
});
