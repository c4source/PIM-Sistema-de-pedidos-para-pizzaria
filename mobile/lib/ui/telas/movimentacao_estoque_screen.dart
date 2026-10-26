import 'package:flutter/material.dart';

import '../../data/repositories/movimentacao_estoque_repository.dart';
import '../../data/repositories/produto_repository.dart';
import '../../models/produto.dart';

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

    if (produtoId == null || quantidade == null || quantidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione um produto e informe uma quantidade válida.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      await _movimentacaoRepository.registrar(
        produtoId: produtoId,
        tipo: widget.tipo,
        quantidade: quantidade,
      );

      if (!mounted) return;

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
            : Column(
                children: [
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
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _salvando ? null : _registrarMovimentacao,

                    child: _salvando
                        ? const CircularProgressIndicator()
                        : Text(
                            widget.tipo == 'entrada'
                                ? 'Registrar Entrada'
                                : 'Registrar Saída',
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
