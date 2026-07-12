import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ApiService {
  static const String baseUrl =
      'https://sorte-a-dois-backend.onrender.com';

  static Future<dynamic> get(String path) async {
    final token = await AuthService.getToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl$path'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 60));

    return _handleResponse(response);
  }

  static Future<dynamic> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await AuthService.getToken();

    final response = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    return _handleResponse(response);
  }

  static Future<dynamic> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await AuthService.getToken();

    final response = await http
        .patch(
          Uri.parse('$baseUrl$path'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    return _handleResponse(response);
  }

  static Future<dynamic> delete(String path) async {
    final token = await AuthService.getToken();

    final response = await http
        .delete(
          Uri.parse('$baseUrl$path'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 60));

    return _handleResponse(response);
  }

  static Future<dynamic> uploadPhoto(
    String path,
    File file,
  ) async {
    final token = await AuthService.getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$path'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 90));

    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  static Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic decoded;

    try {
      decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return decoded;
    }

    throw Exception(
      decoded is Map && decoded['detail'] != null
          ? decoded['detail'].toString()
          : decoded is String && decoded.isNotEmpty
              ? decoded
              : 'Erro ${response.statusCode} na comunicaÃ§Ã£o com o servidor.',
    );
  }
}