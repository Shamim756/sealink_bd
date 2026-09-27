import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<bool> register({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final r = await _repo.register(
      name: name,
      username: username,
      email: email,
      phone: phone,
      password: password,
      role: role,
    );

    _loading = false;
    if (r['success'] == true) {
      notifyListeners();
      return true;
    }
    _error = r['message'];
    notifyListeners();
    return false;
  }

  Future<bool> verifyEmail(String email, String otp) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final r = await _repo.verifyEmail(email: email, otp: otp);
    _loading = false;
    if (r['success'] == true) {
      notifyListeners();
      return true;
    }
    _error = r['message'];
    notifyListeners();
    return false;
  }

  Future<bool> verifyPhone(String phone, String otp) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final r = await _repo.verifyPhone(phone: phone, otp: otp);
    _loading = false;
    if (r['success'] == true) {
      _user = r['user'];
      notifyListeners();
      return true;
    }
    _error = r['message'];
    notifyListeners();
    return false;
  }

  Future<bool> resendEmailOtp(String email) async {
    final r = await _repo.resendEmailOtp(email);
    return r['success'] == true;
  }

  Future<bool> resendPhoneOtp(String phone) async {
    final r = await _repo.resendPhoneOtp(phone);
    return r['success'] == true;
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final r = await _repo.login(username: username, password: password);
    _loading = false;
    if (r['success'] == true) {
      _user = r['user'];
      notifyListeners();
    } else {
      _error = r['message'];
      notifyListeners();
    }
    return r;
  }

  Future<bool> checkUsername(String u) => _repo.checkUsername(u);

  Future<void> tryAutoLogin() async {
    if (await _repo.isLoggedIn()) {
      _user = await _repo.getMe();
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _user = null;
    notifyListeners();
  }
}
