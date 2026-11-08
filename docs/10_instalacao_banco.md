# Instalação e atualização do banco — PIM IV

Este guia explica como configurar **o backend ASP.NET Core (.NET 10)** com **PostgreSQL**, **Entity Framework Core** e **User Secrets**, tanto em uma instalação nova quanto em um banco já utilizado no PIM III/IV.

> **Regra principal:** cada integrante usa seu próprio banco e suas próprias credenciais. Não coloque senhas de banco nem chaves JWT no GitHub.

## 1. Pré-requisitos

- .NET SDK 10 instalado (`dotnet --version`).
- PostgreSQL em execução (o projeto foi testado com PostgreSQL 18).
- pgAdmin 4 para administrar o banco e conferir os dados.
- Repositório atualizado com as alterações integradas na branch `develop`.

Execute os comandos a seguir no **PowerShell, na pasta raiz do repositório** (`pim-3`), exceto quando indicado de outra forma.

## 2. Configurações locais com User Secrets

O arquivo versionado `backend/appsettings.json` deve conter os valores sensíveis vazios:

```json
"ConnectionStrings": {
  "DefaultConnection": ""
},
"Jwt": {
  "Key": "",
  "Issuer": "PimApi",
  "Audience": "PimFront"
}
```

Este é **um trecho** do arquivo, não seu conteúdo completo. Mantenha também as demais configurações existentes.

O identificador `UserSecretsId` já faz parte de `backend/Pim.csproj` e é compartilhado no Git. Portanto, **não é preciso executar `dotnet user-secrets init` novamente**. Os valores secretos ficam no computador de cada desenvolvedor, fora do repositório.

### 2.1. Configurar sua conexão PostgreSQL

Tenha um banco local criado no pgAdmin, como `pim`, `pim_3` ou outro nome de sua preferência. Se o PostgreSQL usa `localhost:5432` e o usuário `postgres`, execute:

```powershell
$banco = Read-Host "Nome do seu banco PostgreSQL (ex.: pim_3)"
$senhaSegura = Read-Host "Senha do PostgreSQL" -AsSecureString
$senha = [System.Net.NetworkCredential]::new('', $senhaSegura).Password
$conexao = "Host=localhost;Port=5432;Database=$banco;Username=postgres;Password=${senha}"

@{ ConnectionStrings = @{ DefaultConnection = $conexao } } |
    ConvertTo-Json -Depth 3 |
    dotnet user-secrets set --project backend/Pim.csproj

Remove-Variable senha, senhaSegura, conexao
```

A senha é solicitada sem aparecer na tela e não precisa ser escrita no `appsettings.json`. Altere `Host`, `Port` ou `Username` no exemplo **se a sua instalação for diferente**.

### 2.2. Gerar sua chave JWT

Cada desenvolvedor pode ter uma chave própria, pois cada um executa sua API local. No PowerShell:

```powershell
$bytes = New-Object byte[] 48
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$rng.Dispose()

$jwtKey = [Convert]::ToBase64String($bytes)
dotnet user-secrets set "Jwt:Key" "$jwtKey" --project backend/Pim.csproj

Remove-Variable jwtKey, bytes
```

**Não compartilhe a chave JWT nem os tokens gerados no Swagger.** Alterar a chave invalida os tokens antigos: nesse caso, basta fazer login novamente no navegador ou aplicativo.

> User Secrets é um recurso de configuração **para desenvolvimento**, não um cofre criptografado para produção. Em produção, as credenciais precisam vir de um gerenciador de segredos ou de configurações seguras do ambiente.

## 3. Antes de atualizar um banco existente: backup

Se o banco já possui produtos, usuários, pedidos ou movimentações:

1. No pgAdmin, clique com o botão direito no banco utilizado pelo projeto.
2. Escolha **Backup...**.
3. Selecione **Format: Custom** e um arquivo `.dump` fora da pasta do repositório.
4. Aguarde a mensagem **Process completed** e confirme que o arquivo foi criado.

O `database/schema.sql` atual não apaga tabelas: ele contém as migrations incrementais do EF. Para bancos antigos sem histórico EF, use `Atualizar-Banco.ps1`, que reconhece a baseline antes de atualizar. Faça backup antes de atualizar um banco de uso.

## 4. Atualizar ou criar as tabelas

A aplicação possui um atualizador que trata dois cenários:

- **Banco vazio:** aplica as migrations do Entity Framework para criar a estrutura atual.
- **Banco antigo compatível:** aplica os ajustes incrementais de colaboradores e kits, registra a estrutura existente na baseline do EF e aplica as migrations restantes, preservando os dados.

Com o ambiente `Development` configurado pelo perfil de execução do backend, execute **na raiz do projeto**:

```powershell
dotnet run --project backend/Pim.csproj -- --atualizar-banco
```

Espere aparecer:

```text
Banco atualizado com sucesso. Dados existentes preservados.
```

Esse comando **atualiza o banco e encerra**; ele não mantém a API aberta.

### Atenção ao ambiente Development

O User Secrets só é carregado automaticamente quando o ambiente da aplicação é `Development`.

O comando recomendado acima utiliza o perfil de execução local do projeto, que já inicializa o backend em `Development`. **Não use `--no-launch-profile` isoladamente** após retirar as credenciais do `appsettings.json`, pois ele pode executar em outro ambiente e não encontrar os segredos.

Se for necessário executar sem o perfil, defina explicitamente o ambiente na mesma sessão do PowerShell:

```powershell
$env:ASPNETCORE_ENVIRONMENT = 'Development'
$env:DOTNET_ENVIRONMENT = 'Development'
dotnet run --project backend/Pim.csproj --no-launch-profile -- --atualizar-banco
```

O script `Atualizar-Banco.ps1` já configura automaticamente o ambiente `Development`, permitindo carregar os User Secrets mesmo utilizando `--no-launch-profile`.

Portanto, também é possível atualizar o banco pela raiz do projeto executando:

```powershell
.\Atualizar-Banco.ps1
```

## 5. Conferir a atualização no pgAdmin

Conecte-se **ao mesmo banco configurado no User Secrets** e execute:

```sql
SELECT
    to_regclass('public.produto') AS produto,
    to_regclass('public.colaborador') AS colaborador,
    to_regclass('public.movimentacao_estoque') AS movimentacao_estoque,
    to_regclass('public.kit_componente') AS kit_componente,
    to_regclass('public."__EFMigrationsHistory"') AS historico_migrations;
```

As cinco colunas devem indicar tabelas existentes, sem valores `NULL`.

Para conferir a quantidade de migrations e movimentações:

```sql
SELECT
    (SELECT COUNT(*) FROM "__EFMigrationsHistory") AS migrations,
    (SELECT COUNT(*) FROM movimentacao_estoque) AS movimentacoes;
```

Na versão de 31/10/2026, são **8 migrations**, incluindo sessões, UUID de sincronização, motivos/contagens, estoque mínimo e suspensão de acessos. A quantidade de movimentações depende dos dados de cada instalação.

### Migration de movimentação de estoque

A migration `AdicionaMovimentacaoEstoque` registra essa tabela no modelo do EF Core e usa `CREATE TABLE IF NOT EXISTS`, pois ela já existia em instalações anteriores do PIM IV. Também cria índices quando necessário.

- Em banco novo, a migration cria a tabela.
- Em banco existente com estrutura compatível, a tabela e seus registros são preservados.
- `IF NOT EXISTS` **não valida uma estrutura incompatível**. Se o banco não tiver o schema esperado, interrompa o processo e investigue.
- A reversão automática (`Down`) dessa migration foi bloqueada para evitar apagar um histórico preexistente.

A movimentação de estoque utiliza **Entity Framework Core**. O saldo e o histórico são gravados na mesma transação; o índice único de `operacao_id` permite reenviar operações sem duplicar lançamentos.

## 6. Iniciar e testar a API

Na raiz do repositório:

```powershell
dotnet build backend/Pim.csproj
dotnet run --project backend/Pim.csproj
```

Utilize a porta mostrada no terminal. No ambiente testado, a API iniciou em `http://localhost:5162`.

Abra o Swagger em `http://localhost:5162/swagger` (ajuste a porta se necessário). Verifique:

1. `GET /api/Produto`: retorna o catálogo do PostgreSQL.
2. `POST /api/Auth/login-colaborador`: autentica um usuário existente e retorna um JWT.
3. `GET /api/Colaboradores`: exige um JWT com perfil `Administrador`.
4. `POST /api/MovimentacaoEstoque`: aceita `Administrador` e `Colaborador`, conforme as regras atuais do projeto.

Um banco novo não recebe dados automaticamente. O seed demonstrativo é opcional: consulte a seção abaixo para instalar pelos scripts e conhecer o acesso inicial.

## 7. Entity Framework: ferramentas e novas migrations

A ferramenta local do projeto pode ser instalada/restaurada com:

```powershell
dotnet tool restore
```

Para listar as migrations, sem aplicá-las:

```powershell
dotnet ef migrations list --project backend/Pim.csproj
```

Para futuras mudanças de modelo, a equipe deve revisar toda migration gerada antes de aplicá-la, especialmente se a tabela já existir. Consulte também [`09_entity_framework.md`](./09_entity_framework.md).

## 8. Problemas comuns e cuidados da equipe

- **Erro de conexão / banco inexistente:** confirme nome do banco, porta, usuário, senha e se o PostgreSQL está ligado.
- **O login funcionava antes e agora retorna 401:** a chave JWT pode ter mudado; faça login novamente para receber outro token.
- **Acesso 403:** confirme o perfil do usuário e as permissões exigidas pelo endpoint.
- **Falha ao usar `--no-launch-profile`:** confira se `Development` está realmente ativo, para que o User Secrets seja carregado.
- **Migration falhou:** não execute `schema.sql`, não apague tabelas e não tente reverter migrations automaticamente. Guarde o erro e revise o backup.
- **Trabalho em equipe:** cada integrante configura seu próprio User Secrets. O `git pull` traz o `UserSecretsId` e o código, **não traz senhas nem chaves locais**.
- **Segredo já publicado no GitHub:** remover do `appsettings.json` não apaga os commits antigos. Se a credencial era real, ela deve ser alterada/rotacionada.

**Nunca faça commit de senhas, strings de conexão com credenciais ou chaves JWT reais.**

## Alternativa: arquivo local ignorado

Também é possível copiar backend/appsettings.Local.example.json para backend/appsettings.Local.json e preencher a conexão e uma chave JWT aleatória. Esse arquivo não deve ser commitado nem publicado. Em Development, User Secrets tem precedência sobre esse arquivo. Variáveis de ambiente têm precedência sobre ambos. Para detalhes da proteção antes dos commits, consulte 12_seguranca_git.md.

## 9. Criar o banco diretamente pelos scripts SQL

Este caminho não exige executar a API nem as ferramentas EF para criar as tabelas. PostgreSQL precisa estar instalado e em execução.

1. Crie um banco vazio no pgAdmin, por exemplo `pim`, e conecte o Query Tool a ele.
2. Abra **database/schema.sql** e execute o arquivo completo. Ele cria a estrutura atual e registra as oito migrations em `__EFMigrationsHistory`.
3. Opcionalmente, abra **database/seed.sql** e execute o arquivo completo no mesmo banco. O seed instala os dados acadêmicos; a estrutura sem seed também é válida.
4. Configure a conexão desse banco e a chave JWT no backend conforme a seção 2. Inicie a API normalmente.

Alternativamente, na raiz do repositório, com psql no PATH:

```powershell
psql -X -h localhost -U postgres -d pim -v ON_ERROR_STOP=1 -f database/schema.sql
psql -X -h localhost -U postgres -d pim -v ON_ERROR_STOP=1 -f database/seed.sql
```

A senha do PostgreSQL é solicitada pelo psql quando necessário. Não coloque a senha no comando nem no Git. O schema pressupõe a instalação no schema PostgreSQL `public`.

### Reexecução e atualização

- **Schema:** pode ser executado novamente. Aplica apenas migrations ainda não registradas, sem apagar registros. Em banco legado sem baseline EF, interrompe a execução antes de criar ou apagar tabelas e orienta usar Atualizar-Banco.ps1.
- **Seed:** a primeira execução exige produtos e pedidos vazios. Uma transação inclui produtos, kits, pedidos, pagamentos e baixas. A tabela `pim_seed_historico` registra a versão; repetir o mesmo seed não altera senhas, saldos, preços, nomes nem pedidos, mesmo depois de editar os dados na aplicação.
- **Banco já em uso sem marca do seed:** o seed recusa inserir dados demonstrativos. Use os cadastros da aplicação; não apague registros para tentar popular novamente.
- **EF após instalação SQL:** Atualizar-Banco.ps1 reconhece o histórico preenchido pelo schema. Não é necessário executar manualmente as antigas migrations SQL 002/003/004.
- O arquivo `backend/Data/schema-ecommerce-restaurante.sql` é histórico, com sintaxe MySQL, e não faz parte desta instalação.

### Dados de demonstração e primeiro acesso

O seed cria **25 produtos**, incluindo duas pizzas broto e **3 kits com 7 vínculos de componentes**. Kits não têm estoque próprio: a capacidade resulta dos componentes. Também cria dois pedidos, três itens, pagamentos e respectivas baixas, com o estoque já descontado para permitir cancelamento coerente. IDs são obtidos do banco; não dependem de sequências começando em 1.

Se não houver administrador, é criado **admin@pim.com**, com senha demonstrativa **123456** e **troca obrigatória no primeiro acesso**. Esse token inicial permite somente trocar a senha. Se já existir um administrador, nenhum acesso demonstrativo adicional é criado e suas credenciais são preservadas. Os testes de API que precisam de sessão normal devem receber as credenciais definitivas por PIM_TEST_ADMIN_EMAIL e PIM_TEST_ADMIN_PASSWORD.

O seed usa a extensão PostgreSQL `pgcrypto` para gerar o hash BCrypt. O usuário que executa o seed precisa de permissão para instalar essa extensão, ou ela deve ter sido instalada pelo administrador do PostgreSQL.

### Manutenção e verificação

O corpo de schema.sql é gerado por `dotnet ef migrations script 0 --idempotent --project backend/Pim.csproj`. Ao incluir novas migrations, regenere o corpo e mantenha a proteção inicial de banco legado e a visão de compatibilidade final. Não registre uma migration no histórico sem executar suas alterações.

O teste de integração `tests/banco-scripts.test.ps1` cria e remove bancos temporários para conferir instalação SQL, reexecução, preservação de alterações, kits, IDs não sequenciais, recusa de seed em banco usado e compatibilidade com o atualizador EF. Requer psql, backend compilado e usuário PostgreSQL com permissão de criar bancos.
