# Backend com Entity Framework Core e Data Annotations

O banco continua sendo PostgreSQL. O acesso da aplicação agora passa pelo PimDbContext, registrado por AddDbContext e UseNpgsql em Program.cs. Não há NpgsqlConnection, NpgsqlCommand nem leitura manual de NpgsqlDataReader nos repositórios.

## Organização
- Models: entidades com Table, Column, Key, Required e StringLength, entre outros atributos.
- DTOs: validação de entrada com Required, EmailAddress, Range, RegularExpression, MinLength e Compare. ApiController devolve HTTP 400 com erros por campo antes de executar a operação.
- Data/PimDbContext.cs: DbSets e configuração dos relacionamentos, chaves compostas, exclusão restrita, índices, precisão monetária e timestamps sem fuso, compatíveis com o banco existente.
- Repositories: consultas LINQ, AsNoTracking, Include/ThenInclude, SaveChangesAsync, ExecuteUpdateAsync e ExecuteDeleteAsync.
- Migrations: estrutura inicial e snapshot do modelo, além dos valores padrão já utilizados pelo banco.

Os atributos não substituem regras de negócio: autorização, composição válida de kits, último administrador e saldo suficiente continuam nas camadas de serviço/repositório.

## Transações e concorrência
Vendas e cancelamentos usam Database.BeginTransactionAsync. A aplicação soma os componentes dos kits com produtos avulsos e grava a baixa histórica na mesma transação. O cancelamento devolve a composição salva na venda, e uma atualização condicional impede a devolução duplicada. A versão da sessão é usada para invalidar tokens após alterações de acesso ou senha.

O SQL explícito restante nos repositórios se limita aos bloqueios de tabela, executados pelo próprio EF (Database.ExecuteSqlRawAsync), para manter a proteção concorrente já existente. O Npgsql permanece como provedor PostgreSQL e tipo de exceção, não como conexão manual.

## Banco local existente
A estrutura foi preservada. O script database/migrations/004_baseline_entity_framework.sql registrou a migration inicial como já existente, sem executar CREATE TABLE para tabelas de negócio. Depois, a migration PadroesBancoExistente foi aplicada pelo EF para alinhar os valores padrão, sem alterar os registros.

Para outra cópia do banco antigo: aplicar primeiro os scripts SQL 002 e 003, depois a baseline 004, e então rodar database update. Não aplicar a migration inicial de criação diretamente sobre tabelas existentes e não usar EnsureCreated/EnsureDeleted no banco atual. A baseline pressupõe uma cópia compatível com o schema e as migrações anteriores; não é uma ferramenta genérica de comparação de bancos.

## Ferramenta e migrations
Na raiz do projeto:

~~~powershell
dotnet tool restore
dotnet ef migrations has-pending-model-changes --project backend/Pim.csproj
dotnet ef database update --project backend/Pim.csproj
~~~

Para evoluir entidades:

~~~powershell
dotnet ef migrations add NomeDaAlteracao --project backend/Pim.csproj
# Revisar a migration gerada antes de aplicar.
dotnet ef database update --project backend/Pim.csproj
~~~

Para banco novo e vazio, configurar a conexão e aplicar database update. As migrations criam as tabelas; não criam automaticamente usuários ou produtos. O seed SQL existente pode ser aplicado para dados acadêmicos de demonstração.

## Verificação
- Compilação do backend e ausência de alterações pendentes no modelo.
- Testes de API de colaboradores: CRUD, perfis, troca obrigatória, reset e revogação de sessões.
- Testes de API de kits: composição, baixa agregada, concorrência e cancelamento histórico.
- tests/dataannotations-api.test.cjs: oito entradas inválidas retornam HTTP 400 com errors por campo.
- Testes frontend existentes: sessão e payload de kits.
- A migration inicial foi aplicada com sucesso em um banco PostgreSQL temporário, removido após a verificação.

Referências: https://www.npgsql.org/efcore/ e https://www.npgsql.org/efcore/release-notes/10.0.html
