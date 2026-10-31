#  Sistema Web de Pedidos para Restaurante
> **Projeto Integrador Multidisciplinar (PIM III) – Universidade Paulista (UNIP)**

##  Objetivo
Desenvolver um sistema web completo e intuitivo para a gestão de pedidos de um restaurante. O foco da aplicação é oferecer um fluxo de navegação simples e direto, permitindo que o cliente final visualize o cardápio e realize pedidos com facilidade, enquanto a equipe interna gerencia a operação de forma ágil e eficiente.

---

##  Escopo do Projeto (MVP)

A aplicação foi dividida em dois módulos principais para atender às necessidades do negócio:

###  Área do Cliente
- [x] **Catálogo Digital:** Visualização dinâmica do cardápio de produtos.
- [x] **Carrinho de Compras:** Gestão temporária de itens selecionados.
- [x] **Checkout Simplificado: finalização de pedido com captura de dados essenciais (Nome, Telefone, Modalidade: Entrega/Retirada e Endereço para entrega quando aplicável).
- [x] **Confirmação:** Feedback visual de pedido realizado com sucesso.

###  Área Administrativa
- [x] **Autenticação:** Sistema de login seguro para o administrador.
- [x] **Gestão de Estoque (CRUD):** Criação, leitura, atualização e exclusão de produtos do cardápio.
- [x] **Painel de Controle:** Visualização de todos os pedidos recebidos.
- [x] **Workflow de Status:** Alteração e acompanhamento do status operacional de cada pedido.
- [x] **Business Intelligence:** Geração de relatórios gerenciais simplificados (ex: total de vendas do dia).

---

##  Arquitetura e Tecnologias

O ecossistema do projeto foi construído utilizando as seguintes tecnologias:

* **Frontend:** HTML5, CSS3 e JavaScript (Vanilla)
* **Backend:** C# com ASP.NET Core Web API
* **Banco de Dados:** PostgreSQL

---

##  Estrutura do Projeto

A organização de pastas segue os padrões de mercado para separação de responsabilidades (Clean Architecture):

```text
 raiz-do-projeto
 ┣  backend/           # API REST em C# (ASP.NET Core), Controllers e Models
 ┣  database/          # Scripts SQL de criação e população do PostgreSQL
 ┣  frontend/          # Interfaces do usuário (HTML, CSS, JS) e assets
 ┗  README.md          # Documentação central do projeto

## Acessos da equipe
O painel possui a opção **Gerenciar colaboradores**, exclusiva do perfil Administrador. É possível listar, criar, editar nome/e-mail/perfil e excluir acessos. A conta existente admin@pim.com recebe o perfil Administrador na migração, mantendo sua senha.

Novos acessos recebem uma senha provisória aleatória, exibida apenas na resposta do cadastro para o administrador entregar ao usuário. No primeiro login, um token restrito de 15 minutos permite apenas definir a senha pessoal (mínimo 8 caracteres, máximo 72 bytes UTF-8). O painel só é liberado após a troca; a senha provisória deixa de funcionar. Alterações no acesso e exclusões invalidam os tokens anteriores. Colaboradores continuam operando pedidos/produtos, sem gerenciar usuários. O último administrador com acesso liberado não pode ser removido ou rebaixado, e a própria conta não pode ser excluída.

Em bancos existentes, aplicar somente database/migrations/002_acessos_colaboradores.sql. Não executar schema.sql, pois recria tabelas. A migração já foi aplicada ao banco local. Reiniciar a API e entrar novamente após atualizar.

Testes: node --test tests/colaboradores-frontend.test.cjs; node tests/colaboradores-api.test.cjs. O teste de API usa localhost:5163 por padrão (PIM_TEST_API permite mudar) e credenciais do seed, substituíveis por PIM_TEST_ADMIN_EMAIL/PIM_TEST_ADMIN_PASSWORD. Ele cria e remove acessos próprios para testar o fluxo, sem modificar pedidos.

O botão **Resetar senha** no gerenciador de colaboradores gera outra senha provisória, invalida a senha e sessões anteriores e exige nova troca no próximo acesso. Apenas administradores podem usar POST /api/Colaboradores/{id}/resetar-senha. A senha aparece uma única vez no pop-up, com Copiar senha e OK. O reset da própria conta é bloqueado: solicite a outro administrador.


## Produtos kit / combos
No cadastro de produtos, marque **Produto kit**, adicione os produtos individuais e a quantidade de cada componente. Cada tamanho/sabor de pizza pode ser cadastrado como um produto separado, com estoque próprio. O preço do kit é independente da soma dos componentes. O estoque exibido representa quantos kits completos podem ser montados; o kit não possui saldo próprio.

Combos existentes não são convertidos automaticamente: edite cada um e vincule os componentes corretos. Não é permitido incluir outro kit, o próprio kit, componentes duplicados ou quantidades não positivas. Produtos usados em kits ou pedidos não podem ser excluídos; podem ser desativados.

A venda soma componentes compartilhados por kits e itens avulsos e valida o estoque dentro da transação. Registros de baixa preservam a composição da venda, permitindo devolver os produtos originais ao cancelar mesmo após editar o kit. O cancelamento pela tela administrativa também devolve estoque; repetir cancelamento não repõe novamente.

A migração database/migrations/003_produtos_kit.sql já foi aplicada ao banco local, preservando os produtos e pedidos. Para outro banco existente, execute apenas a migração. Testes: node --test tests/kits-frontend.test.cjs. O teste tests/kits-api.test.cjs exige PIM_TEST_CLEANUP_SQL apontando para um arquivo temporário; após a execução, aplicar esse SQL para remover os produtos/pedidos criados no teste.


## Entity Framework Core e Data Annotations
O backend usa PimDbContext com o provedor Npgsql para PostgreSQL, repositórios em LINQ e migrations do EF Core. DTOs validam os dados com Data Annotations e retornam HTTP 400 por campo. O banco local foi preservado e registrado na baseline do EF. Consulte docs/09_entity_framework.md para arquitetura, atualização de bancos existentes e comandos de migrations.


## Instalar ou atualizar o banco em outra máquina

O backend utiliza PostgreSQL, Entity Framework Core e User Secrets.

Cada integrante deve configurar sua própria conexão PostgreSQL
e chave JWT utilizando User Secrets, sem armazenar senhas
no appsettings.json.

Após configurar o ambiente, execute na raiz do projeto:

./Atualizar-Banco.ps1

O script aplica as migrations necessárias, preservando os
dados de bancos existentes compatíveis.

Para instruções completas, consulte:
docs/10_instalacao_banco.md

ATENÇÃO: não execute database/schema.sql em bancos
que já possuem dados.


## Sessão por inatividade
A área administrativa web encerra a sessão após aproximadamente 30 minutos sem interação e avisa no último minuto. A atividade é compartilhada entre abas; requisições e atualizações automáticas não renovam o prazo. O botão Continuar conectado renova a atividade antes do vencimento. A API também verifica o prazo por sessão e rejeita tokens inativos, sem permitir reativá-los. O token mantém o limite absoluto de 8 horas, e o primeiro acesso continua com token restrito de 15 minutos. O mobile informa atividade por toque e redireciona para o login ao detectar expiração; o aviso antecipado está implementado no web. A migration SessaoPorInatividade cria sessao_acesso e é aplicada por Atualizar-Banco.ps1. Após atualizar, entre novamente para emitir um token com identificação de sessão.


## Credenciais locais e proteção do Git
Configure o banco e a chave JWT em backend/appsettings.Local.json (ignorado), usando backend/appsettings.Local.example.json como modelo. O appsettings.json compartilhado não contém segredos. Ative a verificação antes dos commits com `node scripts/instalar-verificacao-git.cjs`. Veja docs/12_seguranca_git.md para a instalação, rotação de senhas já expostas e limitações da verificação.

Também é possível usar backend/appsettings.Local.json (ignorado pelo Git), conforme docs/12_seguranca_git.md. Em Development, User Secrets tem precedência sobre esse arquivo; variáveis de ambiente têm precedência sobre ambos.
