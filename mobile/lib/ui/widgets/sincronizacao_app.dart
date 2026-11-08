import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/movimentacao_estoque_repository.dart';

/// Tenta novamente enquanto o app está em uso; não renova a sessão por atividade.
class SincronizacaoApp extends StatefulWidget {
  final Widget child;
  const SincronizacaoApp({super.key, required this.child});
  @override
  State<SincronizacaoApp> createState() => _SincronizacaoAppState();
}

class _SincronizacaoAppState extends State<SincronizacaoApp>
    with WidgetsBindingObserver {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciar();
  }

  void _iniciar() {
    timer?.cancel();
    unawaited(MovimentacaoEstoqueRepository().sincronizar());
    timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => MovimentacaoEstoqueRepository().sincronizar(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _iniciar();
    } else {
      timer?.cancel();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
