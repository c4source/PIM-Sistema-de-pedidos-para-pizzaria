# RF35 — Gerenciamento de Produtos pelo Mobile

O aplicativo mobile permite que funcionários autorizados consultem,
cadastrem e editem produtos utilizando a API REST existente no backend.

Também foi implementada a exclusão de produtos, completando as operações
de CRUD do módulo.

## Arquitetura

O módulo segue a separação de responsabilidades definida para o aplicativo:

ProdutosScreen / ProdutoFormScreen
→ ProdutoRepository
→ ProdutoApi
→ API ASP.NET Core
→ ProdutoController
→ ProdutoService
→ ProdutoRepository do backend
→ PostgreSQL

A interface não acessa diretamente a API ou o banco de dados.

## Operações

- GET `/api/Produto` — consultar produtos;
- POST `/api/Produto` — cadastrar produto;
- PUT `/api/Produto/{id}` — editar produto;
- DELETE `/api/Produto/{id}` — excluir produto.

As operações de cadastro, edição e exclusão utilizam o token JWT
armazenado após o login do funcionário.

O token é enviado no cabeçalho HTTP:

`Authorization: Bearer <token>`

## Cadastro e edição

A mesma tela `ProdutoFormScreen` é reutilizada para cadastro e edição.

Quando nenhum produto é recebido pela tela, o formulário realiza um
cadastro utilizando POST.

Quando um produto existente é recebido, seus dados são carregados nos
campos e o formulário realiza a atualização utilizando PUT.

## Exclusão

A listagem possui uma opção de exclusão para cada produto.

Antes da remoção, o aplicativo apresenta uma confirmação ao usuário.
Após a exclusão ser concluída pela API, a lista de produtos é carregada
novamente.

## Fluxo

Flutter
→ ProdutoRepository
→ ProdutoApi
→ requisição HTTP + JSON
→ API ASP.NET Core
→ PostgreSQL
→ resposta da API
→ atualização da interface

## Resultado

O módulo permite consultar, cadastrar, editar e excluir produtos reais
armazenados no PostgreSQL através da API do sistema.

As operações protegidas utilizam autenticação JWT e a listagem é
atualizada após alterações realizadas pelo aplicativo.



## Validações de Produtos

Foram implementadas validações nos DTOs `ProdutoCreateDto` e `ProdutoUpdateDto` utilizando Data Annotations do ASP.NET Core.

Regras aplicadas:

- Nome obrigatório, com limite de 100 caracteres (`Required` e `StringLength`).
- Preço maior que zero (`Range`), utilizando `ParseLimitsInInvariantCulture` para interpretar corretamente os limites decimais.
- Categoria obrigatória, aceitando apenas `pizza`, `doce`, `bebida` e `combo`.
- Status obrigatório, aceitando apenas `disponivel` e `indisponivel`.
- Estoque obrigatório e maior ou igual a zero (`Range`).

No Flutter, o campo Categoria foi substituído por um `DropdownButtonFormField`, restringindo a seleção às categorias permitidas.

As validações do backend impedem que dados inválidos sejam encaminhados ao PostgreSQL. Requisições inválidas retornam HTTP 400 (Bad Request).

## Testes realizados

- Listagem de produtos no Flutter integrada à API.
- Cadastro de produto pelo Flutter, com persistência confirmada no PostgreSQL.
- Edição de produto pelo Flutter, com atualização confirmada no PostgreSQL.
- Rejeição de categoria inválida no POST e no PUT.
- Rejeição de preço negativo e estoque negativo.
- Rejeição de nome vazio e status inválido.
- Compilação do backend com sucesso no .NET 10.

Os testes de validação foram realizados pelo Swagger.

## Pendências relacionadas

- Melhorar o tratamento de tokens JWT expirados e das mensagens de erro no aplicativo.
- Implementar persistência local com SQLite e sincronização no RF40.
- A exclusão já está implementada, mas seu teste funcional não foi realizado nesta etapa de validação.
  