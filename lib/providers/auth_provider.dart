import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/debug_utils.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? username;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.username,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? username,
    String? error,
    bool clearUsername = false,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      username: clearUsername ? null : (username ?? this.username),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  bool _isOperationInProgress = false;
  
  AuthNotifier() : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    DebugUtils.logAuth('Checking authentication status');
    state = state.copyWith(isLoading: true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final username = prefs.getString('username');
      
      await Future.delayed(const Duration(seconds: 2)); // Splash screen delay
      
      state = state.copyWith(
        isAuthenticated: isLoggedIn,
        username: username,
        isLoading: false,
      );
      DebugUtils.logAuth('Auth status checked: isAuthenticated=$isLoggedIn, username=$username');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> login(String username, String password) async {
    if (_isOperationInProgress) {
      DebugUtils.logAuth('Login blocked - operation already in progress');
      return false;
    }
    
    _isOperationInProgress = true;
    DebugUtils.logAuth('Login attempt for username: $username');
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Simple validation (you can connect to your FastAPI backend here)
      if (username.isNotEmpty && password.length >= 4) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', username);
        
        state = state.copyWith(
          isAuthenticated: true,
          username: username,
          isLoading: false,
          clearError: true,
        );
        DebugUtils.logAuth('Login successful for: $username');
        _isOperationInProgress = false;
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid username or password',
        );
        _isOperationInProgress = false;
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      _isOperationInProgress = false;
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Simple validation
      if (username.isNotEmpty && email.contains('@') && password.length >= 4) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', username);
        
        state = state.copyWith(
          isAuthenticated: true,
          username: username,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid registration data',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    if (_isOperationInProgress) {
      DebugUtils.logAuth('Logout blocked - operation already in progress');
      return;
    }
    
    _isOperationInProgress = true;
    DebugUtils.logAuth('Logout initiated for user: ${state.username}');
    try {
      // Set loading state
      state = state.copyWith(isLoading: true, clearError: true);
      
      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('username');
      
      // Reset to initial state
      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
        username: null,
        error: null,
      );
      DebugUtils.logAuth('Logout completed successfully');
      _isOperationInProgress = false;
    } catch (e) {
      DebugUtils.logError('Logout error occurred', e);
      // Handle logout errors gracefully
      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
        username: null,
        error: null,
      );
      DebugUtils.logAuth('Logout completed with error handling');
      _isOperationInProgress = false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});