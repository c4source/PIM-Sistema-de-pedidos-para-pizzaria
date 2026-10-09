import 'package:flutter/material.dart';

import '../../data/repositories/produto_repository.dart';
import '../../models/produto.dart';

class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  final ProdutoRepository _produtoRepository = ProdutoRepository();

  List<Produto> _produtos = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarEstoque();
  }

  Future<void> _carregarEstoque() async {
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
        _erro = 'Não foi possível carregar o estoque.';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque'),
      ),
      body: _construirConteudo(),
    );
  }

  Widget _construirConteudo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_erro != null) {
      return Center(
        child: Text(_erro!),
      );
    }

    if (_produtos.isEmpty) {
      return const Center(
        child: Text('Nenhum produto encontrado.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _produtos.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final produto = _produtos[index];
        final quantidade = produto.estoque ?? 0;

        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.inventory_2_outlined,
            ),
            title: Text(produto.nome),
            subtitle: Text(
              produto.categoria ?? 'Sem categoria',
            ),
            trailing: Text(
              '$quantidade un.',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}