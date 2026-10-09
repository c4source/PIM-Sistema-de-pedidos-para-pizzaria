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

A estrutura necessária para registrar alterações de estoque também foi
preparada para os requisitos de entrada, saída e histórico de
movimentações.