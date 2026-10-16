import 'package:flutter/material.dart';

import 'produto_form_screen.dart';
import '../../data/repositories/produto_repository.dart';
import '../../models/produto.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  final ProdutoRepository _produtoRepository = ProdutoRepository();

  List<Produto> _produtos = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final produtos = await _produtoRepository.listar();

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

  Future<void> _abrirCadastro() async {
    final cadastrou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const ProdutoFormScreen()),
    );

    if (cadastrou == true) {
      await _carregarProdutos();
    }
  }

  Future<void> _abrirEdicao(Produto produto) async {
    final atualizou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProdutoFormScreen(produto: produto),
      ),
    );

    if (atualizou == true) {
      await _carregarProdutos();
    }
  }

  Future<void> _removerProduto(Produto produto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir produto'),
          content: Text('Deseja realmente excluir "${produto.nome}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await _produtoRepository.remover(id: produto.id);

      if (!mounted) return;

      await _carregarProdutos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto excluído com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o produto.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos')),

      body: _construirConteudo(),

      floatingActionButton: FloatingActionButton(
        onPressed: _abrirCadastro,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _construirConteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Center(child: Text(_erro!));
    }

    if (_produtos.isEmpty) {
      return const Center(child: Text('Nenhum produto cadastrado.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _produtos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final produto = _produtos[index];

        return Card(
          child: ListTile(
            onTap: () {
              _abrirEdicao(produto);
            },
            title: Text(produto.nome),
            subtitle: Text(
              'R\$ ${produto.preco.toStringAsFixed(2)}'
              ' • Estoque: ${produto.estoque ?? 0}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                _removerProduto(produto);
              },
            ),
          ),
        );
      },
    );
  }
}
