import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class FalhaMovimentacao implements Exception {
  final int status;
  final String mensagem;
  FalhaMovimentacao(this.status, this.mensagem);
  @override
  String toString() => mensagem;
}

class MovimentacaoEstoqueApi {
  final http.Client _client;
  MovimentacaoEstoqueApi({http.Client? cliente})
    : _client = cliente ?? http.Client();
  Future<void> registrar({
    required int produtoId,
    required String tipo,
    required int quantidade,
    required String token,
    required String operacaoId,
    String motivo = "outro",
    String? observacao,
    int? estoqueEsperado,
    int? quantidadeContada,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/api/MovimentacaoEstoque'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'produtoId': produtoId,
            'tipo': tipo,
            'quantidade': quantidade,
            'operacaoId': operacaoId,
            'motivo': motivo,
            'observacao': observacao,
            'estoqueEsperado': estoqueEsperado,
            'quantidadeContada': quantidadeContada,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 201) return;
    throw FalhaMovimentacao(response.statusCode, _mensagem(response));
  }

  Future<Map<String, dynamic>> listar(
    String token, {
    int pagina = 1,
    Map<String, String> filtros = const {},
  }) async {
    final response = await _client
        .get(
          Uri.parse(
            '${ApiConfig.baseUrl}/api/MovimentacaoEstoque',
          ).replace(queryParameters: {'pagina': pagina.toString(), ...filtros}),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw FalhaMovimentacao(response.statusCode, _mensagem(response));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> responsaveis(String token) async {
    final r = await _client
        .get(
          Uri.parse(
            '${ApiConfig.baseUrl}/api/MovimentacaoEstoque/responsaveis',
          ),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) {
      throw FalhaMovimentacao(r.statusCode, _mensagem(r));
    }
    return jsonDecode(r.body) as List;
  }

  String _mensagem(http.Response r) {
    if (r.statusCode == 401) {
      return 'Sessão expirada. Entre novamente para sincronizar.';
    }
    if (r.statusCode == 403) return 'Acesso não autorizado.';
    if (r.statusCode >= 500) {
      return 'Servidor indisponível. Tentaremos novamente.';
    }
    try {
      final body = jsonDecode(r.body);
      if (body is String) return body;
      if (body is Map && body['errors'] is Map) {
        return (body['errors'] as Map).values
            .expand((v) => v as List)
            .join(' ');
      }
    } catch (_) {
      /* Respostas de texto são aceitas abaixo. */
    }
    return r.body.length < 500 && !r.body.contains('<')
        ? r.body
        : 'Não foi possível processar a movimentação.';
  }
}
