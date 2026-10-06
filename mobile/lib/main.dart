import 'package:flutter/material.dart';

import 'core/rotas.dart';
import 'core/tema.dart';
import 'data/repositories/auth_repository.dart';
import 'ui/telas/home_screen.dart';
import 'ui/telas/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authRepository = AuthRepository();
  final temSessao = await authRepository.temSessao();

  runApp(
    EstoqueApp(temSessao: temSessao),
  );
}

class EstoqueApp extends StatelessWidget {
  final bool temSessao;

  const EstoqueApp({
    super.key,
    required this.temSessao,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pizzaria - Administração',
      theme: TemaApp.tema,

      home: temSessao
    ? const HomeScreen()
    : const LoginScreen(),

      routes: {
        Rotas.login: (context) => const LoginScreen(),
        Rotas.home: (context) => const HomeScreen(),
      },
    );
  }
}