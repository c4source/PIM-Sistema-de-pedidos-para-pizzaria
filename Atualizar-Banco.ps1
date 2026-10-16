$ErrorActionPreference = 'Stop'
$projetoPim = Join-Path $PSScriptRoot 'backend/Pim.csproj'
Write-Host 'Atualizando o banco configurado no backend...'
& dotnet run --project $projetoPim --no-launch-profile -- --atualizar-banco
if ($LASTEXITCODE -ne 0) { throw 'A atualização falhou. Confira a conexão, permissões do PostgreSQL e a mensagem acima.' }
