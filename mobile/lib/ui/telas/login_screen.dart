import 'package:flutter/material.dart';

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

      await _authRepository.login(email, senha);

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, Rotas.home);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail ou senha inválidos')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  //Arvore de Widgets: estrutura hierarquica de widgets que compoem a interface do usuario. Cada widget pode conter outros widgets, formando uma arvore.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Digite seu email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Digite seu e-mail';
                  }

                  if (!valor.contains('@')) {
                    return 'Digite um e-mail válido';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _senhaController,
                obscureText: _ocultarSenha,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarSenha ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _ocultarSenha = !_ocultarSenha;
                      });
                    },
                  ),
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Digite sua senha';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _carregando ? null : _entrar,
                  child: _carregando
                      ? const CircularProgressIndicator()
                      : const Text('Entrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
