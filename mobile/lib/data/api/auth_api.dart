import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthApi {
  static const String _baseUrl = 'http://10.0.2.2:5162';

  Future<Map<String, dynamic>> login(String email, String senha) async {
    final url = Uri.parse('$_baseUrl/api/Auth/login-colaborador');

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
