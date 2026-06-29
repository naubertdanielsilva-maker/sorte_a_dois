import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.10:8000';

  static Future<dynamic> get(String path) async {
    final token = await AuthService.getToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 8));

    return _handleResponse(response);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final token = await AuthService.getToken();

    final response = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 8));

    return _handleResponse(response);
  }

  static Future<dynamic> uploadPhoto(String path, File file) async {
    final token = await AuthService.getToken();

    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 15));

    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw Exception(
      decoded is Map && decoded['detail'] != null
          ? decoded['detail']
          : 'Erro na comunicação com o servidor.',
    );
  }
}