import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:estoque_app/data/local/catalogo_local.dart';
import 'package:estoque_app/data/local/fila_estoque.dart';
import 'package:estoque_app/data/api/movimentacao_estoque_api.dart';
import 'package:estoque_app/data/repositories/movimentacao_estoque_repository.dart';

String token(int usuario, {bool expirado = false}) =>
    'teste.${base64Url.encode(utf8.encode(jsonEncode({'nameid': usuario.toString(), 'role': 'Administrador', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + (expirado ? -60 : 3600)})))}.teste';

class ApiTeste extends MovimentacaoEstoqueApi {
  final List<String> ids = [];
  final List<Map<String, Object?>> dados = [];
  final List<int> produtos = [];
  Exception? falha;
  int? rejeitarProduto;
  Completer<void>? esperar;
  @override
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
    dados.add({
      "motivo": motivo,
      "observacao": observacao,
      "esperado": estoqueEsperado,
      "contado": quantidadeContada,
    });
    ids.add(operacaoId);
    produtos.add(produtoId);
    if (esperar != null) await esperar!.future;
    if (falha != null) throw falha!;
    if (produtoId == rejeitarProduto) {
      throw FalhaMovimentacao(400, 'Estoque insuficiente.');
    }
  }
}

void main() {
  late Database db;
  late CatalogoLocal catalogo;
  late FilaEstoque fila;
  late ApiTeste api;
  late MovimentacaoEstoqueRepository repo;
  String? credencial;
  setUpAll(sqfliteFfiInit);
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await CatalogoLocal.criarSchema(db);
    catalogo = CatalogoLocal(bancoTeste: db);
    fila = FilaEstoque(local: catalogo);
    api = ApiTeste();
    credencial = token(7);
    repo = MovimentacaoEstoqueRepository.teste(
      api: api,
      fila: fila,
      token: () async => credencial,
    );
  });
  tearDown(() async {
    repo.dispose();
    await db.close();
  });
  test(
    'Timeout preserva operação; reenvio usa o mesmo ID e confirma uma vez',
    () async {
      api.falha = TimeoutException('Sem resposta');
      expect(
        await repo.registrar(produtoId: 1, tipo: 'entrada', quantidade: 2),
        false,
      );
      final id = api.ids.single;
      expect((await fila.listar(7)).single['estado'], 'pendente');
      api.falha = null;
      // Simula recriação do serviço após reiniciar o aplicativo.
      final reiniciado = MovimentacaoEstoqueRepository.teste(
        api: api,
        fila: fila,
        token: () async => credencial,
      );
      await reiniciado.sincronizar();
      await reiniciado.sincronizar();
      reiniciado.dispose();
      expect(api.ids, [id, id]);
      expect((await fila.listar(7)).single['estado'], 'confirmada');
    },
  );
  test('Troca de conta não envia nem exibe a fila do outro usuário', () async {
    api.falha = TimeoutException('Offline');
    await repo.registrar(produtoId: 1, tipo: 'saida', quantidade: 1);
    api.ids.clear();
    api.falha = null;
    credencial = token(8);
    await repo.sincronizar();
    expect(api.ids, isEmpty);
    expect(await repo.locais(), isEmpty);
    credencial = token(7);
    await repo.sincronizar();
    expect(api.ids, hasLength(1));
  });
  test('Saldo insuficiente bloqueia as seguintes do produto, mas permite outros produtos', () async {
    await fila.adicionar(7, 1, 'Pizza', 'saida', 99);
    await fila.adicionar(7, 1, 'Pizza', 'entrada', 2);
    await fila.adicionar(7, 2, 'Bebida', 'entrada', 3);
    api.rejeitarProduto = 1;
    await repo.sincronizar();
    expect(api.produtos, [1, 2]);
    expect((await fila.listar(7)).map((m) => m['estado']), [
      'atencao',
      'pendente',
      'confirmada',
    ]);
    final id = (await fila.listar(7)).first['id'] as String;
    api.rejeitarProduto = null;
    await repo.resolver(id, descartar: true);
    await repo.sincronizar();
    expect(api.produtos, [1, 2, 1]);
    expect((await fila.listar(7)).first['estado'], 'descartada');
  });
  test('Não permite descartar envio de resultado incerto', () async {
    api.falha = TimeoutException('Sem resposta');
    await repo.registrar(produtoId: 1, tipo: 'entrada', quantidade: 1);
    final id = (await fila.listar(7)).single['id'] as String;
    await repo.resolver(id, descartar: true);
    expect((await fila.listar(7)).single['estado'], 'pendente');
  });
  test('401 pausa; somente nova credencial retoma a mesma fila', () async {
    api.falha = FalhaMovimentacao(401, 'Sessão expirada');
    await repo.registrar(produtoId: 1, tipo: 'entrada', quantidade: 1);
    await repo.sincronizar();
    expect(api.ids, hasLength(1));
    api.falha = null;
    credencial = '${token(7)}nova';
    await repo.sincronizar();
    expect(api.ids, hasLength(2));
    expect((await fila.listar(7)).single['estado'], 'confirmada');
  });
  test(
    'Token expirado preserva a fila e não permite novos lançamentos',
    () async {
      await fila.adicionar(7, 1, 'Pizza', 'entrada', 1);
      credencial = token(7, expirado: true);
      await repo.sincronizar();
      expect(api.ids, isEmpty);
      await expectLater(
        repo.registrar(produtoId: 1, tipo: 'entrada', quantidade: 1),
        throwsException,
      );
      expect(await fila.listar(7), hasLength(1));
    },
  );
  test('Chamadas simultâneas não enviam duas vezes a mesma operação', () async {
    await fila.adicionar(7, 1, 'Pizza', 'entrada', 1);
    api.esperar = Completer<void>();
    final primeira = repo.sincronizar();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await repo.sincronizar();
    api.esperar!.complete();
    await primeira;
    expect(api.ids, hasLength(1));
  });
  test('Erro 500 mantém pendente em vez de rejeitar', () async {
    api.falha = FalhaMovimentacao(500, 'Indisponível');
    await repo.registrar(produtoId: 1, tipo: 'entrada', quantidade: 1);
    expect((await fila.listar(7)).single['estado'], 'pendente');
  });
  test(
    'Migração SQLite v1 preserva catálogo e cria fila persistente',
    () async {
      final pasta = await Directory.systemTemp.createTemp('pim_fila_');
      final arquivo = '${pasta.path}/teste.db';
      var disco = await databaseFactoryFfi.openDatabase(
        arquivo,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (d, v) async {
            await d.execute(
              'CREATE TABLE produtos (id INTEGER PRIMARY KEY, nome TEXT)',
            );
            await d.insert('produtos', {'id': 1, 'nome': 'Pizza'});
          },
        ),
      );
      await disco.close();
      disco = await databaseFactoryFfi.openDatabase(
        arquivo,
        options: OpenDatabaseOptions(
          version: 2,
          onUpgrade: (d, a, b) => CatalogoLocal.criarFila(d),
        ),
      );
      final id = await FilaEstoque(local: CatalogoLocal(bancoTeste: disco))
          .adicionar(7, 1, 'Pizza', 'entrada', 1);
      expect((await disco.query('produtos')).single['nome'], 'Pizza');
      await disco.close();
      disco = await databaseFactoryFfi.openDatabase(arquivo);
      expect(
        (await FilaEstoque(local: CatalogoLocal(bancoTeste: disco)).listar(7))
            .single['id'],
        id,
      );
      await disco.close();
      await pasta.delete(recursive: true);
    },
  );
  test(
    'Contagem offline preserva referência, motivo e observação no reenvio',
    () async {
      api.falha = TimeoutException('Offline');
      await repo.registrar(
        produtoId: 1,
        tipo: 'saida',
        quantidade: 2,
        motivo: 'contagem',
        observacao: '  Contagem física  ',
        estoqueEsperado: 6,
        quantidadeContada: 4,
      );
      expect((await fila.listar(7)).single['estoque_esperado'], 6);
      api.falha = null;
      await repo.sincronizar();
      expect(api.dados.last, {
        'motivo': 'contagem',
        'observacao': 'Contagem física',
        'esperado': 6,
        'contado': 4,
      });
    },
  );
  test(
    'Upgrade v2-v3 preserva pendências antigas e usa motivo padrão',
    () async {
      final antigo = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await antigo.execute(
        'CREATE TABLE produtos (id INTEGER PRIMARY KEY, nome TEXT)',
      );
      await antigo.execute(
        'CREATE TABLE fila_estoque (id TEXT PRIMARY KEY, usuario INTEGER, produto INTEGER, nome TEXT, tipo TEXT, quantidade INTEGER, criada TEXT, estado TEXT, erro TEXT, tentada INTEGER)',
      );
      await antigo.insert('produtos', {'id': 1, 'nome': 'Pizza'});
      await antigo.insert('fila_estoque', {
        'id': 'legado',
        'usuario': 7,
        'produto': 1,
        'nome': 'Pizza',
        'tipo': 'entrada',
        'quantidade': 2,
        'criada': '2026-10-31',
        'estado': 'pendente',
        'tentada': 0,
      });
      await CatalogoLocal.evoluirV3(antigo);
      final m = (await FilaEstoque(
        local: CatalogoLocal(bancoTeste: antigo),
      ).listar(7)).single;
      expect(m['id'], 'legado');
      expect(m['motivo'], 'outro');
      expect(m['estoque_esperado'], isNull);
      expect((await antigo.query('produtos')).single['estoque_minimo'], 5);
      await antigo.close();
    },
  );
}
