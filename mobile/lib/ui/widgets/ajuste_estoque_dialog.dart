import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/produto.dart';
import '../../data/repositories/movimentacao_estoque_repository.dart';

const motivosEstoque = {
  'reposicao': 'Reposição',
  'perda': 'Perda',
  'consumo_interno': 'Consumo interno',
  'correcao': 'Correção',
  'outro': 'Outro',
};

class AjusteEstoqueDialog extends StatefulWidget {
  final Produto produto;
  final bool temPendencias;
  const AjusteEstoqueDialog({
    super.key,
    required this.produto,
    this.temPendencias = false,
  });
  @override
  State<AjusteEstoqueDialog> createState() => _AjusteEstoqueDialogState();
}

class _AjusteEstoqueDialogState extends State<AjusteEstoqueDialog> {
  final quantidade = TextEditingController();
  final observacao = TextEditingController();
  String tipo = 'entrada', motivo = 'reposicao';
  bool salvando = false;
  String? erro;
  @override
  void dispose() {
    quantidade.dispose();
    observacao.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    final n = int.tryParse(quantidade.text.trim());
    final saldo = widget.produto.estoque ?? 0;
    if (n == null || n < (tipo == 'contagem' ? 0 : 1) || n > 2147483647) {
      setState(() {
        erro = 'Informe uma quantidade inteira válida.';
      });
      return;
    }
    if (tipo == 'contagem' && widget.temPendencias) {
      setState(() {
        erro = 'Resolva as pendências deste produto antes de registrar a contagem.';
      });
      return;
    }
    final delta = tipo == 'contagem'
        ? n - saldo
        : tipo == 'entrada'
        ? n
        : -n;
    if (delta == 0) {
      setState(() {
        erro = 'A contagem coincide com o último saldo recebido. Nenhum ajuste é necessário.';
      });
      return;
    }
    if (tipo == 'contagem' || delta < 0 && delta.abs() >= 10) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Confirmar ajuste?'),
          content: Text(
            'Produto: ${widget.produto.nome}. ${tipo == 'contagem' ? 'Saldo de referência: $saldo. Contado: $n. Se o saldo mudar, o ajuste será rejeitado.' : 'Retirar $n unidades?'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;
    }
    setState(() {
      salvando = true;
      erro = null;
    });
    try {
      final confirmado = await MovimentacaoEstoqueRepository().registrar(
        produtoId: widget.produto.id,
        nome: widget.produto.nome,
        tipo: delta > 0 ? 'entrada' : 'saida',
        quantidade: delta.abs(),
        motivo: tipo == 'contagem' ? 'contagem' : motivo,
        observacao: observacao.text,
        estoqueEsperado: tipo == 'contagem' ? saldo : null,
        quantidadeContada: tipo == 'contagem' ? n : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              confirmado
                  ? 'Ajuste confirmado!'
                  : 'Ajuste salvo. Acompanhe o resultado em Movimentações.',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          salvando = false;
          erro =
              'Não foi possível salvar. Confira sua sessão e tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !salvando,
    child: AlertDialog(
      title: Text(widget.produto.nome),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Último saldo recebido: ${widget.produto.estoque ?? 0} un.'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: tipo,
              decoration: const InputDecoration(labelText: 'Ação'),
              items: const [
                DropdownMenuItem(value: 'entrada', child: Text('Entrada')),
                DropdownMenuItem(value: 'saida', child: Text('Saída')),
                DropdownMenuItem(
                  value: 'contagem',
                  child: Text(
                    'Contagem de inventário',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: salvando
                  ? null
                  : (v) => setState(() {
                      tipo = v!;
                      erro = null;
                    }),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: quantidade,
              enabled: !salvando,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: tipo == 'contagem'
                    ? 'Quantidade contada'
                    : 'Quantidade',
              ),
            ),
            const SizedBox(height: 14),
            if (tipo != 'contagem')
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: motivo,
                decoration: const InputDecoration(labelText: 'Motivo'),
                items: motivosEstoque.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: salvando ? null : (v) => motivo = v!,
              ),
            const SizedBox(height: 14),
            TextField(
              controller: observacao,
              enabled: !salvando,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observação (opcional)',
              ),
            ),
            const Text(
              'Sem conexão, o ajuste fica na fila. Contagens só são aplicadas se o saldo de referência continuar igual.',
              style: TextStyle(fontSize: 12),
            ),
            if (erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  erro!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: salvando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: salvando ? null : salvar,
          child: Text(salvando ? 'Salvando...' : 'Salvar ajuste'),
        ),
      ],
    ),
  );
}
