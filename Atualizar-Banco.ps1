$ErrorActionPreference = 'Stop'

$projetoPim = Join-Path $PSScriptRoot 'backend/Pim.csproj'

$ambienteAnterior = $env:ASPNETCORE_ENVIRONMENT
$dotnetAnterior = $env:DOTNET_ENVIRONMENT

try {
    $env:ASPNETCORE_ENVIRONMENT = 'Development'
    $env:DOTNET_ENVIRONMENT = 'Development'

    Write-Host 'Atualizando o banco configurado no backend...'

    & dotnet run --project $projetoPim --no-launch-profile -- --atualizar-banco

    if ($LASTEXITCODE -ne 0) {
        throw 'A atualização falhou. Confira a conexão e os erros acima.'
    }
}
finally {
    $env:ASPNETCORE_ENVIRONMENT = $ambienteAnterior
    $env:DOTNET_ENVIRONMENT = $dotnetAnterior
}