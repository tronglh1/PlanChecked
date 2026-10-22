import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/notification_settings.dart';

abstract class NotificationPrefsRepository {
  /// Upserts one `notification_prefs` row per type (with `bundle_daily`).
  Future<void> save(NotificationSettings settings);
}

class SupabaseNotificationPrefsRepository
    implements NotificationPrefsRepository {
  SupabaseNotificationPrefsRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<void> save(NotificationSettings settings) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('notification_prefs').upsert([
      for (final t in NotifType.values)
        {
          'user_id': uid,
          'type': t.code,
          'enabled': settings.isEnabled(t),
          'bundle_daily': settings.bundleDaily,
        },
    ], onConflict: 'user_id,type');
  }
}
