import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pizzaria - Administração'),
      ),
      body: const Center(
        child: Text(
          'Login realizado com sucesso!',
        ),
      ),
    );
  }
}

//StatellesWidget: tela que não possui estado mutável.

//Ex; uma tela que vai exibir alguma informação que não vai mudar durante a execução do aplicativo. 



//Scaffold: widget que fornece uma estrutura basica para tela, incluindo barra de aplicativo, corpo e outros elementos visuais.

//Scaffold: estrutura de uma casa;

//AppBar: barra de topo da tela

//body; corpo da tela, onde o conteudo da tela é exibido.

//FloatingActionButton: botao flutuante, geralmente usado para ações principais da tela. (+)

//BottomNavigationBar: barra de navegação inferior, geralmente usada para navegar entre diferentes telas do aplicativo. (home, perfil, configurações) 




//StateFulWidget; tela que contem estado mutável. ex; uma tela que vai exibir informacoes que vao mudar durante a execucao do aplicativo.