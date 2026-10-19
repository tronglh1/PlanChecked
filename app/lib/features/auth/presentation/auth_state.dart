import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env.dart';

enum AuthStatus { configMissing, signedOut, signedIn }

/// Reads the Supabase session. Never throws when Supabase is not configured
/// or not initialized: reports [AuthStatus.configMissing] instead.
class AuthStateNotifier extends Notifier<AuthStatus> {
  StreamSubscription<AuthState>? _sub;

  @override
  AuthStatus build() {
    ref.onDispose(() => _sub?.cancel());
    if (!Env.isConfigured) return AuthStatus.configMissing;
    try {
      final auth = Supabase.instance.client.auth;
      _sub = auth.onAuthStateChange.listen((event) {
        state = _fromSession(event.session);
      });
      return _fromSession(auth.currentSession);
    } catch (_) {
      return AuthStatus.configMissing;
    }
  }

  AuthStatus _fromSession(Session? s) =>
      s == null ? AuthStatus.signedOut : AuthStatus.signedIn;
}

final authStateProvider = NotifierProvider<AuthStateNotifier, AuthStatus>(
  AuthStateNotifier.new,
);
