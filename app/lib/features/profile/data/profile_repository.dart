import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/user_profile.dart';

abstract class ProfileRepository {
  /// Returns null when the user has no `users` row yet.
  Future<UserProfile?> fetch();
  Future<void> save(UserProfile profile);
  Future<void> updateLang(String lang);

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
    await _client.from('users').upsert(profile.toRow());
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
