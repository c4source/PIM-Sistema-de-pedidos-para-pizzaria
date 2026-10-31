import '../api/movimentacao_estoque_api.dart';
import 'auth_repository.dart';

class MovimentacaoEstoqueRepository {
  final MovimentacaoEstoqueApi _api = MovimentacaoEstoqueApi();
  final AuthRepository _authRepository = AuthRepository();

  Future<void> registrar({
    required int produtoId,
    required String tipo,
    required int quantidade,
  }) async {
    final token = await _authRepository.obterToken();

    if (token == null) {
      throw Exception('Usuário não autenticado');
    }

    await _api.registrar(
      produtoId: produtoId,
      tipo: tipo,
      quantidade: quantidade,
      token: token,
    );
  }
}
