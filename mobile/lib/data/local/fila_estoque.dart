import 'dart:math';

import 'catalogo_local.dart';

class FilaEstoque {
  final CatalogoLocal catalogo;
  FilaEstoque({CatalogoLocal? local}) : catalogo = local ?? CatalogoLocal();
  static String novoId() {
    final random = Random.secure();
    final b = List.generate(16, (_) => random.nextInt(256));
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return [
      h.substring(0, 8),
      h.substring(8, 12),
      h.substring(12, 16),
      h.substring(16, 20),
      h.substring(20),
    ].join('-');
  }

  Future<String> adicionar(
    int usuario,
    int produto,
    String nome,
    String tipo,
    int quantidade, {
    String motivo = "outro",
    String? observacao,
    int? estoqueEsperado,
    int? quantidadeContada,
  }) async {
    if (usuario <= 0 ||
        produto <= 0 ||
        quantidade <= 0 ||
        quantidade > 2147483647 ||
        !['entrada', 'saida'].contains(tipo)) {
      throw ArgumentError('Movimentação inválida.');
    }
    final id = novoId();
    await (await catalogo.banco).insert('fila_estoque', {
      'id': id,
      'usuario': usuario,
      'produto': produto,
      'nome': nome,
      'tipo': tipo,
      'quantidade': quantidade,
      'motivo': motivo,
      'observacao': observacao?.trim().isEmpty == true
          ? null
          : observacao?.trim(),
      'estoque_esperado': estoqueEsperado,
      'quantidade_contada': quantidadeContada,
      'criada': DateTime.now().toUtc().toIso8601String(),
      'estado': 'pendente',
    });
    return id;
  }

  Future<List<Map<String, Object?>>> listar(int usuario) async =>
      (await catalogo.banco).query(
        'fila_estoque',
        where: 'usuario = ?',
        whereArgs: [usuario],
        orderBy: 'rowid',
      );
  Future<void> atualizar(
    String id,
    int usuario,
    Map<String, Object?> dados,
  ) async {
    await (await catalogo.banco).update(
      'fila_estoque',
      dados,
      where: 'id = ? AND usuario = ?',
      whereArgs: [id, usuario],
    );
  }

  Future<void> resolver(
    String id,
    int usuario, {
    required bool descartar,
  }) async {
    // Só rejeições explícitas podem ser descartadas: uma tentativa sem resposta
    // pode já ter sido confirmada no servidor e deve manter o mesmo ID.
    await (await catalogo.banco).update(
      'fila_estoque',
      {'estado': descartar ? 'descartada' : 'pendente', 'erro': null},
      where: 'id = ? AND usuario = ? AND estado = ?',
      whereArgs: [id, usuario, 'atencao'],
    );
  }
}
