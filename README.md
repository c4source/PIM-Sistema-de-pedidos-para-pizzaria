# Madalena Pizzaria

Projeto Integrador Multidisciplinar IV (PIM IV) · Universidade Paulista (UNIP)

Sistema de pedidos e gestão de estoque para uma pizzaria. O cliente faz o pedido pelo site. A equipe acompanha a operação no painel web e consulta ou movimenta o estoque pelo aplicativo Android **Pizzaria Equipe**.

## Funcionalidades

| Módulo | O que permite fazer |
| --- | --- |
| Cardápio web | Consultar produtos e combos, montar o carrinho e finalizar pedidos para entrega ou retirada sem criar conta. |
| Painel administrativo web | Acompanhar pedidos, atualizar etapas de preparo, cancelar pedidos e gerenciar o catálogo, os combos e os acessos da equipe. |
| Aplicativo Android | Consultar produtos e saldos, registrar entradas, saídas e contagens, acompanhar o histórico e gerenciar acessos conforme o perfil. |
| Estoque offline | Consultar o catálogo salvo no aparelho e registrar movimentações em uma fila local para envio quando a API voltar a ficar acessível. |

## Arquitetura

| Pasta | Tecnologia e responsabilidade |
| --- | --- |
| [frontend/](frontend/) | HTML, CSS e JavaScript para o cardápio, o checkout e o painel administrativo. |
| [backend/](backend/) | API REST em C# com ASP.NET Core (.NET 10), validação de DTOs com Data Annotations e acesso ao PostgreSQL via Entity Framework Core e Npgsql. |
| [mobile/](mobile/) | App em Flutter e Dart, com SQLite para o catálogo e a fila local e armazenamento seguro para o token da sessão. |
| [database/](database/) | Scripts de estrutura e dados demonstrativos do PostgreSQL. |
| [docs/](docs/) e [diagrams/](diagrams/) | Guias de instalação, documentação técnica e diagramas do sistema. |

O site e o app se comunicam com a mesma API. O PostgreSQL mantém o estoque oficial compartilhado. O SQLite guarda dados de consulta e lançamentos do aparelho. A sincronização passa pela API, que aplica as mesmas regras de estoque usadas nas operações online.

## Como executar localmente

Você precisa do **.NET SDK 10** e de uma instância PostgreSQL em execução. Para o site, use o VS Code com Live Server ou outro servidor de arquivos estáticos. Para o app Android, instale o Flutter com Dart compatível com o [pubspec.yaml](mobile/pubspec.yaml), o Android SDK e tenha um emulador ou um celular com depuração USB.

### 1. Configurar o banco

Crie um banco PostgreSQL para o projeto. Configure a conexão em `ConnectionStrings:DefaultConnection` e a chave de assinatura em `Jwt:Key` usando **User Secrets**. O guia também descreve a opção de usar o arquivo local ignorado pelo Git. [Instalação e configuração do banco](docs/10_instalacao_banco.md)

No PowerShell, na raiz do repositório, aplique as migrations:

```powershell
.\Atualizar-Banco.ps1
```

Para uma instalação por SQL em um banco vazio, execute [schema.sql](database/schema.sql). Se quiser popular um ambiente de demonstração com catálogo, combos e pedidos, execute [seed.sql](database/seed.sql) no mesmo banco após criar a estrutura. O seed cria um administrador demonstrativo quando ainda não existe um e exige troca da senha no primeiro acesso. Consulte o [guia de instalação](docs/10_instalacao_banco.md) para usar os dados de demonstração ou atualizar um banco existente.

### 2. Iniciar a API

Em outro terminal, na raiz do projeto:

```powershell
dotnet run --project backend/Pim.csproj --launch-profile http
```

Mantenha o terminal aberto. A API local usa a porta **5162**. Confira se ela está respondendo pelo [Swagger](http://localhost:5162/swagger/index.html).

### 3. Abrir o site e o painel

Abra **a raiz do repositório** no VS Code. Inicie o Live Server a partir de `frontend/html/index.html` para que o servidor também encontre as imagens em `/img`.

| Página | Endereço com a porta padrão do Live Server |
| --- | --- |
| Cardápio e pedidos | [Abrir cardápio](http://127.0.0.1:5500/frontend/html/index.html) |
| Área da equipe | [Abrir painel administrativo](http://127.0.0.1:5500/frontend/html/admin-login.html) |

Se o Live Server escolher outra porta, use a porta indicada no navegador.

### 4. Rodar o aplicativo Android

Abra a pasta `mobile` no Android Studio ou acesse-a pelo terminal. Com a API rodando, instale as dependências e liste os dispositivos disponíveis:

```powershell
cd mobile
flutter pub get
flutter devices
```

**No emulador Android**, use o ID listado por `flutter devices`. O endereço padrão do app, `http://10.0.2.2:5162`, aponta para a API no computador.

```powershell
flutter run -d ID_DO_EMULADOR
```

**No celular físico por USB**, ative a depuração USB e aceite a autorização no aparelho. Com o `adb` disponível no terminal (ele fica em `platform-tools` no Android SDK), encaminhe a porta da API e execute:

```powershell
adb -s ID_DO_CELULAR reverse tcp:5162 tcp:5162
flutter run -d ID_DO_CELULAR --dart-define=PIM_API_URL=http://127.0.0.1:5162
```

Substitua os IDs pelos valores listados em `flutter devices`. Ao desconectar o USB, o app permanece instalado e perde o acesso à API por esse caminho. Reconecte o cabo e execute o comando `adb reverse` novamente para retomar a comunicação.

## Regras de operação

- **Combos.** Cada combo tem preço próprio e sua capacidade depende dos componentes disponíveis. A venda registra os itens físicos que foram baixados. O cancelamento usa esse registro para devolver os componentes originais, mesmo se a composição do combo tiver mudado.
- **Sincronização.** O app grava cada movimentação localmente com um UUID antes de tentar enviá-la. A API reconhece reenvios da mesma operação, valida o saldo atual e confirma a alteração e o histórico em uma transação. Uma rejeição de negócio aparece como **Requer atenção**.
- **Contagem.** O app envia o saldo de referência e a quantidade encontrada. Se o saldo oficial tiver mudado, a API rejeita a contagem para que o operador confira o estoque novamente.
- **Acessos.** O administrador gerencia colaboradores e pode gerar senhas provisórias. O primeiro acesso após cadastro ou reset exige troca de senha. A API valida o perfil, a validade da sessão e a inatividade.

### Demonstração do modo offline

1. Faça login com a API disponível e abra **Estoque** para carregar o catálogo.
2. Desconecte o aparelho da API e registre uma entrada ou saída de um produto de teste. Confira o estado **Pendente** em **Movimentações**.
3. Restabeleça a conexão e mantenha o app aberto. A sincronização tenta enviar a fila ao voltar ao primeiro plano e em ciclos de 20 segundos. Confira o lançamento confirmado e o saldo atualizado.
4. Para demonstrar um conflito, carregue um produto com saldo de 8, desconecte o mobile e reduza o saldo para 7 pelo painel web. Registre uma saída de 8 no app e reconecte. O lançamento deve ficar **Requer atenção** e o saldo oficial deve permanecer em 7.

O primeiro login, a edição de cadastros e o gerenciamento de colaboradores precisam de conexão. A fila pertence à conta que a criou e é processada com o app em uso.

## Testes e documentação

- **Mobile.** Na pasta `mobile`, execute `flutter analyze` e `flutter test`. Os testes cobrem catálogo local, fila e telas.
- **Web.** Execute `node --test tests/produtos-ui.test.cjs tests/checkout-feedback.test.cjs tests/kits-frontend.test.cjs` na raiz.
- **Integração.** Os testes de API e scripts SQL em [tests/](tests/) usam banco de desenvolvimento. Consulte os guias antes de rodá-los, pois criam dados de teste.

| Guia | Conteúdo |
| --- | --- |
| [Instalação do banco](docs/10_instalacao_banco.md) | User Secrets, migrations, instalação via SQL e seed. |
| [Modelagem do banco](docs/08_modelagem_database.md) e [diagramas](diagrams/banco_atual/) | Estrutura do PostgreSQL e do SQLite, dicionário de dados e fluxos de sincronização e kits. |
| [Entity Framework Core](docs/09_entity_framework.md) | Persistência, validação e evolução do backend. |
| [Persistência no mobile](docs/pim4/persistencia_local_mobile.md) | Catálogo salvo, fila, reenvio e limites do modo offline. |
| [Operação no mobile](docs/pim4/melhorias_mobile.md) | Ajustes, contagem, alertas e gestão de acessos. |
| [Credenciais e Git](docs/12_seguranca_git.md) | Configuração local e verificação de segredos antes de commits. |
