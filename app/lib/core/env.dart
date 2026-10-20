/// Build-time configuration, supplied with `--dart-define-from-file=env/dev.json`.
class Env {
  const Env._();

  /// Set by main() when Supabase.initialize throws; shown on sign-in errors.
  static String? initError;

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
