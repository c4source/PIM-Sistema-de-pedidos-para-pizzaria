import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class MovimentacaoEstoqueApi {
  Future<void> registrar({
    required int produtoId,
    required String tipo,
    required int quantidade,
    required String token,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/MovimentacaoEstoque');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'produtoId': produtoId,
        'tipo': tipo,
        'quantidade': quantidade,
      }),
    );

    if (response.statusCode == 201) {
      return;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Usuário não autorizado');
    }

    if (response.statusCode == 400) {
      throw Exception(response.body);
    }

    if (response.statusCode == 404) {
      throw Exception('Produto não encontrado');
    }

    throw Exception('Erro ao registrar movimentação');
  }
}
