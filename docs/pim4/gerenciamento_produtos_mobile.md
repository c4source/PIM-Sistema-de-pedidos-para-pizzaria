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