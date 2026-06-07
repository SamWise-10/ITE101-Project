import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate inputs
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        _errorMessage = 'All fields are required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if email exists
      if (await _authService.emailExists(email)) {
        _errorMessage = 'Email already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if username exists
      if (await _authService.usernameExists(username)) {
        _errorMessage = 'Username already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final success = await _authService.signUp(
        username: username,
        email: email,
        password: password,
        role: role,
      );

      _isLoading = false;
      if (success) {
        _errorMessage = null;
      } else {
        _errorMessage = 'Sign up failed';
      }
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (email.isEmpty || password.isEmpty) {
        _errorMessage = 'Email and password are required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final success = await _authService.signIn(
        email: email,
        password: password,
      );

      if (success) {
        _currentUser = await _authService.getCurrentUser();
        _errorMessage = null;
      } else {
        _errorMessage = 'Invalid email or password';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_currentUser != null) {
      await _authService.logOut(userId: _currentUser!['id']);
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
