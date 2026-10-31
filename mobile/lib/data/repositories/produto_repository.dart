import '../../models/produto.dart';
import '../api/produto_api.dart';
import 'auth_repository.dart';
import '../local/catalogo_local.dart';

class ProdutoRepository {
  final ProdutoApi _produtoApi;
  final AuthRepository _authRepository;
  final CatalogoLocal _local;
  bool usandoCache = false;
  bool falhaCache = false;
  DateTime? ultimaSincronizacao;
  ProdutoRepository({
    ProdutoApi? api,
    CatalogoLocal? local,
    AuthRepository? auth,
  }) : _produtoApi = api ?? ProdutoApi(),
       _local = local ?? CatalogoLocal(),
       _authRepository = auth ?? AuthRepository();

  //Listar
  Future<List<Produto>> listar({bool permitirCache = true}) async {
    usandoCache = false;
    falhaCache = false;
    late List<Produto> produtos;
    try {
      produtos = await _produtoApi.listar();
    } on CatalogoIndisponivel {
      if (!permitirCache) rethrow;
      final salvo = await _local.ler();
      if (salvo == null) rethrow;
      usandoCache = true;
      ultimaSincronizacao = salvo.sincronizadoEm;
      return salvo.produtos;
    }
    try {
      ultimaSincronizacao = await _local.substituir(produtos);
    } catch (_) {
      falhaCache = true;
      ultimaSincronizacao = null;
    }
    return produtos;
  }

  Future<void> _invalidarCache() async {
    ultimaSincronizacao = null;
    try {
      await _local.invalidar();
    } catch (_) {
      falhaCache = true;
    }
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

    final criado = await _produtoApi.cadastrar(
      nome: nome,
      preco: preco,
      descricao: descricao,
      categoria: categoria,
      status: status,
      estoque: estoque,
      imagemUrl: imagemUrl,
      token: token,
    );
    await _invalidarCache();
    return criado;
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
    await _invalidarCache();
  }

  //remover
  Future<void> remover({required int id}) async {
    final token = await _authRepository.obterToken();

    if (token == null) {
      throw Exception('Usuário não autenticado');
    }

    await _produtoApi.remover(id: id, token: token);
    await _invalidarCache();
  }
}
