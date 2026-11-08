import 'dart:convert';

import 'package:http/http.dart' as http;

import '../repositories/auth_repository.dart';
import '../repositories/movimentacao_estoque_repository.dart';
import 'api_config.dart';

class ColaboradoresApi {
  Future<dynamic> executar(
    String metodo, {
    String caminho = '',
    Map<String, dynamic>? dados,
  }) async {
    final token = await AuthRepository().obterToken();
    if (!administradorSessao(token)) {
      throw Exception('Somente administradores podem gerenciar usuários.');
    }
    final request = http.Request(
      metodo,
      Uri.parse('${ApiConfig.baseUrl}/api/Colaboradores$caminho'),
    );
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token!}',
    });
    if (dados != null) request.body = jsonEncode(dados);
    final client = http.Client();
    try {
      final response = await http.Response.fromStream(
        await client.send(request),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isEmpty ? null : jsonDecode(response.body);
      }
      if (response.statusCode == 401) {
        throw Exception('Sessão expirada. Entre novamente.');
      }
      if (response.statusCode == 403) {
        throw Exception('Acesso permitido apenas ao administrador.');
      }
      if (response.statusCode >= 500) {
        throw Exception('Servidor indisponível. Tente novamente.');
      }
      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = response.body;
      }
      final mensagem = body is Map && body['errors'] is Map
          ? (body['errors'] as Map).values.expand((v) => v as List).join(' ')
          : body is String
          ? body
          : 'Não foi possível concluir a operação.';
      throw Exception(mensagem);
    } finally {
      client.close();
    }
  }
}
