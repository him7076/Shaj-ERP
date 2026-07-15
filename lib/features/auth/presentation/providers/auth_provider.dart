import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/core/constants/app_constants.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? email;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.email,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(String email) => AuthState(status: AuthStatus.authenticated, email: email);
  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) => AuthState(status: AuthStatus.error, errorMessage: message);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(prefs);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final SharedPreferences _prefs;

  AuthNotifier(this._prefs) : super(AuthState.initial()) {
    _checkSavedAuth();
  }

  void _checkSavedAuth() {
    final email = _prefs.getString(AppConstants.keyUserEmail) ?? 'admin@sahaj.com';
    final token = _prefs.getString(AppConstants.keyAuthToken) ?? 'dummy_token';

    if (!_prefs.containsKey(AppConstants.keyUserEmail)) {
      _prefs.setString(AppConstants.keyUserEmail, email);
      _prefs.setString(AppConstants.keyAuthToken, token);
    }

    state = AuthState.authenticated(email);
  }

  Future<bool> login(String email, String password) async {
    state = AuthState.loading();
    
    // Simulate API/Firebase delay
    await Future.delayed(const Duration(seconds: 1));

    // Basic Validation Placeholder
    if (email.contains('@') && password.length >= 6) {
      await _prefs.setString(AppConstants.keyUserEmail, email);
      await _prefs.setString(AppConstants.keyAuthToken, 'dummy_firebase_auth_token_for_${email.split('@')[0]}');
      
      state = AuthState.authenticated(email);
      return true;
    } else {
      String errorMsg = 'Invalid email or password. Password must be at least 6 characters.';
      state = AuthState.error(errorMsg);
      return false;
    }
  }

  Future<void> logout() async {
    state = AuthState.loading();
    
    // Simulate cleanup
    await Future.delayed(const Duration(milliseconds: 500));
    
    await _prefs.setString(AppConstants.keyUserEmail, 'admin@sahaj.com');
    await _prefs.setString(AppConstants.keyAuthToken, 'dummy_token');
    
    state = AuthState.authenticated('admin@sahaj.com');
  }
}
