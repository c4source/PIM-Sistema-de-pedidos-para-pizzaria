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

A listagem possui uma opção de exclusão para produtos comuns. Para produtos kit, o aplicativo exibe um cadeado e impede a exclusão, mantendo seu gerenciamento exclusivamente na Web.

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
git
- Implementar persistência local com SQLite e sincronização no RF40.
- A exclusão já está implementada, mas seu teste funcional não foi realizado nesta etapa de validação.
  

---

## Proteção dos Produtos Kit

### Descrição

O backend permite cadastrar produtos kit, compostos por
outros produtos individuais.

A criação e a edição da composição dos kits são realizadas
exclusivamente pelo sistema Web.

No aplicativo Flutter, foi implementada uma proteção para
impedir alterações indevidas nesses produtos.

### Implementação no Flutter

O modelo `Produto` recebeu o atributo `ehKit`, que identifica
se o produto é um kit a partir da resposta da API.

Na tela `ProdutosScreen`:

- Produtos comuns continuam permitindo edição e exclusão.
- Produtos kit exibem um cadeado no lugar da lixeira.
- Ao tocar em um kit, o aplicativo bloqueia sua edição.
- É apresentada a mensagem:
  "Kits devem ser editados pelo sistema Web."

Essa proteção evita que o aplicativo envie atualizações
incompletas que possam comprometer a composição dos kits.

### Integração

Flutter → ProdutoRepository → ProdutoApi
→ API ASP.NET Core → PostgreSQL

O aplicativo consulta normalmente todos os produtos,
incluindo kits, mas restringe suas operações de edição
e exclusão na interface.

### Testes realizados

- Criação do produto "Kit Teste Mobile" pela interface Web.
- Cadastro do kit com um componente: Água sem gás.
- Confirmação de `eh_kit = true` no PostgreSQL.
- Listagem do kit no aplicativo Flutter.
- Exibição do cadeado no lugar do botão de exclusão.
- Bloqueio da abertura da tela de edição.
- Exibição da mensagem informando que kits são
  gerenciados pelo sistema Web.
- `flutter analyze` sem erros.

### Resultado

A proteção dos produtos kit foi implementada e testada
com sucesso no aplicativo mobile.

O gerenciamento da composição dos kits permanece na Web,
enquanto o Flutter continua permitindo as operações
de produtos comuns.
