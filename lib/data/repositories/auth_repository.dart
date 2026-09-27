import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/api_client.dart';
import '../models/user_model.dart';
import '../../core/constants/api_endpoints.dart';

class AuthRepository {
  final _dio = ApiClient().dio;

  // ---- Register ----
  Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      final r = await _dio.post(ApiEndpoints.register, data: {
        'name': name,
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      });
      return {'success': true, 'data': r.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  // ---- Verify Email ----
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final r = await _dio.post(ApiEndpoints.verifyEmail,
          data: {'email': email, 'otp': otp});
      return {'success': true, 'data': r.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  // ---- Verify Phone (final → returns token) ----
  Future<Map<String, dynamic>> verifyPhone({
    required String phone,
    required String otp,
  }) async {
    try {
      final r = await _dio.post(ApiEndpoints.verifyPhone,
          data: {'phone': phone, 'otp': otp});
      final token = r.data['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      final user = UserModel.fromJson(r.data['user']);
      return {'success': true, 'user': user};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  // ---- Resend Email OTP ----
  Future<Map<String, dynamic>> resendEmailOtp(String email) async {
    try {
      await _dio.post(ApiEndpoints.resendEmailOtp, data: {'email': email});
      return {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Error'
      };
    }
  }

  // ---- Resend Phone OTP ----
  Future<Map<String, dynamic>> resendPhoneOtp(String phone) async {
    try {
      await _dio.post(ApiEndpoints.resendPhoneOtp, data: {'phone': phone});
      return {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Error'
      };
    }
  }

  // ---- Login ----
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final r = await _dio.post(ApiEndpoints.login,
          data: {'username': username, 'password': password});
      final token = r.data['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      final user = UserModel.fromJson(r.data['user']);
      return {'success': true, 'user': user};
    } on DioException catch (e) {
      final data = e.response?.data;
      return {
        'success': false,
        'message': data?['message'] ?? 'Network error',
        'nextStep': data?['nextStep'],
        'email': data?['email'],
        'phone': data?['phone'],
      };
    }
  }

  // ---- Check Username ----
  Future<bool> checkUsername(String u) async {
    try {
      final r = await _dio.get(ApiEndpoints.checkUsername(u));
      return r.data['available'] == true;
    } catch (_) {
      return false;
    }
  }

  // ---- Get Current User ----
  Future<UserModel?> getMe() async {
    try {
      final r = await _dio.get(ApiEndpoints.me);
      if (r.data['success'] == true) return UserModel.fromJson(r.data['user']);
      return null;
    } catch (_) {
      return null;
    }
  }

  // ---- Logout ----
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // ---- Is Logged In ----
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') != null;
  }
}