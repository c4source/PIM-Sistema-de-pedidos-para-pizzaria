# Evolução operacional do mobile

## Uso diário

- Em Estoque, toque em um produto individual para abrir o ajuste rápido. Entrada/saída registram quantidades e motivo; contagem informa o número encontrado fisicamente.
- A busca ignora acentos e maiúsculas. O ícone de filtro permite categoria, estoque baixo e zerados.
- O menu de cada produto permite Configurar alerta: informe o estoque mínimo online. O padrão é 5; zero desativa o alerta de saldo baixo, mas o saldo zerado continua identificado. Os avisos são visuais, sem notificações push. Kits são calculados pelos componentes e não recebem ajustes nem limite próprio.
- Reposição, perda, consumo interno, correção e outro são os motivos disponíveis, com observação opcional de até 500 caracteres. Contagens têm motivo próprio.
- Saídas a partir de 10 unidades pedem confirmação. A contagem sempre pede confirmação.
- O painel inicial mostra zerados, produtos com estoque baixo e quantidade de movimentações manuais do dia. O resumo indica quando utiliza o último catálogo local. Vendas continuam registradas nos pedidos/baixas, não entram no contador de movimentações manuais.

## Contagem e concorrência

A contagem calcula a diferença entre o último saldo recebido e a quantidade encontrada. Ela não substitui o saldo sem conferência: a API, dentro da mesma transação que altera o estoque, compara o saldo atual com estoqueEsperado. Se forem diferentes, retorna 409 com os dois saldos e não aplica nada. O responsável deve atualizar o estoque, descartar a contagem rejeitada e conferir novamente.

Contagens podem aguardar conexão no SQLite, com o mesmo UUID no reenvio. Não se inicia uma contagem se esse produto já tiver pendências na conta deste aparelho. Mesmo assim, outros aparelhos e usuários podem movimentar o produto; o servidor decide se a referência continua válida. Quando a contagem coincide com a referência, nenhum ajuste é enviado.

## Histórico e pendências

O ícone Filtrar histórico abre período, tipo, produto e responsável. Datas inicial/final são inclusivas. Filtros se aplicam ao histórico da API; a fila local permanece visível por completo para não esconder pendências. Responsáveis com histórico podem ser consultados por qualquer perfil operacional, sem expor e-mail/senha. Nome, motivo e observação aparecem no lançamento.

Ao sair com pendências, o aplicativo pede confirmação e explica que é necessário entrar com a mesma conta para retomar. Um resultado de envio incerto continua pendente e não pode ser descartado como rejeição.

## Suspensão de acessos

Somente administradores podem suspender/reativar em Colaboradores. Suspender preserva os registros, incrementa a versão da sessão e impede login e uso de tokens anteriores na API. Reativar permite um novo login; não reativa tokens antigos. Não é permitido suspender a própria conta ou o último administrador com acesso ativo. Excluir continua restrito quando há histórico vinculado.

## Atualização e instalação

- Execute Atualizar-Banco.ps1 e reinicie a API: a migration EvolucaoOperacionalMobile adiciona ativo, estoque_minimo e os campos de motivo/contagem. O schema.sql também inclui essa migration; o seed anterior continua válido com os valores padrão.
- Pare e execute novamente o mobile. A versão 3 do SQLite adiciona as colunas preservando catálogo e pendências das versões anteriores; lançamentos antigos ficam com motivo Outro.
- O nome instalado passa a Pizzaria Equipe, com o logotipo e versão 1.1.0+2. O applicationId foi mantido para preservar os dados ao atualizar. Este ciclo valida o APK de depuração; assinatura de distribuição e publicação em loja são etapas separadas.

## Validação

flutter analyze, testes SQLite de migração/reenvio, testes de interface em tela estreita com fonte ampliada e testes da API para contagem concorrente, idempotência, filtros, limite de estoque e suspensão/reativação. tests/banco-scripts.test.ps1 valida instalação SQL e atualização EF em bancos temporários.

Para apontar outra API sem editar o código, execute `flutter run --dart-define=PIM_API_URL=http://IP-DO-SERVIDOR:5162` ou passe o mesmo parâmetro ao build. Use a URL base sem barra final. O padrão continua sendo o endereço do host no emulador Android; a cópia SQLite fica separada por URL. Em distribuição fora do ambiente local, configure a API com HTTPS.
