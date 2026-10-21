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
$conexao = "Host=localhost;Port=5432;Database=$banco;Username=postgres;Password=$senha"

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

**Não execute `database/schema.sql` sobre um banco com dados.** Esse script pode recriar tabelas e causar perda de informações.

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

Na integração realizada em **20/10/2026**, o banco local `pim_3` terminou com **5 migrations e 6 movimentações preservadas**. Em outros bancos, a quantidade de movimentações pode ser diferente.

### Migration de movimentação de estoque

A migration `AdicionaMovimentacaoEstoque` registra essa tabela no modelo do EF Core e usa `CREATE TABLE IF NOT EXISTS`, pois ela já existia em instalações anteriores do PIM IV. Também cria índices quando necessário.

- Em banco novo, a migration cria a tabela.
- Em banco existente com estrutura compatível, a tabela e seus registros são preservados.
- `IF NOT EXISTS` **não valida uma estrutura incompatível**. Se o banco não tiver o schema esperado, interrompa o processo e investigue.
- A reversão automática (`Down`) dessa migration foi bloqueada para evitar apagar um histórico preexistente.

A movimentação de estoque continua usando **Npgsql diretamente no repositório**; o EF Core foi integrado para mapear sua entidade e gerenciar sua criação por migration.

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

Um banco novo não recebe automaticamente usuários e produtos de demonstração. O arquivo `database/seed.sql` é **opcional e deve ser aplicado somente em uma instalação acadêmica nova**, após conferir seu conteúdo; **não o execute em bancos existentes**.

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
