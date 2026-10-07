import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pizzaria - Administração'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Painel Administrativo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Selecione uma opção para gerenciar o sistema.',
            ),

            const SizedBox(height: 24),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: const [
                  _AtalhoAdmin(
                    titulo: 'Usuários',
                    icone: Icons.people,
                  ),
                  _AtalhoAdmin(
                    titulo: 'Produtos',
                    icone: Icons.inventory_2,
                  ),
                  _AtalhoAdmin(
                    titulo: 'Estoque',
                    icone: Icons.warehouse,
                  ),
                  _AtalhoAdmin(
                    titulo: 'Movimentações',
                    icone: Icons.swap_horiz,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtalhoAdmin extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final VoidCallback? onTap;

  const _AtalhoAdmin({
    required this.titulo,
    required this.icone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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