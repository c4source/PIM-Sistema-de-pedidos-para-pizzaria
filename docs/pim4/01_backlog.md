# Product Backlog — PIM IV

## Contexto

O PIM IV representa a evolução do sistema desenvolvido no PIM III para a Madalena Pizzaria.

As funcionalidades já implementadas permanecem como base da solução. Neste novo ciclo serão adicionadas funcionalidades e requisitos relacionados às disciplinas do quarto semestre.

A principal evolução será o desenvolvimento de um aplicativo mobile interno destinado aos funcionários da pizzaria, integrado à API e ao banco de dados já existentes.

---

# 1. Requisitos Funcionais

Os requisitos funcionais descrevem as funcionalidades que o sistema deverá disponibilizar aos seus usuários.

| Código | Requisito | Descrição | Prioridade |
|---|---|---|---|
| RF30 | Gestão de Usuários | Permitir que o administrador cadastre, consulte, edite e ative ou inative usuários/funcionários do sistema interno. | Alta |
| RF33 | Autenticação de Funcionários | Permitir que funcionários cadastrados realizem login no aplicativo mobile utilizando suas credenciais. Usuários inválidos ou inativos não poderão acessar o sistema. | Alta |
| RF34 | Tela Inicial Administrativa | Disponibilizar, após o login, uma tela inicial com acesso às funcionalidades de produtos, movimentações de estoque e usuários. | Alta |
| RF35 | Gerenciamento de Produtos pelo Mobile | Permitir que funcionários autorizados consultem, cadastrem e editem produtos por meio do aplicativo mobile. | Alta |
| RF36 | Controle de Estoque | Manter e atualizar a quantidade disponível dos produtos controlados pelo estoque. | Alta |
| RF37 | Entrada de Estoque | Permitir registrar entradas de produtos, informando produto, quantidade, data/hora e usuário responsável. | Alta |
| RF38 | Saída de Estoque | Permitir registrar saídas de produtos, impedindo movimentações superiores à quantidade disponível. | Alta |
| RF39 | Histórico de Movimentações | Permitir consultar o histórico de entradas e saídas de estoque, identificando produto, quantidade, tipo, data/hora e usuário responsável. | Alta |
| RF40 | Sincronização de Dados | Permitir a sincronização dos dados entre o armazenamento local do aplicativo e a API do sistema. | Alta |
| RF41 | Encerramento de Sessão | Permitir que o funcionário encerre sua sessão no aplicativo mobile. | Média |

---

# 2. Requisitos Não Funcionais

Os requisitos não funcionais definem tecnologias, padrões, restrições e características de qualidade da solução.

| Código | Categoria | Requisito | Prioridade |
|---|---|---|---|
| RNF10 | Tecnologia Mobile | O aplicativo mobile deverá ser desenvolvido utilizando Flutter e Dart. | Alta |
| RNF11 | Arquitetura Mobile | O aplicativo deverá possuir separação entre apresentação, gerenciamento de estado, repositórios e fontes de dados locais e remotas. | Alta |
| RNF12 | Gerenciamento de Estado | O aplicativo deverá utilizar `setState` e/ou `ChangeNotifier` para gerenciamento de estado, conforme a arquitetura definida para o projeto. | Alta |
| RNF13 | Persistência Local | O aplicativo deverá utilizar SQLite para armazenamento local dos dados necessários ao seu funcionamento. | Alta |
| RNF14 | Integração com API | A comunicação entre o aplicativo mobile e o backend deverá ser realizada por API REST utilizando HTTP e JSON. | Alta |
| RNF15 | Tecnologia Backend | O backend deverá utilizar C# e ASP.NET Core, evoluindo a API existente no PIM III. | Alta |
| RNF16 | Arquitetura .NET | O backend deverá aplicar orientação a objetos, organização em camadas e modularização. | Alta |
| RNF17 | Banco de Dados | O banco de dados principal deverá utilizar PostgreSQL e permanecer integrado às aplicações Web e Mobile por meio da API. | Alta |
| RNF18 | Segurança | O acesso às funcionalidades administrativas deverá exigir autenticação e impedir o acesso de usuários não autorizados ou inativos. | Alta |
| RNF19 | Armazenamento de Credenciais | Senhas de usuários não deverão ser armazenadas em texto puro. | Alta |
| RNF20 | Consistência de Estoque | O sistema deverá garantir que movimentações de estoque não resultem em quantidade negativa. | Alta |
| RNF21 | Manutenibilidade | O código deverá manter separação de responsabilidades, nomes claros e organização modular para facilitar manutenção e evolução. | Média |
| RNF22 | Banco de Dados Acadêmico | O projeto de banco deverá possuir modelo lógico, modelo físico, MER, procedures, triggers e script completo do banco utilizado pela solução. | Alta |

---

# 3. Requisitos Mantidos do PIM III

Os requisitos implementados no PIM III permanecem válidos e fazem parte da solução existente.

O Product Backlog do PIM IV concentra-se nas novas funcionalidades e nas alterações necessárias para integrar as disciplinas do quarto semestre.

---

# 4. Fora do Escopo Atual

Considerando o prazo disponível para desenvolvimento, os seguintes itens do backlog de expansão do PIM III não serão priorizados neste ciclo:

- cadastro de clientes;
- login de clientes;
- histórico de pedidos do cliente;
- pagamento online;
- integração com sistemas de pagamento;
- promoções e campanhas;
- notificações de status do pedido;
- configurações administrativas avançadas.

Esses itens permanecem registrados como possibilidades de evolução futura.

---

# 5. Observações

O backlog poderá ser atualizado caso novos requisitos obrigatórios sejam definidos pelos professores durante o desenvolvimento do PIM IV.

Os requisitos definidos neste documento serão utilizados como base para a organização das atividades no Trello e para o acompanhamento do desenvolvimento do projeto.