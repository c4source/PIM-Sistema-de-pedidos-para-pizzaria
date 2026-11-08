import 'package:flutter/material.dart';

import 'trocar_senha_screen.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/rotas.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState(); //Objeto que contem o estado da tela, ou seja, as informações que podem mudar durante a execução do aplicativo.
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); //Chave global para o formulário, usada para validar os campos de email e senha.

  //Controladores de texto para os campos de email e senha. Eles permitem acessar o valor digitado pelo usuário.
  //Controller le/guarda o que foi digitado no campo
  //Objetos do tipo TextEditingController. Captura o que o usuario digitar e guarda nas variaveis _emailController e _senhaController.
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();

  bool _ocultarSenha = true; //estado: true = *** / false = 123
  bool _carregando =
      false; //estado: false = botao normal / true = "Entrando..."

  //O método dispose é chamado quando o widget é removido da árvore de widgets. Ele é usado para liberar recursos, como controladores de texto, que não são mais necessários.
  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final email = _emailController.text.trim();
      final senha = _senhaController.text;

      final resposta = await _authRepository.login(email, senha);

      if (!mounted) return;

      if (resposta['trocaSenhaObrigatoria'] == true) {
        final tokenProvisorio = resposta['token'];

        if (tokenProvisorio is! String || tokenProvisorio.isEmpty) {
          throw Exception('Token provisório não recebido.');
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TrocarSenhaScreen(tokenProvisorio: tokenProvisorio),
          ),
        );

        return;
      }

      // Login normal: usuário já possui senha definitiva.
      Navigator.pushReplacementNamed(context, Rotas.home);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/logo.png',
                      width: 130,
                      height: 130,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Bem-vindo à pizzaria',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Acesse o painel da equipe para cuidar dos produtos e do estoque.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xff64748b)),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (v) => v != null && v.contains('@')
                        ? null
                        : 'Informe um e-mail válido.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senhaController,
                    obscureText: _ocultarSenha,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) {
                      if (!_carregando) _entrar();
                    },
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _ocultarSenha
                            ? 'Mostrar senha'
                            : 'Ocultar senha',
                        icon: Icon(
                          _ocultarSenha
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() {
                          _ocultarSenha = !_ocultarSenha;
                        }),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Informe sua senha.' : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _carregando ? null : _entrar,
                    child: _carregando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Acesso exclusivo da equipe',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xff64748b), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
