# Visão Geral — PIM IV

## Contexto

O PIM IV representa a continuidade e evolução do sistema desenvolvido no PIM III para a Madalena Pizzaria.

No PIM III foi desenvolvido um sistema web de pedidos, composto por uma área pública para realização de pedidos e uma área administrativa para gerenciamento da operação da pizzaria.

No PIM IV, o sistema existente será mantido como base e receberá novas funcionalidades e melhorias relacionadas às disciplinas do quarto semestre.


---

## Proposta do PIM IV

A principal evolução do sistema será a criação de um aplicativo mobile interno para utilização pelos funcionários da pizzaria.

O aplicativo não será destinado aos clientes. O cliente continuará utilizando o sistema web existente para consultar o cardápio e realizar pedidos.

O aplicativo mobile terá foco nas operações administrativas da pizzaria, permitindo que funcionários autenticados tenham acesso às funcionalidades internas do sistema.

Entre as principais funcionalidades previstas estão:

- autenticação de funcionários;
- tela inicial administrativa;
- gerenciamento de produtos;
- controle de estoque;
- registro de entrada e saída de produtos;
- consulta de movimentações de estoque;
- gestão de usuários/funcionários.

---

## Integração da Solução

O sistema será composto por diferentes aplicações integradas.

```text
Sistema Web
    │
    │
    ▼
API REST em C# / .NET
    │
    ▼
PostgreSQL
    ▲
    │
    │
Aplicativo Mobile
Flutter + Dart
    │
    └── SQLite para armazenamento local
```

    
## Evolução do PIM III

As funcionalidades implementadas no PIM III permanecem como parte do sistema.

O PIM IV não representa a criação de um novo projeto, mas a evolução da solução já existente, incorporando novas funcionalidades e tecnologias relacionadas às disciplinas do quarto semestre.

Do backlog de expansão elaborado no PIM III, foi selecionado para implementação o requisito:

### RF30 — Gestão de Usuários

O sistema permitirá que o administrador gerencie os usuários responsáveis pelo acesso ao ambiente interno da pizzaria.

A gestão de usuários deverá permitir:

- cadastrar usuários;
- consultar usuários cadastrados;
- editar informações dos usuários;
- ativar ou inativar usuários.

Os usuários cadastrados representarão funcionários da pizzaria que poderão acessar as funcionalidades administrativas do sistema.

---

## Tecnologias Previstas

### Aplicação Web

- HTML;
- CSS;
- JavaScript.

### Backend e API

- C#;
- ASP.NET Core;
- API REST.

### Aplicação Mobile

- Flutter;
- Dart;
- SQLite.

### Banco de Dados

- PostgreSQL.

### Gerenciamento do Projeto

- Git;
- GitHub;
- Trello;
- Kanban.

---

## Objetivo do PIM IV

O objetivo do PIM IV é evoluir o sistema da pizzaria para uma solução integrada, permitindo que a aplicação web, o aplicativo mobile, a API e o banco de dados trabalhem de forma conjunta.

A evolução deverá aplicar os conhecimentos adquiridos nas disciplinas do quarto semestre, mantendo o escopo do projeto controlado e priorizando as funcionalidades necessárias para o funcionamento da solução.