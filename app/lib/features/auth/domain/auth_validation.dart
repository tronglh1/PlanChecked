/// Pure input rules for the login flow.
class AuthValidation {
  const AuthValidation._();

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static bool isValidEmail(String input) => _email.hasMatch(input.trim());

  /// Supabase email OTP is 6 digits.
  static bool isValidOtp(String input) =>
      RegExp(r'^\d{6}$').hasMatch(input.trim());
}
