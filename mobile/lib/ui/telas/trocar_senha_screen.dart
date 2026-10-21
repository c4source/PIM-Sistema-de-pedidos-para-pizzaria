import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/rotas.dart';
import '../../data/repositories/auth_repository.dart';

class TrocarSenhaScreen extends StatefulWidget {
  final String tokenProvisorio;

  const TrocarSenhaScreen({
    super.key,
    required this.tokenProvisorio,
  });

  @override
  State<TrocarSenhaScreen> createState() => _TrocarSenhaScreenState();
}

class _TrocarSenhaScreenState extends State<TrocarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  final AuthRepository _authRepository = AuthRepository();

  bool _salvando = false;

  @override
  void dispose() {
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _salvarSenha() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      await _authRepository.trocarSenha(
        tokenProvisorio: widget.tokenProvisorio,
        novaSenha: _novaSenhaController.text,
      );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        Rotas.home,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
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
        title: const Text('Definir nova senha'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Primeiro acesso',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Por segurança, você precisa definir '
                'uma nova senha antes de acessar o sistema.',
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _novaSenhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova senha',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.length < 8) {
                    return 'A senha deve ter pelo menos 8 caracteres';
                  }

                  if (utf8.encode(valor).length > 72) {
                    return 'A senha ultrapassa o limite de 72 bytes';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmarSenhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nova senha',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor != _novaSenhaController.text) {
                    return 'As senhas não coincidem';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: _salvando ? null : _salvarSenha,
                child: _salvando
                    ? const CircularProgressIndicator()
                    : const Text('Salvar nova senha'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}