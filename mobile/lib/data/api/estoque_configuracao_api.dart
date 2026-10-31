import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import '../repositories/auth_repository.dart';

class EstoqueConfiguracaoApi {
  Future<void> definirLimite(int produto, int limite) async {
    final token = await AuthRepository().obterToken();
    if (token == null) throw Exception('Entre novamente.');
    final resposta = await http
        .patch(
          Uri.parse(
            '${ApiConfig.baseUrl}/api/Produto/$produto/estoque-minimo',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'estoqueMinimo': limite}),
        )
        .timeout(const Duration(seconds: 8));
    if (resposta.statusCode != 204) {
      throw Exception(
        'Não foi possível atualizar o alerta. Confira sua conexão e permissão.',
      );
    }
  }
}
