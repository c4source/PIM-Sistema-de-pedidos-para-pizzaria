import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estoque_app/ui/widgets/status_catalogo.dart';

void main() {
  testWidgets('Aviso local cabe em tela estreita e oferece sincronização', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var chamadas = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StatusCatalogo(
                local: true,
                carregando: false,
                falhaCache: false,
                atualizadoEm: DateTime(2026, 10, 31, 14, 30),
                sincronizar: () {
                  chamadas++;
                },
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Sem conexão'), findsOneWidget);
    expect(
      find.textContaining('Você pode registrar movimentações'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Atualizar'));
    expect(chamadas, 1);
  });
  testWidgets('Sincronização fica bloqueada enquanto consulta o servidor', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatusCatalogo(
            local: false,
            carregando: true,
            falhaCache: false,
            atualizadoEm: null,
            sincronizar: () {},
          ),
        ),
      ),
    );
    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.onPressed, isNull);
  });
  testWidgets(
    'Pendências mostram contagem e acesso à fila sem afirmar estoque atualizado',
    (tester) async {
      var abriu = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusCatalogo(
              local: false,
              carregando: false,
              falhaCache: false,
              atualizadoEm: DateTime.now(),
              sincronizar: () {},
              assunto: 'Estoque',
              pendentes: 2,
              atencao: 1,
              abrirFila: () {
                abriu = true;
              },
            ),
          ),
        ),
      );
      expect(find.text('Estoque atualizado'), findsNothing);
      expect(
        find.textContaining('2 movimentações aguardando envio'),
        findsOneWidget,
      );
      expect(
        find.textContaining('1 movimentação requer atenção'),
        findsOneWidget,
      );
      await tester.tap(find.textContaining('2 movimentações aguardando envio'));
      expect(abriu, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Estado online usa texto simples e horário da atualização', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatusCatalogo(
            local: false,
            carregando: false,
            falhaCache: false,
            atualizadoEm: DateTime.now(),
            sincronizar: () {},
            assunto: 'Estoque',
          ),
        ),
      ),
    );
    expect(find.text('Estoque atualizado'), findsOneWidget);
    expect(find.textContaining('Atualizado às'), findsOneWidget);
    expect(find.text('Catálogo do servidor'), findsNothing);
    expect(find.byTooltip('Atualizar'), findsOneWidget);
  });
}
