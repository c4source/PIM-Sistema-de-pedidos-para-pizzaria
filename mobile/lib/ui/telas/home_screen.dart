import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/movimentacao_estoque_repository.dart';
import '../../core/rotas.dart';
import '../../data/repositories/produto_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool admin = false;
  int pendentes = 0, zerados = 0, baixos = 0;
  int? movimentosHoje;
  String resumoOrigem = "Carregando resumo...";
  final repo = MovimentacaoEstoqueRepository();
  @override
  void initState() {
    super.initState();
    repo.addListener(_atualizar);
    _atualizar();
    _resumo();
    repo.sincronizar();
  }

  @override
  void dispose() {
    repo.removeListener(_atualizar);
    super.dispose();
  }

  Future<void> _atualizar() async {
    final token = await AuthRepository().obterToken();
    final fila = await repo.locais();
    if (mounted) {
      setState(() {
        admin = administradorSessao(token);
        pendentes = fila
            .where((m) => m['estado'] == 'pendente' || m['estado'] == 'atencao')
            .length;
      });
    }
  }

  bool _carregandoResumo = false;
  Future<void> _resumo() async {
    if (_carregandoResumo) return;
    _carregandoResumo = true;
    if (mounted) {
      setState(() {
        movimentosHoje = null;
      });
    }
    try {
      final produtos = ProdutoRepository();
      final dados = await produtos.listar();
      if (mounted) {
        setState(() {
          zerados = dados.where((p) => (p.estoque ?? 0) == 0).length;
          baixos = dados
              .where(
                (p) =>
                    !p.ehKit &&
                    (p.estoque ?? 0) > 0 &&
                    (p.estoque ?? 0) <= p.estoqueMinimo,
              )
              .length;
          resumoOrigem = produtos.usandoCache
              ? 'Resumo do último saldo salvo'
              : 'Resumo do estoque atualizado';
        });
      }
      final token = await AuthRepository().obterToken();
      if (token != null) {
        final hoje = DateTime.now().toIso8601String().substring(0, 10);
        final h = await repo.api.listar(
          token,
          filtros: {'de': hoje, 'ate': hoje},
        );
        if (mounted) {
          setState(() {
            movimentosHoje = h['total'] as int;
          });
        }
      }
    } catch (_) {
      if (mounted && resumoOrigem == 'Carregando resumo...') {
        setState(() {
          resumoOrigem = 'Conecte-se para obter o resumo';
        });
      }
    } finally {
      _carregandoResumo = false;
    }
  }

  Future<void> _sair() async {
    final itens = await repo.locais();
    final n = itens
        .where((m) => ['pendente', 'atencao'].contains(m['estado']))
        .length;
    if (!mounted) return;
    if (n > 0) {
      final sim = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Sair com pendências?'),
          content: Text(
            'Existem $n lançamentos neste aparelho. Eles serão preservados; entre novamente com a mesma conta para enviá-los.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Continuar no app'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Sair'),
            ),
          ],
        ),
      );
      if (sim != true || !mounted) return;
    }
    await AuthRepository().logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, Rotas.login, (r) => false);
    }
  }

  Widget atalho(
    String titulo,
    String descricao,
    IconData icone,
    String rota,
    Color cor,
  ) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        await Navigator.pushNamed(context, rota);
        if (mounted) {
          _resumo();
          _atualizar();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icone, color: cor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descricao,
                    style: const TextStyle(
                      color: Color(0xff64748b),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 22, color: Color(0xff64748b)),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          Image.asset('assets/logo.png', width: 36, height: 36),
          SizedBox(width: 10),
          Text('Pizzaria'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sair',
          onPressed: _sair,
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xff252b35),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUA PIZZARIA, EM DIA',
                style: TextStyle(
                  color: Color(0xffffb9bf),
                  fontSize: 12,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Tudo pronto para mais uma rodada?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Produtos, equipe e estoque em um só lugar.',
                style: TextStyle(color: Color(0xffcbd5e1)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(resumoOrigem, style: const TextStyle(color: Color(0xff64748b))),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: Text("Zerados: $zerados"),
              onPressed: () => Navigator.pushNamed(
                context,
                Rotas.estoque,
                arguments: "Zerados",
              ),
            ),
            ActionChip(
              label: Text("Estoque baixo: $baixos"),
              onPressed: () => Navigator.pushNamed(
                context,
                Rotas.estoque,
                arguments: "Estoque baixo",
              ),
            ),
            ActionChip(
              label: Text(
                "Movimentações hoje: ${movimentosHoje?.toString() ?? "—"}",
              ),
              onPressed: () {
                final hoje = DateTime.now().toIso8601String().substring(0, 10);
                Navigator.pushNamed(
                  context,
                  Rotas.movimentacoes,
                  arguments: <String, String>{"de": hoje, "ate": hoje},
                );
              },
            ),
            IconButton(
              tooltip: "Atualizar resumo",
              onPressed: _resumo,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (pendentes > 0)
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.cloud_upload_outlined,
                color: Colors.deepOrange,
              ),
              title: Text('$pendentes movimentações aguardando'),
              subtitle: const Text('Veja as pendências e possíveis ajustes.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, Rotas.movimentacoes),
            ),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Gerenciar',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        LayoutBuilder(
          builder: (context, box) {
            final itens = [
              atalho(
                'Produtos',
                'Organize o cardápio',
                Icons.local_pizza_outlined,
                Rotas.produtos,
                const Color(0xffef3340),
              ),
              atalho(
                'Estoque',
                'Consulte e ajuste saldos',
                Icons.inventory_2_outlined,
                Rotas.estoque,
                const Color(0xff2563eb),
              ),
              atalho(
                'Movimentações',
                'Histórico e fila de envios',
                Icons.swap_vert,
                Rotas.movimentacoes,
                const Color(0xff0f766e),
              ),
              if (admin)
                atalho(
                  'Colaboradores',
                  'Gerencie os acessos',
                  Icons.people_outline,
                  Rotas.usuarios,
                  const Color(0xff7c3aed),
                ),
            ];
            return Wrap(
              spacing: 12,
              runSpacing: 0,
              children: itens
                  .map(
                    (w) => SizedBox(
                      width: box.maxWidth >= 500
                          ? (box.maxWidth - 12) / 2
                          : box.maxWidth,
                      child: w,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}
