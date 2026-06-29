import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'access_token';
  static const String _nameKey = 'user_name';
  static const String _emailKey = 'user_email';
  static const String _idKey = 'user_id';

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiService.post('/auth/login', {
      'email': email,
      'password': password,
    });

    await _saveSession(data);
    return data['user'];
  }

  static Future<Map<String, dynamic>> registerAndLogin({
    required String name,
    required String email,
    required String password,
  }) async {
    await ApiService.post('/users/', {
      'name': name,
      'email': email,
      'password': password,
    });

    return login(email: email, password: password);
  }

  static Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, data['access_token']);
    await prefs.setString(_nameKey, data['user']['name']);
    await prefs.setString(_emailKey, data['user']['email']);
    await prefs.setInt(_idKey, data['user']['id']);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_idKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}