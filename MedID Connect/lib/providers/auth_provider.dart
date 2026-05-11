import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  late final AuthService _authService = AuthService(_apiClient);

  bool isChecking = true;
  bool isAuthenticated = false;
  bool isDemoMode = false;
  bool isSubmitting = false;
  String? errorMessage;
  Map<String, dynamic>? currentUser;

  Future<void> bootstrap() async {
    isChecking = true;
    notifyListeners();
    try {
      if (await _authService.hasToken()) {
        currentUser = await _authService.me();
        isAuthenticated = true;
        isDemoMode = false;
      }
    } catch (error) {
      await _apiClient.clearToken();
      isAuthenticated = false;
      errorMessage = _apiClient.readableError(error);
    } finally {
      isChecking = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    return _submit(() => _authService.login(email: email, password: password));
  }

  Future<bool> signup({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _submit(
      () => _authService.signup(
        fullName: fullName,
        email: email,
        password: password,
        age: 34,
        gender: 'Male',
        bloodGroup: 'O+',
      ),
    );
  }

  void continueAsGuest() {
    isAuthenticated = true;
    isDemoMode = true;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    isAuthenticated = false;
    isDemoMode = false;
    currentUser = null;
    notifyListeners();
  }

  Future<bool> _submit(Future<Map<String, dynamic>> Function() action) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await action();
      currentUser = Map<String, dynamic>.from(result['user'] as Map);
      isAuthenticated = true;
      isDemoMode = false;
      return true;
    } catch (error) {
      errorMessage = _apiClient.readableError(error);
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
