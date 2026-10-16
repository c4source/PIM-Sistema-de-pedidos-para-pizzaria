import '../../models/produto.dart';
import '../api/produto_api.dart';
import 'auth_repository.dart';

class ProdutoRepository {
  final ProdutoApi _produtoApi = ProdutoApi();
  final AuthRepository _authRepository = AuthRepository();

  //Listar
  Future<List<Produto>> listar() {
    return _produtoApi.listar();
  }

  //Cadastrar
  Future<Produto> cadastrar({
    required String nome,
    required double preco,
    String? descricao,
    String? categoria,
    String? status,
    int? estoque,
    String? imagemUrl,
  }) async {
    final token = await _authRepository.obterToken();

    if (token == null) {
      throw Exception('Usuário não autenticado');
    }

    return _produtoApi.cadastrar(
      nome: nome,
      preco: preco,
      descricao: descricao,
      categoria: categoria,
      status: status,
      estoque: estoque,
      imagemUrl: imagemUrl,
      token: token,
    );
  }

  //Atualizar
  Future<void> atualizar({
    required int id,
    required String nome,
    required double preco,
    String? descricao,
    String? categoria,
    String? status,
    int? estoque,
    String? imagemUrl,
  }) async {
    final token = await _authRepository.obterToken();

    if (token == null) {
      throw Exception('Usuário não autenticado');
    }

    await _produtoApi.atualizar(
      id: id,
      nome: nome,
      preco: preco,
      descricao: descricao,
      categoria: categoria,
      status: status,
      estoque: estoque,
      imagemUrl: imagemUrl,
      token: token,
    );
  }

  //remover
  Future<void> remover({required int id}) async {
    final token = await _authRepository.obterToken();

    if (token == null) {
      throw Exception('Usuário não autenticado');
    }

    await _produtoApi.remover(id: id, token: token);
  }
}
