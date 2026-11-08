import 'package:flutter/material.dart';

import '../../data/repositories/movimentacao_estoque_repository.dart';
import '../../data/repositories/produto_repository.dart';
import '../../models/produto.dart';
import '../widgets/ajuste_estoque_dialog.dart';

class MovimentacaoEstoqueScreen extends StatefulWidget {
  final String tipo;

  const MovimentacaoEstoqueScreen({super.key, required this.tipo});

  @override
  State<MovimentacaoEstoqueScreen> createState() =>
      _MovimentacaoEstoqueScreenState();
}

class _MovimentacaoEstoqueScreenState extends State<MovimentacaoEstoqueScreen> {
  final ProdutoRepository _produtoRepository = ProdutoRepository();
  final TextEditingController _quantidadeController = TextEditingController();
  final MovimentacaoEstoqueRepository _movimentacaoRepository =
      MovimentacaoEstoqueRepository();

  List<Produto> _produtos = [];
  int? _produtoSelecionadoId;

  bool _carregando = true;
  bool _salvando = false;
  String? _erro;
  String _motivo = "outro";
  final _observacao = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    try {
      final produtos = (await _produtoRepository.listar())
          .where((produto) => !produto.ehKit)
          .toList();

      if (!mounted) return;

      setState(() {
        _produtos = produtos;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar os produtos.';
        _carregando = false;
      });
    }
  }

  Future<void> _registrarMovimentacao() async {
    final produtoId = _produtoSelecionadoId;
    final quantidade = int.tryParse(_quantidadeController.text.trim());

    if (produtoId == null ||
        quantidade == null ||
        quantidade <= 0 ||
        quantidade > 2147483647) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione um produto e informe uma quantidade válida.',
          ),
        ),
      );
      return;
    }

    if (widget.tipo == "saida" && quantidade >= 10) {
      final sim = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text("Confirmar saída?"),
          content: Text("Retirar $quantidade unidades?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text("Voltar"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text("Confirmar"),
            ),
          ],
        ),
      );
      if (sim != true || !mounted) return;
    }
    setState(() {
      _salvando = true;
    });

    try {
      final confirmada = await _movimentacaoRepository.registrar(
        produtoId: produtoId,
        nome: _produtos.firstWhere((p) => p.id == produtoId).nome,
        tipo: widget.tipo,
        motivo: _motivo,
        observacao: _observacao.text,
        quantidade: quantidade,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            confirmada
                ? 'Movimentação confirmada!'
                : 'Movimentação salva. Acompanhe o envio em Movimentações.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      final mensagem = e.toString().contains('Estoque insuficiente')
          ? 'Estoque insuficiente! A quantidade solicitada é maior que a disponível.'
          : 'Não foi possível registrar a movimentação.';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagem)));
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _observacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tipo == 'entrada' ? 'Entrada de Estoque' : 'Saída de Estoque',
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _erro != null
            ? Center(child: Text(_erro!))
            : _produtos.isEmpty
            ? const Center(child: Text('Nenhum produto encontrado.'))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Text(
                        'Sem conexão, o lançamento fica na fila deste aparelho. O saldo oficial só muda após confirmação do servidor.',
                      ),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: _produtoSelecionadoId,
                      isExpanded: true,

                      decoration: const InputDecoration(
                        labelText: 'Selecione o produto',
                        border: OutlineInputBorder(),
                      ),

                      items: _produtos.map((produto) {
                        return DropdownMenuItem<int>(
                          value: produto.id,
                          child: Text(
                            produto.nome,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),

                      onChanged: (id) {
                        setState(() {
                          _produtoSelecionadoId = id;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _quantidadeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _motivo,
                      decoration: const InputDecoration(labelText: 'Motivo'),
                      items: motivosEstoque.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: _salvando ? null : (v) => _motivo = v!,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _observacao,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Observação (opcional)',
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _salvando ? null : _registrarMovimentacao,

                      child: _salvando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.tipo == 'entrada'
                                  ? 'Registrar Entrada'
                                  : 'Registrar Saída',
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
