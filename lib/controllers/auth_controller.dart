// lib/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../core/logger.dart';

class AuthController extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _errorMessage;
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await AuthService().login(username, password);
      if (user != null) {
        _isLoggedIn = true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      Logger.error('Login failed', error: e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService().logout();
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> register(
    String username,
    String password, {
    String? role,
    String? email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthService().register(
        username,
        password,
        role: role,
        email: email,
      );
      // Auto login after register?
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> changePassword(String oldPass, String newPass) async {
    try {
      await AuthService().changePassword(oldPass, newPass);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // 2FA
  Future<bool> verify2FA(String code) async {
    return await AuthService().verify2FA(code);
  }

  // Check session
  void checkAuth() {
    _isLoggedIn = AuthService().isAuthenticated;
    notifyListeners();
  }
}
