import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env.dart';
import '../data/auth_repository.dart';

enum AuthStatus { configMissing, signedOut, signedIn }

/// Throws when Supabase is not configured; [AuthStateNotifier] maps that to
/// [AuthStatus.configMissing]. Tests override this with a fake.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!Env.isConfigured) throw StateError('Supabase is not configured');
  return SupabaseAuthRepository();
});

/// Reads the auth session. Never throws when Supabase is not configured or
/// not initialized: reports [AuthStatus.configMissing] instead.
class AuthStateNotifier extends Notifier<AuthStatus> {
  StreamSubscription<String?>? _sub;

  @override
  AuthStatus build() {
    ref.onDispose(() => _sub?.cancel());
    try {
      final repo = ref.read(authRepositoryProvider);
      _sub = repo.userIdChanges().listen((id) {
        state = id == null ? AuthStatus.signedOut : AuthStatus.signedIn;
      });
      return repo.currentUserId == null
          ? AuthStatus.signedOut
          : AuthStatus.signedIn;
    } catch (_) {
      return AuthStatus.configMissing;
    }
  }
}

final authStateProvider = NotifierProvider<AuthStateNotifier, AuthStatus>(
  AuthStateNotifier.new,
);
