import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:estoque_app/models/produto.dart';
import 'package:estoque_app/data/local/catalogo_local.dart';
import 'package:estoque_app/data/api/produto_api.dart';
import 'package:estoque_app/data/repositories/produto_repository.dart';
import 'package:estoque_app/data/repositories/auth_repository.dart';

class AuthTeste extends AuthRepository {
  @override
  Future<String?> obterToken() async => 'token-teste';
}

class ApiTeste extends ProdutoApi {
  List<Produto> produtos;
  Exception? erro;
  bool falhaEscrita = false;
  ApiTeste(this.produtos);
  @override
  Future<List<Produto>> listar() async {
    if (erro != null) throw erro!;
    return produtos;
  }

  @override
  Future<void> remover({required int id, required String token}) async {
    if (falhaEscrita) throw const CatalogoIndisponivel('Sem conexão');
  }
}

Produto produto(int id, {bool kit = false, int estoque = 3}) => Produto(
  id: id,
  nome: kit ? 'Combo' : 'Pizza',
  preco: 29.90,
  ehKit: kit,
  estoque: estoque,
  status: 'disponivel',
  categoria: kit ? 'combo' : 'pizza',
);

void main() {
  late Database db;
  late CatalogoLocal local;
  setUpAll(() {
    sqfliteFfiInit();
  });
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await CatalogoLocal.criarSchema(db);
    local = CatalogoLocal(bancoTeste: db);
  });
  tearDown(() async {
    await db.close();
  });
  test('Catálogo continua no arquivo SQLite após fechar e reabrir', () async {
    final pasta = await Directory.systemTemp.createTemp('pim_sqlite_teste_');
    final arquivo = path.join(pasta.path, 'catalogo.db');
    var disco = await databaseFactoryFfi.openDatabase(
      arquivo,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, versao) => CatalogoLocal.criarSchema(db),
      ),
    );
    try {
      await CatalogoLocal(bancoTeste: disco)
          .substituir([produto(9, kit: true, estoque: 2)]);
      await disco.close();
      disco = await databaseFactoryFfi.openDatabase(arquivo);
      final salvo = await CatalogoLocal(bancoTeste: disco).ler();
      expect(salvo!.produtos.single.id, 9);
      expect(salvo.produtos.single.ehKit, isTrue);
    } finally {
      await disco.close();
      await databaseFactoryFfi.deleteDatabase(arquivo);
      await pasta.delete();
    }
  });
  test('Primeira instalação não inventa catálogo vazio sincronizado', () async {
    expect(await local.ler(), isNull);
  });
  test('Preserva produtos, identificação de kits, saldo e data', () async {
    final data = await local.substituir([
      produto(1),
      produto(2, kit: true, estoque: 1),
    ]);
    final salvo = (await local.ler())!;
    expect(salvo.produtos.length, 2);
    expect(salvo.produtos.firstWhere((p) => p.id == 2).ehKit, isTrue);
    expect(salvo.produtos.firstWhere((p) => p.id == 2).estoque, 1);
    expect(salvo.sincronizadoEm, data);
  });
  test(
    'Snapshot novo remove produtos excluídos e aceita catálogo vazio',
    () async {
      await local.substituir([produto(1), produto(2)]);
      await local.substituir([produto(2)]);
      expect((await local.ler())!.produtos.single.id, 2);
      await local.substituir([]);
      expect((await local.ler())!.produtos, isEmpty);
    },
  );
  test(
    'Falha de gravação desfaz troca inteira e preserva snapshot anterior',
    () async {
      final data = await local.substituir([produto(1)]);
      await expectLater(
        local.substituir([produto(2), produto(2)]),
        throwsA(isA<DatabaseException>()),
      );
      final salvo = (await local.ler())!;
      expect(salvo.produtos.single.id, 1);
      expect(salvo.sincronizadoEm, data);
    },
  );
  test('Consulta online sincroniza e falha de rede utiliza SQLite', () async {
    final api = ApiTeste([produto(1)]);
    final repo = ProdutoRepository(api: api, local: local);
    await repo.listar();
    expect(repo.usandoCache, isFalse);
    api.erro = const CatalogoIndisponivel('Sem conexão');
    expect((await repo.listar()).single.id, 1);
    expect(repo.usandoCache, isTrue);
    expect(repo.ultimaSincronizacao, isNotNull);
  });
  test(
    'Sem sincronização anterior ou com cache proibido, falha é mantida',
    () async {
      final repo = ProdutoRepository(
        api: ApiTeste([])..erro = const CatalogoIndisponivel('Sem conexão'),
        local: local,
      );
      await expectLater(repo.listar(), throwsA(isA<CatalogoIndisponivel>()));
      await local.substituir([produto(1)]);
      await expectLater(
        repo.listar(permitirCache: false),
        throwsA(isA<CatalogoIndisponivel>()),
      );
    },
  );
  test('401 e resposta inválida não são escondidos pelo cache', () async {
    await local.substituir([produto(1)]);
    for (final response in [
      http.Response('Não autorizado', 401),
      http.Response('invalido', 200),
    ]) {
      final api = ProdutoApi(cliente: MockClient((_) async => response));
      final repo = ProdutoRepository(api: api, local: local);
      await expectLater(repo.listar(), throwsA(isA<Exception>()));
      expect(repo.usandoCache, isFalse);
    }
  });
  test(
    '503 permite consulta histórica e volta a sincronizar ao reconectar',
    () async {
      await local.substituir([produto(1)]);
      final api = ApiTeste([])
        ..erro = const CatalogoIndisponivel('Servidor indisponível');
      final repo = ProdutoRepository(api: api, local: local);
      await repo.listar();
      expect(repo.usandoCache, isTrue);
      api.erro = null;
      api.produtos = [produto(2)];
      expect((await repo.listar()).single.id, 2);
      expect(repo.usandoCache, isFalse);
      expect((await local.ler())!.produtos.single.id, 2);
    },
  );
  test('Escrita offline falha sem criar fila ou alterar catálogo; sucesso invalida saldo', () async {
    await local.substituir([produto(1)]);
    final api = ApiTeste([])..falhaEscrita = true;
    final repo = ProdutoRepository(api: api, local: local, auth: AuthTeste());
    await expectLater(
      repo.remover(id: 1),
      throwsA(isA<CatalogoIndisponivel>()),
    );
    expect((await local.ler())!.produtos.single.id, 1);
    api.falhaEscrita = false;
    await repo.remover(id: 1);
    expect(await local.ler(), isNull);
  });
}
