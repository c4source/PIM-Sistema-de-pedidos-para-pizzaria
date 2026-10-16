import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/produto.dart';
import 'api_config.dart';

//get
class ProdutoApi {
  Future<List<Produto>> listar() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/Produto');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> dados = jsonDecode(response.body);

      return dados.map((item) => Produto.fromJson(item)).toList();
    }

    throw Exception('Erro ao carregar produtos');
  }

  //post
  Future<Produto> cadastrar({
    required String nome,
    required double preco,
    String? descricao,
    String? categoria,
    String? status,
    int? estoque,
    String? imagemUrl,
    required String token,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/Produto');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': nome,
        'preco': preco,
        'descricao': descricao,
        'categoria': categoria,
        'status': status,
        'estoque': estoque,
        'imagemUrl': imagemUrl,
      }),
    );

    if (response.statusCode == 201) {
      return Produto.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Usuário não autorizado');
    }

    throw Exception('Erro ao cadastrar produto');
  }

  //Editar
  Future<void> atualizar({
    required int id,
    required String nome,
    required double preco,
    String? descricao,
    String? categoria,
    String? status,
    int? estoque,
    String? imagemUrl,
    required String token,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/Produto/$id');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': nome,
        'preco': preco,
        'descricao': descricao,
        'categoria': categoria,
        'status': status,
        'estoque': estoque,
        'imagemUrl': imagemUrl,
      }),
    );

    if (response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Usuário não autorizado');
    }

    throw Exception('Erro ao atualizar produto');
  }

  //Remover
  Future<void> remover({required int id, required String token}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/Produto/$id');

    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Usuário não autorizado');
    }

    if (response.statusCode == 404) {
      throw Exception('Produto não encontrado');
    }

    throw Exception('Erro ao remover produto');
  }


}
