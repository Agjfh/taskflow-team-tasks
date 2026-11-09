import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this.api);

  static const _tokenKey = 'auth_token';

  final ApiClient api;
  User? user;
  bool initializing = true;

  bool get isLoggedIn => user != null;

  /// Restores a saved session on app start.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    api.token = prefs.getString(_tokenKey);
    if (api.token != null) {
      try {
        user = User.fromJson(await api.get('/auth/me') as Map<String, dynamic>);
      } on ApiException {
        await _clear();
      }
    }
    initializing = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final data = await api.post('/auth/login', {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;
    await _save(data);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final data = await api.post('/auth/register', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': password,
    }) as Map<String, dynamic>;
    await _save(data);
  }

  Future<void> logout() async {
    try {
      await api.post('/auth/logout');
    } on ApiException {
      // Token may already be invalid; clear locally anyway.
    }
    await _clear();
    notifyListeners();
  }

  Future<void> _save(Map<String, dynamic> data) async {
    api.token = data['token'] as String;
    user = User.fromJson(data['user'] as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, api.token!);
    notifyListeners();
  }

  Future<void> _clear() async {
    api.token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
