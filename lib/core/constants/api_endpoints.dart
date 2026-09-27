class ApiEndpoints {
  // Kali Linux desktop / Chrome → localhost
  static const String baseUrl = 'http://localhost:3000';

  // Android emulator হলে এটা use করুন:
  // static const String baseUrl = 'http://10.0.2.2:3000';

  // Physical device হলে Kali-র IP:
  // static const String baseUrl = 'http://192.168.1.50:3000';

  static const String register = '$baseUrl/auth/register';
  static const String verifyEmail = '$baseUrl/auth/verify-email';
  static const String verifyPhone = '$baseUrl/auth/verify-phone';
  static const String resendEmailOtp = '$baseUrl/auth/resend-email-otp';
  static const String resendPhoneOtp = '$baseUrl/auth/resend-phone-otp';
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';

  static String checkUsername(String username) =>
      '$baseUrl/auth/check-username/$username';
}