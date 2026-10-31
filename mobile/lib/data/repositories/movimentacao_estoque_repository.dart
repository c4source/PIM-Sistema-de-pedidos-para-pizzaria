import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api/movimentacao_estoque_api.dart';
import '../local/fila_estoque.dart';
import 'auth_repository.dart';

Map<String, dynamic>? dadosSessao(String? token) {
  try {
    final p = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(token!.split('.')[1]))),
    ) as Map<String, dynamic>;
    if ((p['exp'] as num) * 1000 <= DateTime.now().millisecondsSinceEpoch) {
      return null;
    }
    return p;
  } catch (_) {
    return null;
  }
}

int? usuarioSessao(String? token) {
  final p = dadosSessao(token);
  return int.tryParse(
    (p?['nameid'] ??
            p?['sub'] ??
            p?['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
            '')
        .toString(),
  );
}

bool administradorSessao(String? token) {
  final p = dadosSessao(token);
  return (p?['role'] ??
          p?['http://schemas.microsoft.com/ws/2008/06/identity/claims/role']) ==
      'Administrador';
}

class MovimentacaoEstoqueRepository extends ChangeNotifier {
  static final _instancia = MovimentacaoEstoqueRepository.teste();
  factory MovimentacaoEstoqueRepository() => _instancia;
  final MovimentacaoEstoqueApi api;
  final FilaEstoque fila;
  final Future<String?> Function() obterToken;
  bool sincronizando = false;
  int revisao = 0;
  String? aviso;
  String? _tokenBloqueado;
  MovimentacaoEstoqueRepository.teste({
    MovimentacaoEstoqueApi? api,
    FilaEstoque? fila,
    Future<String?> Function()? token,
  }) : api = api ?? MovimentacaoEstoqueApi(),
       fila = fila ?? FilaEstoque(),
       obterToken = token ?? AuthRepository().obterToken;

  Future<List<Map<String, Object?>>> locais() async {
    final usuario = usuarioSessao(await obterToken());
    return usuario == null ? [] : fila.listar(usuario);
  }

  Future<bool> registrar({
    required int produtoId,
    required String tipo,
    required int quantidade,
    String? nome,
    String motivo = "outro",
    String? observacao,
    int? estoqueEsperado,
    int? quantidadeContada,
  }) async {
    final credencial = await obterToken();
    final usuario = usuarioSessao(credencial);
    if (usuario == null || credencial == _tokenBloqueado) {
      throw Exception('Entre novamente para registrar movimentações.');
    }
    final id = await fila.adicionar(
      usuario,
      produtoId,
      nome ?? 'Produto $produtoId',
      tipo,
      quantidade,
      motivo: motivo,
      observacao: observacao,
      estoqueEsperado: estoqueEsperado,
      quantidadeContada: quantidadeContada,
    );
    revisao++;
    notifyListeners();
    await sincronizar();
    final itens = await fila.listar(usuario);
    return itens.firstWhere((m) => m['id'] == id)['estado'] == 'confirmada';
  }

  Future<void> sincronizar() async {
    if (sincronizando) return;
    sincronizando = true;
    aviso = null;
    notifyListeners();
    try {
      final credencial = await obterToken();
      if (credencial != null && credencial == _tokenBloqueado) {
        aviso = "Entre novamente para retomar os envios.";
        return;
      }
      final usuario = usuarioSessao(credencial);
      if (usuario == null) {
        aviso = 'Entre para sincronizar as pendências da sua conta.';
        return;
      }
      final bloqueados = <int>{};
      for (final m in await fila.listar(usuario)) {
        final produto = m['produto'] as int;
        if (m['estado'] == 'atencao') {
          bloqueados.add(produto);
          continue;
        }
        if (m['estado'] != 'pendente' || bloqueados.contains(produto)) continue;
        // Lê de novo a credencial a cada envio: logout/troca de conta interrompe a fila.
        final token = await obterToken();
        if (usuarioSessao(token) != usuario) break;
        await fila.atualizar(m['id'] as String, usuario, {'tentada': 1});
        try {
          await api.registrar(
            produtoId: produto,
            tipo: m['tipo'] as String,
            quantidade: m['quantidade'] as int,
            token: token!,
            operacaoId: m['id'] as String,
            motivo: m['motivo'] as String? ?? 'outro',
            observacao: m['observacao'] as String?,
            estoqueEsperado: m['estoque_esperado'] as int?,
            quantidadeContada: m['quantidade_contada'] as int?,
          );
          await fila.atualizar(m['id'] as String, usuario, {
            'estado': 'confirmada',
            'erro': null,
          });
          revisao++;
        } on FalhaMovimentacao catch (e) {
          aviso = e.mensagem;
          if (e.status == 401 || e.status == 403) _tokenBloqueado = token;
          if (e.status == 401 ||
              e.status == 403 ||
              e.status >= 500 ||
              e.status == 408 ||
              e.status == 429) {
            break;
          }
          await fila.atualizar(m['id'] as String, usuario, {
            'estado': 'atencao',
            'erro': e.mensagem,
          });
          revisao++;
          bloqueados.add(produto);
        } catch (_) {
          aviso = 'Sem resposta do servidor. Pendências salvas neste aparelho.';
          break;
        }
      }
    } catch (_) {
      aviso = 'Não foi possível sincronizar. As pendências foram preservadas.';
    } finally {
      sincronizando = false;
      notifyListeners();
    }
  }

  Future<void> resolver(String id, {required bool descartar}) async {
    final usuario = usuarioSessao(await obterToken());
    if (usuario == null || sincronizando) return;
    await fila.resolver(id, usuario, descartar: descartar);
    revisao++;
    notifyListeners();
    if (!descartar) await sincronizar();
  }
}
