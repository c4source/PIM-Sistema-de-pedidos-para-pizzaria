# Mobile: catálogo local e fila de estoque

O PostgreSQL é a fonte oficial. O SQLite guarda o catálogo e os lançamentos do aparelho; toda alteração no PostgreSQL passa pela API autenticada.

## Funcionamento

1. Entre online e abra Produtos ou Estoque para baixar o catálogo. O primeiro login e a primeira consulta exigem conexão.
2. Em Estoque, use os ícones de entrada e saída para registrar uma quantidade de um produto individual. Kits são calculados pelos componentes e não recebem movimentação direta.
3. O lançamento é gravado primeiro no SQLite com um UUID e o ID da conta. Se a API responder, passa a Confirmada. Sem resposta, permanece Pendente mesmo depois de fechar o aplicativo.
4. Enquanto o app estiver em primeiro plano, tenta enviar a cada 20 segundos, ao abrir novamente e ao tocar em Sincronizar. Não há serviço executando com o app fechado. Essas tentativas não renovam a sessão por inatividade.
5. A API valida o usuário, o produto e o saldo e registra saldo + histórico na mesma transação EF. O índice único operacao_id impede duplicação. Reenvios do mesmo usuário com o mesmo conteúdo retornam o lançamento original. O mesmo ID com dados/autor diferentes é rejeitado.
6. Estoque insuficiente e demais rejeições de negócio aparecem como Requer atenção. Os lançamentos seguintes desse produto ficam aguardando; outros produtos podem continuar. O usuário pode tentar novamente depois de corrigir a causa ou descartar o lançamento explicitamente rejeitado. Um envio sem resposta não pode ser descartado: pode já ter sido confirmado no servidor.
7. Em Movimentações, a fila local é separada do histórico paginado da API. Sem conexão, confirmações já recebidas neste aparelho continuam visíveis; o histórico completo precisa de conexão.

A tela Estoque mostra o último saldo recebido e a estimativa que inclui pendências da conta atual. Essa estimativa não reserva unidades nem garante disponibilidade: vendas, outros aparelhos e envios sem resposta podem mudar o saldo. Kits continuam mostrando a capacidade do último catálogo recebido; a estimativa local não recalcula os componentes de kits.

## Contas e permissões

A fila fica vinculada à conta que a criou. Outra conta não a visualiza nem a envia. Após expiração do JWT ou resposta 401/403, é necessário entrar novamente; uma nova credencial da mesma conta pode retomar os lançamentos. A sessão continua sendo verificada no servidor a cada envio.

Colaboradores é exclusivo do administrador e exige conexão: listagem, criação/edição em diálogo, exclusão e reset de senha provisória. A senha provisória aparece somente no diálogo de resultado, com Copiar e OK; não vai para o SQLite. O primeiro acesso mantém a troca obrigatória de senha. As proteções de último administrador, exclusão e reset do próprio usuário continuam na API.

Cadastros de produtos continuam online. Apenas entradas e saídas de estoque usam a fila. Alterar o cadastro de um produto e seu saldo absoluto exige conexão.

## Persistência e atualização

O arquivo pim*catalogo*\*.db fica no diretório privado de bancos do aplicativo, separado por endereço de API. A versão 2 acrescenta fila_estoque; a versão 3 adiciona motivo, observação, referência de contagem e estoque mínimo por onUpgrade, preservando catálogo e pendências anteriores. Invalidar ou substituir o catálogo não apaga a fila. Limpar os dados/desinstalar o app apaga pendências ainda não enviadas; elas não são compartilhadas entre aparelhos. Tokens continuam no armazenamento seguro.

A migration SincronizacaoMovimentacoesMobile adiciona o UUID opcional e seu índice único no PostgreSQL, preservando movimentos antigos. Execute Atualizar-Banco.ps1 antes de iniciar a nova API em outra máquina. O cliente antigo continua aceito sem UUID, mas só o novo mobile fornece a proteção contra reenvios.

GET /api/MovimentacaoEstoque?pagina=1&tamanho=30 retorna o histórico autenticado com nomes de produto/responsável e total; tamanho máximo 100. POST mantém produtoId, tipo e quantidade, acrescentando operacaoId. O responsável sempre vem do JWT.

## Teste manual

- Pare o app completamente, execute flutter pub get e inicie novamente.
- Com a API ligada, entre e abra Estoque para baixar o catálogo.
- Interrompa a API e registre uma entrada ou saída em um produto de teste. Confira Pendente em Movimentações e feche/reabra o app.
- Religue a API: com sessão válida, o lançamento deve confirmar em até um ciclo de tentativa. Atualize Estoque e confira o saldo oficial.
- Teste uma saída maior que o saldo: deve ficar Requer atenção, sem estoque negativo. Ajuste o saldo e tente novamente, ou descarte a rejeição.
- Troque de conta: as pendências da conta anterior não devem aparecer nem ser enviadas. Entre de novo com a conta original para retomá-las.

## Validação automatizada

flutter analyze --no-pub
flutter test
flutter build apk --debug --no-pub

Os testes SQLite usam sqflite_common_ffi: persistência em disco, upgrade v1-v2, timeout/reenvio com mesmo ID, isolamento entre contas, sessão expirada, chamadas simultâneas, rejeição de negócio, ordem por produto e retomada. O script tests/movimentacoes-api.test.cjs testa a API com produtos temporários e exige PIM_TEST_CLEANUP_SQL para registrar a limpeza SQL desses dados. Execute-o somente em banco de desenvolvimento e aplique o arquivo de limpeza após o teste.

As melhorias de ajuste rápido, filtros, contagem, alertas e suspensão estão em [melhorias_mobile.md](melhorias_mobile.md).
