import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../models/produto.dart';
import '../api/api_config.dart';

class CatalogoSalvo {
  final List<Produto> produtos;
  final DateTime sincronizadoEm;
  const CatalogoSalvo(this.produtos, this.sincronizadoEm);
}

/// Cache de consulta. O PostgreSQL continua sendo a fonte oficial do estoque.
class CatalogoLocal {
  static final Map<String, Future<Database>> _bancos = {};
  final Database? bancoTeste;
  CatalogoLocal({this.bancoTeste});

  static Future<void> criarSchema(Database db) async {
    await criarFila(db);
    await db.execute(
      'CREATE TABLE produtos (id INTEGER PRIMARY KEY, eh_kit INTEGER NOT NULL, nome TEXT NOT NULL, preco REAL NOT NULL, descricao TEXT, categoria TEXT, status TEXT, estoque INTEGER, imagem_url TEXT, estoque_minimo INTEGER NOT NULL DEFAULT 5)',
    );
    await db.execute(
      'CREATE TABLE sincronizacao (id INTEGER PRIMARY KEY CHECK (id = 1), data TEXT NOT NULL)',
    );
  }

  static Future<void> criarFila(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS fila_estoque (id TEXT PRIMARY KEY, usuario INTEGER NOT NULL, produto INTEGER NOT NULL, nome TEXT NOT NULL, tipo TEXT NOT NULL, quantidade INTEGER NOT NULL CHECK(quantidade > 0), criada TEXT NOT NULL, estado TEXT NOT NULL DEFAULT "pendente", erro TEXT, tentada INTEGER NOT NULL DEFAULT 0, motivo TEXT NOT NULL DEFAULT "outro", observacao TEXT, estoque_esperado INTEGER, quantidade_contada INTEGER)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS fila_usuario ON fila_estoque(usuario, criada)',
    );
  }

  static Future<void> evoluirV3(Database db) async {
    for (final tabela in ['produtos', 'fila_estoque']) {
      final colunas = await db.rawQuery('PRAGMA table_info($tabela)');
      final novas = tabela == 'produtos'
          ? {'estoque_minimo': 'INTEGER NOT NULL DEFAULT 5'}
          : {
              'motivo': 'TEXT NOT NULL DEFAULT "outro"',
              'observacao': 'TEXT',
              'estoque_esperado': 'INTEGER',
              'quantidade_contada': 'INTEGER',
            };
      for (final coluna in novas.entries) {
        if (!colunas.any((c) => c['name'] == coluna.key)) {
          await db.execute(
            'ALTER TABLE $tabela ADD COLUMN ${coluna.key} ${coluna.value}',
          );
        }
      }
    }
  }

  Future<Database> get banco async {
    if (bancoTeste != null) return bancoTeste!;
    final origem = base64Url
        .encode(utf8.encode(ApiConfig.baseUrl))
        .replaceAll('=', '');
    return _bancos.putIfAbsent(
      origem,
      () async => openDatabase(
        path.join(await getDatabasesPath(), 'pim_catalogo_$origem.db'),
        version: 3,
        onUpgrade: (db, old, next) async {
          if (old < 2) await criarFila(db);
          if (old < 3) await evoluirV3(db);
        },
        onCreate: (db, version) => criarSchema(db),
      ),
    );
  }

  Future<DateTime> substituir(List<Produto> produtos) async {
    final db = await banco;
    final agora = DateTime.now().toUtc();
    await db.transaction((tx) async {
      await tx.delete('produtos');
      final batch = tx.batch();
      for (final p in produtos) {
        batch.insert('produtos', p.toLocalMap());
      }
      await batch.commit(noResult: true);
      await tx.insert('sincronizacao', {
        'id': 1,
        'data': agora.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
    return agora;
  }

  Future<CatalogoSalvo?> ler() async {
    final db = await banco;
    return db.transaction((tx) async {
      final info = await tx.query(
        'sincronizacao',
        where: 'id = ?',
        whereArgs: [1],
      );
      if (info.isEmpty) return null;
      final rows = await tx.query('produtos', orderBy: 'nome COLLATE NOCASE');
      return CatalogoSalvo(
        rows.map(Produto.fromLocalMap).toList(),
        DateTime.parse(info.first['data'] as String),
      );
    });
  }

  Future<void> invalidar() async {
    final db = await banco;
    await db.transaction((tx) async {
      await tx.delete('produtos');
      await tx.delete('sincronizacao');
    });
  }
}
