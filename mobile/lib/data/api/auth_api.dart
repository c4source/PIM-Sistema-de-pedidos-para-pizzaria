import 'dart:convert';

import 'api_config.dart';

import 'package:http/http.dart' as http;

class AuthApi {
  Future<Map<String, dynamic>> login(String email, String senha) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/Auth/login-colaborador');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('E-mail ou senha inválidos');
  }
}
