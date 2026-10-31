import 'package:flutter/material.dart';

import '../widgets/status_catalogo.dart';
import '../widgets/ajuste_estoque_dialog.dart';
import '../../data/api/estoque_configuracao_api.dart';
import '../../data/repositories/movimentacao_estoque_repository.dart';
import '../../core/rotas.dart';
import '../../core/busca.dart';

import 'movimentacao_estoque_screen.dart';
import '../../data/repositories/produto_repository.dart';
import '../../models/produto.dart';

class EstoqueScreen extends StatefulWidget {
  final String saldoInicial;
  const EstoqueScreen({super.key, this.saldoInicial = "Todos"});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  final ProdutoRepository _produtoRepository = ProdutoRepository();

  List<Produto> _produtos = [];
  List<Map<String, Object?>> _fila = [];
  final _movimentos = MovimentacaoEstoqueRepository();
  @override
  void dispose() {
    _movimentos.removeListener(_mudou);
    super.dispose();
  }

  int _revisao = -1;
  void _mudou() {
    if (!mounted ||
        _movimentos.sincronizando ||
        _revisao == _movimentos.revisao) {
      return;
    }
    _revisao = _movimentos.revisao;
    if (!_carregando) _carregarEstoque();
  }

  String _busca = '', _categoria = 'Todas', _saldo = 'Todos';
  Future<void> _ajustar(Produto p) async {
    final salvo = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AjusteEstoqueDialog(
        produto: p,
        temPendencias: _fila.any(
          (m) =>
              m['produto'] == p.id &&
              ['pendente', 'atencao'].contains(m['estado']),
        ),
      ),
    );
    if (salvo == true && mounted) await _carregarEstoque();
  }

  Future<void> _limite(Produto p) async {
    int valor = p.estoqueMinimo;
    final form = GlobalKey<FormState>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Alerta de estoque baixo'),
        content: Form(
          key: form,
          child: TextFormField(
            initialValue: valor.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantidade mínima',
              helperText:
                  'Requer conexão. Zero desativa o alerta de saldo baixo.',
            ),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n < 0 || n > 2147483647) {
                return 'Informe um número inteiro positivo ou zero.';
              }
              valor = n;
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(c, true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await EstoqueConfiguracaoApi().definirLimite(p.id, valor);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Alerta atualizado.')));
        await _carregarEstoque();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar o alerta. Esta configuração exige conexão.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _opcoesFiltros() async {
    var categoria = _categoria, saldo = _saldo;
    final aplicar = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Filtrar estoque'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: categoria,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items:
                    [
                          'Todas',
                          ..._produtos
                              .map((p) => p.categoria)
                              .whereType<String>()
                              .toSet(),
                        ]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                onChanged: (v) => categoria = v!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: saldo,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Saldo'),
                items: ['Todos', 'Estoque baixo', 'Zerados']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => saldo = v!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              categoria = 'Todas';
              saldo = 'Todos';
              Navigator.pop(c, true);
            },
            child: const Text('Limpar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    if (aplicar == true && mounted) {
      setState(() {
        _categoria = categoria;
        _saldo = saldo;
      });
    }
  }

  Widget _filtros() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar produto',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() {
              _busca = v;
            }),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: _categoria == 'Todas' && _saldo == 'Todos'
              ? 'Filtrar estoque'
              : 'Filtros ativos: $_categoria, $_saldo',
          onPressed: _opcoesFiltros,
          icon: Icon(
            _categoria == 'Todas' && _saldo == 'Todos'
                ? Icons.filter_alt_outlined
                : Icons.filter_alt,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    ),
  );
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _saldo = ["Todos", "Estoque baixo", "Zerados"].contains(widget.saldoInicial)
        ? widget.saldoInicial
        : "Todos";
    _movimentos.addListener(_mudou);
    _carregarEstoque();
  }

  Future<void> _carregarEstoque() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await _movimentos.sincronizar();
      final produtos = await _produtoRepository.listar();
      final fila = await _movimentos.locais();

      if (!mounted) return;

      setState(() {
        _produtos = produtos;
        _fila = fila;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Registrar entrada',
            onPressed: _carregando
                ? null
                : () async {
                    final registrada = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) =>
                            const MovimentacaoEstoqueScreen(tipo: 'entrada'),
                      ),
                    );

                    if (registrada == true && mounted) {
                      await _carregarEstoque();
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: 'Registrar saída',
            onPressed: () async {
              final registrada = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) =>
                      const MovimentacaoEstoqueScreen(tipo: 'saida'),
                ),
              );

              if (registrada == true && mounted) {
                await _carregarEstoque();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          StatusCatalogo(
            assunto: 'Estoque',
            pendentes: _fila.where((m) => m['estado'] == 'pendente').length,
            atencao: _fila.where((m) => m['estado'] == 'atencao').length,
            abrirFila: () => Navigator.pushNamed(context, Rotas.movimentacoes),
            falhaConsulta: _erro != null,
            local: _produtoRepository.usandoCache,
            carregando: _carregando,
            falhaCache: _produtoRepository.falhaCache,
            atualizadoEm: _produtoRepository.ultimaSincronizacao,
            sincronizar: _carregarEstoque,
          ),
          _filtros(),
          Expanded(child: _construirConteudo()),
        ],
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
      return const Center(child: Text('Nenhum produto encontrado.'));
    }

    final filtrados = _produtos
        .where(
          (p) =>
              normalizarBusca(p.nome)
                  .contains(normalizarBusca(_busca.trim())) &&
              (_categoria == 'Todas' || p.categoria == _categoria) &&
              (_saldo == 'Todos' ||
                  _saldo == 'Zerados' && (p.estoque ?? 0) == 0 ||
                  _saldo == 'Estoque baixo' &&
                      !p.ehKit &&
                      (p.estoque ?? 0) > 0 &&
                      (p.estoque ?? 0) <= p.estoqueMinimo),
        )
        .toList();
    if (filtrados.isEmpty) {
      return const Center(child: Text('Nenhum produto para estes filtros.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtrados.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final produto = filtrados[index];
        final quantidade = produto.estoque ?? 0;

        final pendentes = _fila
            .where(
              (m) => m['produto'] == produto.id && m['estado'] == 'pendente',
            )
            .toList();
        final delta = pendentes.fold<int>(
          0,
          (s, m) =>
              s +
              (m['tipo'] == 'entrada'
                  ? m['quantidade'] as int
                  : -(m['quantidade'] as int)),
        );
        return Card(
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(produto.nome),
            onTap: produto.ehKit ? null : () => _ajustar(produto),
            subtitle: pendentes.isNotEmpty
                ? Text(
                    'Estimativa com pendências: ${quantidade + delta} un. (sujeita à confirmação)',
                  )
                : _fila.any(
                    (m) =>
                        m['produto'] == produto.id && m['estado'] == 'atencao',
                  )
                ? const Text(
                    'Movimentação requer atenção',
                    style: TextStyle(color: Color(0xff8a5900)),
                  )
                : produto.ehKit
                ? const Text('Calculado pelos componentes')
                : !produto.ehKit && quantidade <= produto.estoqueMinimo
                ? Text(
                    quantidade == 0 ? 'Sem estoque' : 'Estoque baixo',
                    style: const TextStyle(color: Color(0xff8a5900)),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  produto.ehKit ? '$quantidade kits' : '$quantidade un.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!produto.ehKit)
                  PopupMenuButton<String>(
                    tooltip: 'Ações do produto',
                    onSelected: (v) =>
                        v == 'ajustar' ? _ajustar(produto) : _limite(produto),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'ajustar',
                        child: Text('Ajustar estoque'),
                      ),
                      PopupMenuItem(
                        value: 'limite',
                        child: Text('Configurar alerta'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
