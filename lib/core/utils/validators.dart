class Validators {
  static String? required(String? v, String f) =>
      (v == null || v.trim().isEmpty) ? '$f required' : null;

  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Email required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
      return 'Invalid email';
    }
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.isEmpty) return 'Phone required';
    if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(v)) {
      return 'Use 01XXXXXXXXX format';
    }
    return null;
  }

  static String? username(String? v) {
    if (v == null || v.isEmpty) return 'Username required';
    if (v.length < 4) return 'Min 4 characters';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
      return 'Only letters, numbers, _';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password required';
    if (v.length < 6) return 'Min 6 characters';
    return null;
  }

  static String? otp(String? v) {
    if (v == null || v.isEmpty) return 'OTP required';
    if (v.length != 6) return '6 digits required';
    return null;
  }
}