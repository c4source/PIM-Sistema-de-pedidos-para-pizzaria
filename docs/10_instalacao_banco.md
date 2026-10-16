# Instalação e atualização do banco

Instale o SDK .NET 10 e o PostgreSQL. Configure Host, Port, Database, Username e Password em backend/appsettings.json para o banco da máquina. O usuário PostgreSQL precisa poder criar/alterar tabelas; para criar o banco automaticamente, precisa também de permissão CREATEDB. Se não tiver, crie o banco vazio previamente.

Na raiz do projeto, execute:

~~~powershell
.\Atualizar-Banco.ps1
~~~

Ou, sem o script PowerShell:

~~~powershell
dotnet run --project backend --no-launch-profile -- --atualizar-banco
~~~

O comando compila, atualiza o banco e termina; não inicia o servidor web. Depois, execute o backend normalmente.

- Banco inexistente ou vazio: EF Core aplica as migrations e cria a estrutura atual.
- Banco antigo do projeto sem histórico EF: o atualizador verifica o schema conhecido, aplica os scripts incrementais de colaboradores/kits e registra a baseline antes de aplicar as migrations EF pendentes. Os scripts ficam embutidos no backend.
- Banco já versionado: aplica somente migrations pendentes. Pode executar novamente sem duplicar dados.
- Banco antigo incompatível: a atualização é interrompida; não apaga ou recria as tabelas existentes.

A conexão é com PostgreSQL. O atualizador não instala o servidor nem altera a senha do usuário PostgreSQL. Recomenda-se guardar um backup de bancos com dados importantes antes de atualizar.

O comando prepara a estrutura, sem inserir usuários ou produtos de demonstração. Para uma instalação acadêmica vazia, o seed database/seed.sql pode ser aplicado uma única vez pelo pgAdmin. Ele cria o administrador de demonstração e o catálogo; não o execute em bancos existentes para evitar duplicação e redefinição de senha.

Nas próximas evoluções, adicione migrations EF normalmente; o mesmo comando aplicará as versões novas. Não execute database/schema.sql sobre um banco com dados: esse arquivo apaga tabelas.
