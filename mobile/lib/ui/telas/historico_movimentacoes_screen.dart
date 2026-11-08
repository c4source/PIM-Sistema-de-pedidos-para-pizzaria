import 'package:flutter/material.dart';

import '../../data/repositories/movimentacao_estoque_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/produto_repository.dart';
import '../../models/produto.dart';
import '../widgets/ajuste_estoque_dialog.dart';

class HistoricoMovimentacoesScreen extends StatefulWidget {
  final Map<String, String> filtrosIniciais;
  const HistoricoMovimentacoesScreen({
    super.key,
    this.filtrosIniciais = const {},
  });
  @override
  State<HistoricoMovimentacoesScreen> createState() =>
      _HistoricoMovimentacoesScreenState();
}

class _HistoricoMovimentacoesScreenState
    extends State<HistoricoMovimentacoesScreen> {
  final repo = MovimentacaoEstoqueRepository();
  List<Map<String, Object?>> locais = [];
  List<dynamic> remotos = [];
  bool carregando = false;
  String? erro;
  int pagina = 1;
  int total = 0;
  Map<String, String> filtros = {};
  List<Produto> produtos = [];
  List<dynamic> autores = [];
  String motivoTexto(Object? v) =>
      v == 'contagem' ? 'Contagem' : motivosEstoque[v] ?? 'Outro';
  Future<void> _filtrar() async {
    final token = await AuthRepository().obterToken();
    try {
      produtos = await ProdutoRepository().listar();
      if (token != null) autores = await repo.api.responsaveis(token);
    } catch (_) {
      /* Filtros por data/tipo continuam disponíveis. */
    }
    if (!mounted) return;
    final copia = Map<String, String>.from(filtros);
    final de = TextEditingController(text: copia['de'] ?? '');
    final ate = TextEditingController(text: copia['ate'] ?? '');
    String? falha;
    final sim = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setModal) => AlertDialog(
          title: const Text('Filtrar histórico'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: de,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'De',
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: c,
                      initialDate: DateTime.tryParse(de.text) ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) {
                      de.text = d.toIso8601String().substring(0, 10);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ate,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Até',
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: c,
                      initialDate:
                          DateTime.tryParse(ate.text) ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) {
                      ate.text = d.toIso8601String().substring(0, 10);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: copia['tipo'] ?? '',
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Todos')),
                    DropdownMenuItem(value: 'entrada', child: Text('Entradas')),
                    DropdownMenuItem(value: 'saida', child: Text('Saídas')),
                  ],
                  onChanged: (v) => copia['tipo'] = v!,
                ),
                const SizedBox(height: 12),
                if (produtos.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue:
                        produtos.any((p) => p.id.toString() == copia['produto'])
                        ? copia['produto']
                        : '',
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Produto'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Todos')),
                      ...produtos.map(
                        (p) => DropdownMenuItem(
                          value: p.id.toString(),
                          child: Text(p.nome, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => copia['produto'] = v!,
                  ),
                const SizedBox(height: 12),
                if (autores.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue:
                        autores.any((a) => a['id'].toString() == copia['autor'])
                        ? copia['autor']
                        : '',
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Responsável'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Todos')),
                      ...autores.map(
                        (a) => DropdownMenuItem(
                          value: a['id'].toString(),
                          child: Text(
                            a['nome'] as String,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => copia['autor'] = v!,
                  ),
                if (falha != null) Text(falha!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                copia.clear();
                de.clear();
                ate.clear();
                Navigator.pop(c, true);
              },
              child: const Text('Limpar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (de.text.isNotEmpty &&
                    ate.text.isNotEmpty &&
                    de.text.compareTo(ate.text) > 0) {
                  setModal(() {
                    falha = 'A data inicial deve ser anterior à final.';
                  });
                  return;
                }
                copia['de'] = de.text;
                copia['ate'] = ate.text;
                Navigator.pop(c, true);
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    de.dispose();
    ate.dispose();
    if (sim == true && mounted) {
      filtros = copia..removeWhere((k, v) => v.isEmpty);
      pagina = 1;
      await _carregar(sincronizar: false);
    }
  }

  @override
  void initState() {
    super.initState();
    filtros = Map<String, String>.from(widget.filtrosIniciais);
    repo.addListener(_mudou);
    _carregar();
  }

  @override
  void dispose() {
    repo.removeListener(_mudou);
    super.dispose();
  }

  void _mudou() {
    if (!repo.sincronizando) _carregar(sincronizar: false);
  }

  Future<void> _carregar({bool sincronizar = true}) async {
    if (carregando) return;
    setState(() {
      carregando = true;
      erro = null;
      remotos = [];
    });
    try {
      final fila = await repo.locais();
      if (mounted) {
        setState(() {
          locais = fila;
        });
      }
      if (sincronizar) {
        await repo.sincronizar();
        final atualizada = await repo.locais();
        if (mounted) {
          setState(() {
            locais = atualizada;
          });
        }
      }
      final token = await AuthRepository().obterToken();
      if (token == null) throw Exception();
      final data = await repo.api.listar(
        token,
        pagina: pagina,
        filtros: filtros,
      );
      if (mounted) {
        setState(() {
          remotos = data['itens'] as List;
          total = data['total'] as int;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          erro = 'Histórico do servidor indisponível. A fila local continua abaixo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  String data(Object? value) {
    final d = DateTime.tryParse(value.toString())?.toLocal();
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget movimento(
    String nome,
    String tipo,
    int quantidade,
    String detalhe,
    Color cor, {
    Widget? acoes,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: cor.withValues(alpha: .1),
                child: Icon(
                  tipo == 'entrada' ? Icons.south_west : Icons.north_east,
                  color: cor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nome,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                (tipo == 'entrada' ? '+' : '−') + quantidade.toString(),
                style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(detalhe),
          ?acoes,
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final fila = locais
        .where(
          (m) => m['estado'] != 'confirmada' && m['estado'] != 'descartada',
        )
        .toList();
    final confirmadas = locais
        .where((m) => m['estado'] == 'confirmada')
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimentações'),
        actions: [
          IconButton(
            tooltip: "Filtrar histórico",
            onPressed: carregando ? null : _filtrar,
            icon: const Icon(Icons.filter_alt_outlined),
          ),
          IconButton(
            onPressed: carregando ? null : () => _carregar(),
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _carregar(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Controle de estoque',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Os lançamentos aguardam a confirmação da API. Pendências pertencem à conta que as criou.',
            ),
            const SizedBox(height: 20),
            if (filtros.isNotEmpty)
              Text("Filtros ativos no histórico: ${filtros.length}"),
            if (carregando) const LinearProgressIndicator(),
            if (repo.aviso != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(repo.aviso!),
              ),
            Text(
              'Fila deste aparelho · ${fila.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (fila.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhuma movimentação pendente.'),
              ),
            for (final m in fila)
              movimento(
                m['nome'] as String,
                m['tipo'] as String,
                m['quantidade'] as int,
                '${m['estado'] == 'atencao' ? 'Requer atenção' : 'Pendente'} · ${data(m['criada'])} · ${motivoTexto(m['motivo'])}${m['observacao'] == null ? '' : ' · ${m['observacao']}'}${m['erro'] == null ? '' : ' · ${m['erro']}'}',
                m['estado'] == 'atencao' ? Colors.deepOrange : Colors.blueGrey,
                acoes: m['estado'] != 'atencao'
                    ? null
                    : Wrap(
                        children: [
                          if (m["estoque_esperado"] != null)
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                "Atualize o estoque, descarte esta contagem rejeitada e registre uma nova.",
                              ),
                            ),
                          TextButton(
                            onPressed:
                                repo.sincronizando ||
                                    m['estoque_esperado'] != null
                                ? null
                                : () => repo.resolver(
                                    m['id'] as String,
                                    descartar: false,
                                  ),
                            child: const Text('Tentar novamente'),
                          ),
                          TextButton(
                            onPressed: repo.sincronizando
                                ? null
                                : () async {
                                    final sim = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text(
                                          'Descartar lançamento rejeitado?',
                                        ),
                                        content: const Text(
                                          'Este lançamento não alterou o estoque no servidor.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(c, false),
                                            child: const Text('Voltar'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(c, true),
                                            child: const Text('Descartar'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (sim == true) {
                                      await repo.resolver(
                                        m['id'] as String,
                                        descartar: true,
                                      );
                                    }
                                  },
                            child: const Text('Descartar'),
                          ),
                        ],
                      ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Histórico do servidor',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            if (erro != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(erro!),
              ),
            for (final m in remotos)
              movimento(
                m['produto'] as String,
                m['tipo'] as String,
                m['quantidade'] as int,
                'Confirmada · ${m['colaborador'] as String} · ${data(m['dataHora'])} · ${motivoTexto(m['motivo'])}${m['observacao'] == null ? '' : ' · ${m['observacao']}'}',
                Colors.teal,
              ),
            if (erro != null && remotos.isEmpty && filtros.isEmpty)
              for (final m in confirmadas.reversed)
                movimento(
                  m['nome'] as String,
                  m['tipo'] as String,
                  m['quantidade'] as int,
                  'Confirmada pela API · ${data(m['criada'])}',
                  Colors.teal,
                ),
            if (remotos.isEmpty && erro == null && !carregando)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum lançamento registrado.'),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: pagina > 1 && !carregando
                      ? () {
                          pagina--;
                          _carregar(sincronizar: false);
                        }
                      : null,
                  child: const Text('Anterior'),
                ),
                Text('Página $pagina'),
                TextButton(
                  onPressed: pagina * 30 < total && !carregando
                      ? () {
                          pagina++;
                          _carregar(sincronizar: false);
                        }
                      : null,
                  child: const Text('Próxima'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
