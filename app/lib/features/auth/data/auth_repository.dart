import 'package:supabase_flutter/supabase_flutter.dart';

/// Deep-link used as OAuth redirect. Must be registered in the Android
/// manifest (intent-filter) and in Supabase Auth > URL Configuration.
const String kAuthRedirectUrl = 'io.supabase.vuonnha://login-callback/';

abstract class AuthRepository {
  /// Emits the signed-in user id (or null when signed out). The first event
  /// reflects the current session.
  Stream<String?> userIdChanges();
  String? get currentUserId;

  /// Opens the Google consent page in the browser (PKCE); returns when the
  /// flow has been launched. The session arrives later via [userIdChanges].
  Future<void> signInWithGoogle();

  Future<void> sendEmailOtp(String email);
  Future<void> verifyEmailOtp(String email, String code);
  Future<void> signOut();

  /// Calls RPC `delete_my_account`, then clears the local session.
  Future<void> deleteMyAccount();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Stream<String?> userIdChanges() async* {
    yield _client.auth.currentSession?.user.id;
    yield* _client.auth.onAuthStateChange.map((e) => e.session?.user.id);
  }

  @override
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kAuthRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  @override
  Future<void> sendEmailOtp(String email) =>
      _client.auth.signInWithOtp(email: email.trim(), shouldCreateUser: true);

  @override
  Future<void> verifyEmailOtp(String email, String code) => _client.auth
      .verifyOTP(email: email.trim(), token: code.trim(), type: OtpType.email);

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> deleteMyAccount() async {
    await _client.rpc('delete_my_account');
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // Session already gone server-side.
    }
  }
}
