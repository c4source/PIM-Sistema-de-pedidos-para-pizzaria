import 'package:flutter/material.dart';

class TemaApp {
  static ThemeData get tema {
    return ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB23A48),
      ),

      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}

// O tema do aplicativo define a aparência visual do aplicativo, incluindo cores, fontes e estilos de widgets. O tema é aplicado a todo o aplicativo e pode ser personalizado para atender às necessidades do desenvolvedor