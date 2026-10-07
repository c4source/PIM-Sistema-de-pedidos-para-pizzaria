import 'package:flutter/material.dart';

import '../../models/produto.dart';
import '../../data/repositories/produto_repository.dart';

class ProdutoFormScreen extends StatefulWidget {
  final Produto? produto;

  const ProdutoFormScreen({super.key, this.produto});

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final ProdutoRepository _produtoRepository = ProdutoRepository();

  final _nomeController = TextEditingController();
  final _precoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _estoqueController = TextEditingController();
  final _imagemUrlController = TextEditingController();

  String _status = 'disponivel';
  bool _salvando = false;

  bool get _editando => widget.produto != null;

  @override
  void initState() {
    super.initState();

    final produto = widget.produto;

    if (produto != null) {
      _nomeController.text = produto.nome;
      _precoController.text = produto.preco.toString();
      _descricaoController.text = produto.descricao ?? '';
      _categoriaController.text = produto.categoria ?? '';
      _estoqueController.text = (produto.estoque ?? 0).toString();
      _imagemUrlController.text = produto.imagemUrl ?? '';
      _status = produto.status ?? 'disponivel';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    _descricaoController.dispose();
    _categoriaController.dispose();
    _estoqueController.dispose();
    _imagemUrlController.dispose();

    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      final preco = double.parse(_precoController.text.replaceAll(',', '.'));

      final estoque = int.parse(_estoqueController.text);

      if (_editando) {
        await _produtoRepository.atualizar(
          id: widget.produto!.id,
          nome: _nomeController.text.trim(),
          preco: preco,
          descricao: _descricaoController.text.trim(),
          categoria: _categoriaController.text.trim(),
          status: _status,
          estoque: estoque,
          imagemUrl: _imagemUrlController.text.trim(),
        );
      } else {
        await _produtoRepository.cadastrar(
          nome: _nomeController.text.trim(),
          preco: preco,
          descricao: _descricaoController.text.trim(),
          categoria: _categoriaController.text.trim(),
          status: _status,
          estoque: estoque,
          imagemUrl: _imagemUrlController.text.trim(),
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível cadastrar o produto.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar Produto' : 'Cadastrar Produto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Informe o nome';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _precoController,
                decoration: const InputDecoration(labelText: 'Preço'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (valor) {
                  final preco = double.tryParse(
                    valor?.replaceAll(',', '.') ?? '',
                  );

                  if (preco == null || preco <= 0) {
                    return 'Informe um preço válido';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _categoriaController,
                decoration: const InputDecoration(labelText: 'Categoria'),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _estoqueController,
                decoration: const InputDecoration(labelText: 'Estoque'),
                keyboardType: TextInputType.number,
                validator: (valor) {
                  final estoque = int.tryParse(valor ?? '');

                  if (estoque == null || estoque < 0) {
                    return 'Informe um estoque válido';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(
                    value: 'disponivel',
                    child: Text('Disponível'),
                  ),
                  DropdownMenuItem(
                    value: 'indisponivel',
                    child: Text('Indisponível'),
                  ),
                ],
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() {
                      _status = valor;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _imagemUrlController,
                decoration: const InputDecoration(labelText: 'URL da imagem'),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _salvando ? null : _salvar,
                  child: _salvando
                      ? const CircularProgressIndicator()
                      : Text(_editando ? 'Salvar alterações' : 'Cadastrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
