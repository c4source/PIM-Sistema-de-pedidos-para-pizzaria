# RF34 — Tela Inicial Administrativa

Após a autenticação do funcionário, o aplicativo apresenta uma tela
inicial administrativa com acesso aos principais módulos do sistema.

## Estrutura da tela

A Home possui atalhos para:

- Usuários;
- Produtos;
- Estoque;
- Movimentações.

Os atalhos foram organizados em cards utilizando componentes do
Material Design do Flutter.

## Navegação

As rotas principais do aplicativo são centralizadas no arquivo
`core/rotas.dart`.

A navegação para cada módulo é conectada conforme sua funcionalidade
é implementada. O módulo de Produtos já possui navegação funcional
para a tela de gerenciamento de produtos.

## Fluxo

Login
→ autenticação realizada
→ Home administrativa
→ seleção do módulo
→ tela correspondente

## Resultado

O funcionário autenticado é direcionado para um painel administrativo
centralizado, que funciona como ponto de acesso às funcionalidades
internas do aplicativo.