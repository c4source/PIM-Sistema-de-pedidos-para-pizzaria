import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/api/colaboradores_api.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/movimentacao_estoque_repository.dart';

class UsuariosScreen extends StatefulWidget {
  final ColaboradoresApi? api;
  const UsuariosScreen({super.key, this.api});
  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  late final api = widget.api ?? ColaboradoresApi();
  List<dynamic> usuarios = [];
  bool ocupado = false;
  String? erro;
  int? autor;
  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      ocupado = true;
      erro = null;
    });
    try {
      autor = usuarioSessao(await AuthRepository().obterToken());
      final dados = await api.executar('GET') as List;
      if (mounted) {
        setState(() {
          usuarios = dados;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          erro = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          ocupado = false;
        });
      }
    }
  }

  void _mensagem(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagem)));
    }
  }

  Future<void> _senha(dynamic resposta, String titulo) async {
    if (!mounted) return;
    final senha = resposta['senhaProvisoria'] as String;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.teal, size: 48),
        title: Text(titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entregue esta senha ao colaborador. Ele deverá trocá-la no primeiro acesso.',
            ),
            const SizedBox(height: 16),
            SelectableText(
              senha,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: senha));
              if (c.mounted) {
                ScaffoldMessenger.of(
                  c,
                ).showSnackBar(const SnackBar(content: Text('Senha copiada.')));
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _formulario([Map<String, dynamic>? usuario]) async {
    final nome = TextEditingController(text: usuario?['nome'] as String? ?? '');
    final email = TextEditingController(
      text: usuario?['email'] as String? ?? '',
    );
    String perfil = usuario?['perfil'] as String? ?? 'Colaborador';
    final key = GlobalKey<FormState>();
    bool salvando = false;
    String? falha;
    dynamic resposta;
    final sucesso = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => StatefulBuilder(
        builder: (c, setModal) => PopScope(
          canPop: !salvando,
          child: AlertDialog(
            title: Text(usuario == null ? 'Criar usuário' : 'Editar usuário'),
            content: SingleChildScrollView(
              child: Form(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nome,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      maxLength: 100,
                      validator: (v) => (v?.trim().length ?? 0) < 2
                          ? 'Informe o nome.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      maxLength: 100,
                      validator: (v) =>
                          v != null &&
                              RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(v.trim())
                          ? null
                          : 'Informe um e-mail válido.',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: perfil,
                      decoration: const InputDecoration(labelText: 'Perfil'),
                      items: ['Administrador', 'Colaborador']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: salvando ? null : (v) => perfil = v!,
                    ),
                    if (falha != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          falha!,
                          style: TextStyle(
                            color: Theme.of(c).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: salvando ? null : () => Navigator.pop(c, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: salvando
                    ? null
                    : () async {
                        if (!key.currentState!.validate()) return;
                        setModal(() {
                          salvando = true;
                          falha = null;
                        });
                        try {
                          resposta = await api.executar(
                            usuario == null ? 'POST' : 'PUT',
                            caminho: usuario == null ? '' : '/${usuario['id']}',
                            dados: {
                              'nome': nome.text.trim(),
                              'email': email.text.trim(),
                              'perfil': perfil,
                            },
                          );
                          if (c.mounted) Navigator.pop(c, true);
                        } catch (e) {
                          if (c.mounted) {
                            setModal(() {
                              falha = e.toString().replaceFirst(
                                'Exception: ',
                                '',
                              );
                              salvando = false;
                            });
                          }
                        }
                      },
                child: Text(salvando ? 'Salvando...' : 'Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
    // Aguarda a animação do diálogo antes de liberar os controllers.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    nome.dispose();
    email.dispose();
    if (sucesso == true) {
      if (usuario == null) {
        await _senha(resposta, 'Usuário criado!');
      } else {
        _mensagem('Usuário atualizado com sucesso.');
      }
      if (mounted) await _carregar();
    }
  }

  Future<void> _situacao(Map<String, dynamic> u) async {
    final ativo = u['ativo'] != false;
    final sim = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(ativo ? 'Suspender acesso?' : 'Reativar acesso?'),
        content: Text(
          ativo
              ? 'O usuário perderá acesso. Seu histórico será preservado.'
              : 'O usuário poderá entrar novamente com suas credenciais.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (sim != true || !mounted) return;
    setState(() {
      ocupado = true;
    });
    try {
      await api.executar(
        'PATCH',
        caminho: '/${u['id']}/ativo',
        dados: {'ativo': !ativo},
      );
      _mensagem(ativo ? 'Acesso suspenso.' : 'Acesso reativado.');
    } catch (e) {
      _mensagem(e.toString().replaceFirst('Exception: ', ''));
    }
    if (mounted) await _carregar();
  }

  Future<void> _acao(Map<String, dynamic> u, bool resetar) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(resetar ? 'Resetar senha?' : 'Excluir usuário?'),
        content: Text(
          '${resetar ? 'Gerar uma nova senha provisória para ' : 'Excluir o acesso de '}${u['nome']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    setState(() {
      ocupado = true;
    });
    try {
      final resposta = await api.executar(
        resetar ? 'POST' : 'DELETE',
        caminho: '/${u['id']}${resetar ? '/resetar-senha' : ''}',
      );
      if (mounted) {
        setState(() {
          ocupado = false;
        });
      }
      if (resetar) {
        await _senha(resposta, 'Senha resetada!');
      } else {
        _mensagem('Usuário excluído.');
      }
    } catch (e) {
      _mensagem(e.toString().replaceFirst('Exception: ', ''));
    }
    if (mounted) await _carregar();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Colaboradores'),
      actions: [
        IconButton(
          onPressed: ocupado ? null : _carregar,
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar',
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: ocupado ? null : () => _formulario(),
      icon: const Icon(Icons.person_add_outlined),
      label: const Text('Criar usuário'),
    ),
    body: RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          const Text(
            'Sua equipe',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gerencie os acessos da pizzaria. Esta área exige conexão.',
          ),
          const SizedBox(height: 20),
          if (ocupado) const LinearProgressIndicator(),
          if (erro != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(erro!)),
          for (final u in usuarios)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xffeef2f6),
                          child: Icon(
                            u['perfil'] == 'Administrador'
                                ? Icons.admin_panel_settings_outlined
                                : Icons.person_outline,
                            color: const Color(0xff334155),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            u['nome'] as String,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (u['perfil'] as String) +
                          (u['ativo'] == false ? ' · Suspenso' : ''),
                      style: const TextStyle(color: Color(0xff475569)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: u['ativo'] == false
                              ? 'Reativar acesso'
                              : 'Suspender acesso',
                          onPressed: ocupado || u['id'] == autor
                              ? null
                              : () => _situacao(Map<String, dynamic>.from(u)),
                          icon: Icon(
                            u['ativo'] == false
                                ? Icons.play_circle_outline
                                : Icons.pause_circle_outline,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: ocupado
                              ? null
                              : () => _formulario(Map<String, dynamic>.from(u)),
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xff2563eb),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Resetar senha',
                          onPressed: ocupado || u['id'] == autor
                              ? null
                              : () => _acao(Map<String, dynamic>.from(u), true),
                          icon: const Icon(Icons.lock_reset),
                        ),
                        IconButton(
                          tooltip: 'Excluir',
                          onPressed: ocupado || u['id'] == autor
                              ? null
                              : () =>
                                    _acao(Map<String, dynamic>.from(u), false),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
