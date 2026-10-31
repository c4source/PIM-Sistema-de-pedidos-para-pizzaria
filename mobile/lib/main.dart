import 'package:flutter/material.dart';

import 'ui/telas/estoque_screen.dart';
import 'ui/telas/produtos_screen.dart';
import 'core/rotas.dart';
import 'core/tema.dart';
import 'data/repositories/auth_repository.dart';
import 'ui/telas/home_screen.dart';
import 'ui/telas/login_screen.dart';

final sessaoNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authRepository = AuthRepository();
  final temSessao = await authRepository.temSessao();

  runApp(EstoqueApp(temSessao: temSessao));
}

class EstoqueApp extends StatelessWidget {
  final bool temSessao;

  const EstoqueApp({super.key, required this.temSessao});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: sessaoNavigatorKey,
      builder: (context, child) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) async {
          final valida = await AuthRepository().registrarAtividade();
          if (!valida) {
            sessaoNavigatorKey.currentState?.pushNamedAndRemoveUntil(
              Rotas.login,
              (route) => false,
            );
          }
        },
        child: child ?? const SizedBox.shrink(),
      ),
      debugShowCheckedModeBanner: false,
      title: 'Pizzaria - Administração',
      theme: TemaApp.tema,

      home: temSessao ? const HomeScreen() : const LoginScreen(),

      routes: {
        Rotas.login: (context) => const LoginScreen(),
        Rotas.home: (context) => const HomeScreen(),
        Rotas.produtos: (context) => const ProdutosScreen(),
        Rotas.estoque: (context) => const EstoqueScreen(),
      },
    );
  }
}
