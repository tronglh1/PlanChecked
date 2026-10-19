import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/local_prefs.dart';
import '../../../core/env.dart';
import '../data/notification_prefs_repository.dart';
import '../domain/notification_settings.dart';

const String kNotifPrefKey = 'notification_settings';

final notificationPrefsRepositoryProvider =
    Provider<NotificationPrefsRepository>((ref) {
      if (!Env.isConfigured) throw StateError('Supabase is not configured');
      return SupabaseNotificationPrefsRepository();
    });

/// Toggles are stored locally first (works offline), then mirrored to the
/// `notification_prefs` table best-effort.
class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    _load();
    return const NotificationSettings();
  }

  Future<void> _load() async {
    try {
      final raw = await ref.read(localPrefsProvider).get(kNotifPrefKey);
      if (raw != null) state = NotificationSettings.decode(raw);
    } catch (_) {}
  }

  Future<void> setType(NotifType t, bool value) =>
      _update(state.withType(t, value));

  Future<void> setBundle(bool value) => _update(state.withBundle(value));

  Future<void> _update(NotificationSettings next) async {
    state = next;
    try {
      await ref.read(localPrefsProvider).set(kNotifPrefKey, next.encode());
    } catch (_) {}
    try {
      await ref.read(notificationPrefsRepositoryProvider).save(next);
    } catch (_) {
      // Offline or backend not ready: the local value stays authoritative.
    }
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      NotificationSettingsNotifier.new,
    );
