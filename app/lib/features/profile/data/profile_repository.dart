import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/user_profile.dart';

abstract class ProfileRepository {
  /// Returns null when the user has no `users` row yet.
  Future<UserProfile?> fetch();
  Future<void> save(UserProfile profile);
  Future<void> updateLang(String lang);

  /// Records the terms / privacy / ND13 acceptance shown on the login screen
  /// (`consents`). Idempotent per kind and [version]; best effort.
  Future<void> recordConsents(String version);

  /// Uploads an avatar and returns the storage path to keep in `avatar_path`.
  Future<String> uploadAvatar(Uint8List bytes, {String ext = 'jpg'});
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Not signed in');
    return id;
  }

  @override
  Future<UserProfile?> fetch() async {
    final row = await _client
        .from('users')
        .select()
        .eq('id', _uid)
        .maybeSingle();
    return row == null ? null : UserProfile.fromRow(row);
  }

  @override
  Future<void> save(UserProfile profile) async {
    // INSERT on `users` is revoked; the row is created by the auth trigger.
    final row = profile.toRow()..remove('id');
    final updated = await _client
        .from('users')
        .update(row)
        .eq('id', _uid)
        .select('id');
    if (updated.isEmpty) {
      // RLS hid the row or the trigger row is missing: surface it, do not
      // pretend the profile was saved.
      throw StateError('Profile row not found for current user');
    }
  }

  @override
  Future<void> recordConsents(String version) async {
    const kinds = ['terms', 'privacy', 'nd13'];
    final have = await _client
        .from('consents')
        .select('kind')
        .eq('user_id', _uid)
        .eq('version', version);
    final done = {for (final r in have) r['kind'] as String};
    final rows = [
      for (final k in kinds)
        if (!done.contains(k))
          {'user_id': _uid, 'kind': k, 'version': version, 'granted': true},
    ];
    if (rows.isEmpty) return;
    await _client.from('consents').insert(rows);
  }

  @override
  Future<void> updateLang(String lang) async {
    await _client.from('users').update({'lang': lang}).eq('id', _uid);
  }

  @override
  Future<String> uploadAvatar(Uint8List bytes, {String ext = 'jpg'}) async {
    final path = '$_uid/avatar.$ext';
    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }
}
