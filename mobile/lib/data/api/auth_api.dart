import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class AuthApi {
  Future<bool> registrarAtividade(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/Auth/atividade'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode != 401;
  }

  // LOGIN DO COLABORADOR
  Future<Map<String, dynamic>> login(String email, String senha) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/Auth/login-colaborador');

    late http.Response response;
    try {
      response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception('O servidor demorou para responder. Tente novamente.');
    } on http.ClientException {
      throw Exception(
        'Não foi possível conectar à API. Verifique a conexão e se o backend está em execução.',
      );
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      throw Exception('E-mail ou senha inválidos.');
    }
    if (response.statusCode == 403) {
      throw Exception('Acesso não autorizado. Verifique com o administrador.');
    }
    if (response.statusCode >= 500) {
      throw Exception('Servidor indisponível. Tente novamente mais tarde.');
    }
    throw Exception(
      'Não foi possível entrar (HTTP ${response.statusCode}). Verifique os dados e a configuração da API.',
    );
  }

  // TROCA OBRIGATÓRIA DE SENHA
  Future<Map<String, dynamic>> trocarSenha({
    required String token,
    required String novaSenha,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/Auth/trocar-senha');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'novaSenha': novaSenha, 'confirmacaoSenha': novaSenha}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    if (response.statusCode == 400) {
      throw Exception('Senha inválida. Verifique os requisitos.');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Sessão provisória inválida ou expirada.');
    }

    throw Exception('Não foi possível alterar a senha.');
  }

  // Verifica se a sessão continua válida no backend.
  Future<bool> validarSessao(String token) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/Auth/sessao');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      return false;
    }

    throw Exception('Não foi possível validar a sessão.');
  }
}
