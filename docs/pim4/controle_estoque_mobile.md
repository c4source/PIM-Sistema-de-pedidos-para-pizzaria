# RF36 — Controle de Estoque

O aplicativo mobile permite consultar a quantidade atual disponível
dos produtos cadastrados no sistema.

## Tela de Estoque

A tela de estoque apresenta os produtos cadastrados contendo:

- nome do produto;
- categoria;
- quantidade disponível em estoque.

Os dados exibidos são obtidos da API REST e correspondem aos valores
armazenados no PostgreSQL.

## Arquitetura

EstoqueScreen
→ ProdutoRepository
→ ProdutoApi
→ GET /api/Produto
→ API ASP.NET Core
→ PostgreSQL

A interface mobile não acessa diretamente o banco de dados.

## Controle da quantidade

A quantidade atual permanece armazenada no campo `estoque` da tabela
`produto`.

Também foi preparada a infraestrutura de movimentações de estoque,
permitindo que alterações futuras sejam realizadas por meio de entradas
e saídas registradas no sistema.

Uma movimentação atualiza a quantidade do produto e registra seu
histórico dentro de uma transação no banco de dados.

## Consistência

O backend impede que uma movimentação resulte em estoque negativo.

A atualização da quantidade e o registro da movimentação são executados
na mesma transação. Caso alguma etapa falhe, toda a operação é desfeita.

## Autenticação

O token JWT passou a armazenar também o identificador do colaborador
autenticado.

Dessa forma, futuras movimentações podem identificar automaticamente
qual funcionário realizou a operação.

## Resultado

O funcionário pode consultar pelo aplicativo a quantidade atual dos
produtos armazenados no sistema.

As funcionalidades de entrada (RF37) e saída (RF38) de estoque foram implementadas e testadas no aplicativo mobile, com integração à API ASP.NET Core e ao PostgreSQL.


---

# RF37 — Registro de Entrada de Estoque

## Descrição

Foi implementada a funcionalidade de entrada de estoque pelo aplicativo Flutter.

O funcionário autenticado pode selecionar um produto, informar a quantidade e registrar uma entrada, aumentando o estoque disponível.

## Implementação no Flutter

Foram criados os seguintes arquivos:

- `movimentacao_estoque_screen.dart` — formulário de entrada e saída.
- `movimentacao_estoque_repository.dart` — intermediação entre interface e API.
- `movimentacao_estoque_api.dart` — comunicação HTTP com o backend.

A tela `estoque_screen.dart` também recebeu um botão para registrar entradas.

A interface utiliza o mesmo formulário para entrada e saída, diferenciando as operações pelo parâmetro `tipo`.

## Integração com o Backend

A movimentação é enviada ao endpoint:

`POST /api/MovimentacaoEstoque`

O corpo JSON contém:

- `produtoId` — identificador do produto.
- `tipo` — entrada ou saída.
- `quantidade` — unidades movimentadas.

A requisição utiliza o token JWT do funcionário autenticado.

O backend identifica o colaborador, valida os dados e utiliza uma transação PostgreSQL para atualizar o estoque e registrar a movimentação.

## Validações

- Produto selecionado.
- Quantidade inteira maior que zero.
- Tipo de movimentação válido.
- Identificação do funcionário pelo JWT.
- Atualização do estoque e histórico na mesma transação.

## Testes realizados

- Registro de entrada pelo Swagger, com resposta HTTP 201.
- Confirmação do aumento de estoque no PostgreSQL.
- Confirmação do histórico na tabela `movimentacao_estoque`.
- Registro de entrada diretamente pelo Flutter.
- Atualização automática da listagem de estoque após a operação.

No teste pelo Flutter, o produto "Agua com gas" passou de 55 para 65 unidades após uma entrada de 10 unidades.

## Resultado

O RF37 está implementado e teve seu fluxo online validado com Flutter, API ASP.NET Core e PostgreSQL.

A persistência offline e a sincronização com SQLite serão desenvolvidas no RF40.


---

# RF38 — Registro de Saída de Estoque

## Descrição

Foi implementado o registro de saída de estoque pelo aplicativo Flutter.

O funcionário autenticado pode selecionar um produto, informar a quantidade e registrar uma saída, reduzindo o estoque disponível.

## Implementação

A tela `EstoqueScreen` recebeu um botão para registrar saídas.

Foi reutilizada a tela `MovimentacaoEstoqueScreen`, utilizando o parâmetro `tipo: 'saida'`.

A movimentação é enviada para a API por meio do endpoint:

`POST /api/MovimentacaoEstoque`

O backend utiliza uma transação PostgreSQL para atualizar o estoque e registrar a movimentação.

## Validações

- Quantidade inteira maior que zero.
- Produto existente.
- Funcionário autenticado via JWT.
- Estoque suficiente para realizar a saída.
- Produtos kit não permitem movimentações diretas.
- Atualização do estoque e registro do histórico na mesma transação.

## Testes realizados

- Compilação do backend .NET com sucesso.
- `flutter analyze` sem erros.
- Registro de saída pelo Flutter.
- Produto "Agua com gas" reduzido de 65 para 64 unidades.
- Movimentação confirmada no PostgreSQL.
- Tentativa de retirar 65 unidades recusada por estoque insuficiente.
- Estoque preservado em 64 unidades após a tentativa inválida.
- Mensagem de estoque insuficiente exibida no Flutter.
- Tentativa de movimentar o kit de código 27 recusada pela API com HTTP 400.

## Resultado

O RF38 foi implementado e testado com sucesso no fluxo online:

Flutter → API ASP.NET Core → PostgreSQL.

A sincronização offline utilizando SQLite será desenvolvida no RF40.