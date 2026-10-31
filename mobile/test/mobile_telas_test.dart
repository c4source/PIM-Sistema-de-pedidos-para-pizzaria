import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:estoque_app/core/tema.dart';
import 'package:estoque_app/data/api/colaboradores_api.dart';
import 'package:estoque_app/ui/telas/usuarios_screen.dart';
import 'package:estoque_app/ui/telas/login_screen.dart';
import 'package:estoque_app/ui/widgets/ajuste_estoque_dialog.dart';
import 'package:estoque_app/models/produto.dart';
import 'package:estoque_app/core/busca.dart';

class EquipeTeste extends ColaboradoresApi {
  final List<Map<String, dynamic>> usuarios = [
    {
      'id': 8,
      'nome': 'Ana',
      'email': 'ana@example.test',
      'perfil': 'Colaborador',
    },
  ];
  final List<String> chamadas = [];
  @override
  Future<dynamic> executar(
    String metodo, {
    String caminho = '',
    Map<String, dynamic>? dados,
  }) async {
    chamadas.add(metodo + caminho);
    if (metodo == 'GET') return usuarios.toList();
    if (metodo == 'POST' && caminho.isEmpty) {
      final u = {'id': 9, ...dados!};
      usuarios.add(u);
      return {'colaborador': u, 'senhaProvisoria': 'provisoria-de-teste'};
    }
    if (caminho.endsWith('resetar-senha')) {
      return {'senhaProvisoria': 'provisoria-resetada'};
    }
    if (metodo == 'DELETE') {
      usuarios.removeWhere((u) => '/${u['id']}' == caminho);
      return null;
    }
    return null;
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });
  testWidgets('Login cabe em tela estreita e com teclado aberto', (t) async {
    t.view.physicalSize = const Size(320, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(theme: TemaApp.tema, home: const LoginScreen()),
    );
    await t.pumpAndSettle();
    await t.tap(find.byType(TextFormField).first);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('Bem-vindo à pizzaria'), findsOneWidget);
  });
  testWidgets(
    'Colaboradores lista sem e-mail; formulário e senha abrem somente em diálogos',
    (t) async {
      final api = EquipeTeste();
      await t.pumpWidget(
        MaterialApp(
          theme: TemaApp.tema,
          home: UsuariosScreen(api: api),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('ana@example.test'), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      await t.tap(find.text('Criar usuário'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).at(0), 'Bruno');
      await t.enterText(find.byType(TextFormField).at(1), 'bruno@example.test');
      await t.tap(find.text('Salvar'));
      await t.pumpAndSettle();
      expect(find.text('Usuário criado!'), findsOneWidget);
      expect(find.text('provisoria-de-teste'), findsOneWidget);
      expect(find.text('Copiar'), findsOneWidget);
      await t.tap(find.text('OK'));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('provisoria-de-teste'), findsNothing);
      expect(find.text('Bruno'), findsOneWidget);
      expect(api.chamadas, contains('POST'));
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('Reset solicita confirmação e exibe nova senha provisória', (
    t,
  ) async {
    final api = EquipeTeste();
    await t.pumpWidget(
      MaterialApp(
        theme: TemaApp.tema,
        home: UsuariosScreen(api: api),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Resetar senha'));
    await t.pumpAndSettle();
    expect(api.chamadas, isNot(contains('POST/8/resetar-senha')));
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(find.text('provisoria-resetada'), findsOneWidget);
    expect(api.chamadas, contains('POST/8/resetar-senha'));
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
  test('Busca ignora acentos e maiúsculas', () {
    expect(normalizarBusca('ÁGUA COM GÁS'), 'agua com gas');
    expect(normalizarBusca('Reposição'), 'reposicao');
  });
  testWidgets('Ajuste rápido cabe em tela estreita com fonte ampliada', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        theme: TemaApp.tema,
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Builder(
          builder: (c) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: c,
                builder: (_) => AjusteEstoqueDialog(
                  produto: Produto(
                    id: 1,
                    nome: 'Pizza grande de frango',
                    preco: 30,
                    estoque: 6,
                  ),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Abrir'));
    await t.pumpAndSettle();
    expect(find.text('Último saldo recebido: 6 un.'), findsOneWidget);
    expect(find.text('Quantidade'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
  });
}
