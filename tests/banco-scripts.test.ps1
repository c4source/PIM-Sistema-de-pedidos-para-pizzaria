param([string]$Configuration = 'Debug', [string]$PsqlPath = 'psql')
$ErrorActionPreference = 'Stop'
$repoTeste = Split-Path $PSScriptRoot -Parent
$assemblyTeste = Join-Path $repoTeste "backend/bin/$Configuration/net10.0/Npgsql.dll"
if (!(Test-Path $assemblyTeste)) { throw "Compile o backend na configuração $Configuration antes de testar." }
Add-Type -Path $assemblyTeste
$conexaoTeste = $env:PIM_TEST_CONNECTION
if (!$conexaoTeste) {
    $arquivoLocal = Join-Path $repoTeste 'backend/appsettings.Local.json'
    if (!(Test-Path $arquivoLocal)) { throw 'Configure PIM_TEST_CONNECTION ou backend/appsettings.Local.json.' }
    $configTeste = Get-Content $arquivoLocal -Raw | ConvertFrom-Json
    $conexaoTeste = $configTeste.ConnectionStrings.DefaultConnection
}
$builderTeste = [Npgsql.NpgsqlConnectionStringBuilder]::new($conexaoTeste)
$pgAnterior = $env:PGPASSWORD
$connAnterior = $env:ConnectionStrings__DefaultConnection
$logAnterior = $env:Logging__LogLevel__Default
$env:PGPASSWORD = $builderTeste.Password
$env:Logging__LogLevel__Default = 'Critical'
$prefixoTeste = 'pim_scripts_' + [Guid]::NewGuid().ToString('N').Substring(0, 12)
$bancosTeste = @()
function Sql-Teste([string]$banco, [string]$sql) {
    $saida = & $PsqlPath -X -h $builderTeste.Host -p $builderTeste.Port -U $builderTeste.Username -d $banco -v ON_ERROR_STOP=1 -At -c $sql 2>&1
    if ($LASTEXITCODE -ne 0) { throw ($saida -join "`n") }
    return ($saida -join "`n")
}
function Executar-Arquivo([string]$banco, [string]$arquivo, [bool]$deveFalhar = $false) {
    $saida = & $PsqlPath -X -h $builderTeste.Host -p $builderTeste.Port -U $builderTeste.Username -d $banco -v ON_ERROR_STOP=1 -f (Join-Path $repoTeste $arquivo) 2>&1
    $codigo = $LASTEXITCODE
    if ($deveFalhar -and $codigo -eq 0) { throw "$arquivo deveria ter recusado esse banco." }
    if (!$deveFalhar -and $codigo -ne 0) { throw ($saida -join "`n") }
}
function Conferir([bool]$condicao, [string]$mensagem) {
    if (!$condicao) { throw "FALHOU: $mensagem" }
    Write-Output "OK: $mensagem"
}
function Atualizar-Ef([string]$banco) {
    $configTemporaria = [Npgsql.NpgsqlConnectionStringBuilder]::new($builderTeste.ConnectionString)
    $configTemporaria.Database = $banco
    $env:ConnectionStrings__DefaultConnection = $configTemporaria.ConnectionString
    $saida = & dotnet run --project (Join-Path $repoTeste 'backend/Pim.csproj') -c $Configuration --no-build --no-launch-profile -- --atualizar-banco 2>&1
    if ($LASTEXITCODE -ne 0) { throw ($saida -join "`n") }
}
function Impressao-Dados([string]$banco) {
    return Sql-Teste $banco 'SELECT md5(ROW((SELECT jsonb_agg(to_jsonb(p) ORDER BY codprod) FROM produto p),(SELECT jsonb_agg(to_jsonb(c) ORDER BY id_colaborador) FROM colaborador c),(SELECT jsonb_agg(to_jsonb(p) ORDER BY id_pedido) FROM pedido p),(SELECT jsonb_agg(to_jsonb(i) ORDER BY id_item_pedido) FROM itempedido i),(SELECT jsonb_agg(to_jsonb(p) ORDER BY id_pagamento) FROM pagamento p),(SELECT jsonb_agg(to_jsonb(k) ORDER BY id_kit,id_produto) FROM kit_componente k),(SELECT jsonb_agg(to_jsonb(b) ORDER BY id_pedido,id_produto) FROM pedido_baixa_estoque b),(SELECT jsonb_agg(to_jsonb(s) ORDER BY versao) FROM pim_seed_historico s))::text)'
}
try {
    foreach ($sufixo in @('sql', 'ef')) {
        $novoBanco = $prefixoTeste + '_' + $sufixo
        if ($novoBanco -notmatch '^pim_scripts_[a-f0-9]{12}_(sql|ef)$') { throw 'Nome de teste inválido.' }
        $null = Sql-Teste 'postgres' ('CREATE DATABASE "' + $novoBanco + '"')
        $bancosTeste += $novoBanco
    }
    $bancoSql = $prefixoTeste + '_sql'
    $bancoEf = $prefixoTeste + '_ef'
    Executar-Arquivo $bancoSql 'database/schema.sql'
    $versao = Sql-Teste $bancoSql 'SELECT count(*) FROM "__EFMigrationsHistory"'
    $esperado = @(Get-ChildItem (Join-Path $repoTeste 'backend/Migrations') -Filter '*.cs' | Where-Object { $_.Name -match '^\d{14}_[^.]+\.cs$' }).Count
    Conferir ([int]$versao -eq $esperado) 'Schema registra todas as migrations atuais'
    $estrutura = Sql-Teste $bancoSql "SELECT to_regclass('public.sessao_acesso') IS NOT NULL AND EXISTS(SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='movimentacao_estoque' AND indexdef LIKE 'CREATE UNIQUE INDEX%operacao_id%')"
    Conferir ($estrutura -eq 't') 'Sessões e índice único de operações existem'
    $null = Sql-Teste $bancoSql 'ALTER TABLE produto ALTER COLUMN codprod RESTART WITH 101; ALTER TABLE pedido ALTER COLUMN id_pedido RESTART WITH 51; ALTER TABLE colaborador ALTER COLUMN id_colaborador RESTART WITH 21;'
    Executar-Arquivo $bancoSql 'database/seed.sql'
    $dados = Sql-Teste $bancoSql 'SELECT (SELECT count(*) FROM produto),(SELECT count(*) FROM produto WHERE eh_kit),(SELECT count(*) FROM kit_componente),(SELECT count(*) FROM pedido),(SELECT count(*) FROM itempedido),(SELECT count(*) FROM pedido_baixa_estoque)'
    Conferir ($dados -eq '25|3|7|2|3|3') 'Seed cria produtos, kits, pedidos e baixas sem IDs fixos'
    $admin = Sql-Teste $bancoSql "SELECT trocar_senha AND senha_usuario=crypt('123456',senha_usuario) FROM colaborador WHERE perfil='Administrador'"
    Conferir ($admin -eq 't') 'Administrador demonstrativo exige troca da senha inicial'
    $coerente = Sql-Teste $bancoSql "SELECT NOT EXISTS(SELECT 1 FROM pedido p JOIN itempedido i USING(id_pedido) GROUP BY p.id_pedido,p.valor_total HAVING sum(i.subtotal)<>p.valor_total) AND (SELECT estoque FROM produto WHERE nome_produto='Pizza Calabresa')=19 AND (SELECT estoque FROM produto_com_estoque WHERE nome_produto='Combo Familia')=15"
    Conferir ($coerente -eq 't') 'Totais dos pedidos, estoque descontado e capacidade dos kits são coerentes'
    $null = Sql-Teste $bancoSql "UPDATE produto SET preco=18.70,estoque=8 WHERE nome_produto='Coca-Cola 600ml'; UPDATE colaborador SET nome_usuario='Administrador editado',senha_usuario=crypt(gen_random_uuid()::text,gen_salt('bf')),trocar_senha=FALSE,versao_sessao=9;"
    $antes = Impressao-Dados $bancoSql
    Executar-Arquivo $bancoSql 'database/seed.sql'
    Executar-Arquivo $bancoSql 'database/schema.sql'
    Atualizar-Ef $bancoSql
    Conferir ((Impressao-Dados $bancoSql) -eq $antes) 'Repetir seed/schema e atualizar pelo EF preserva dados e credenciais editados'
    Atualizar-Ef $bancoEf
    Executar-Arquivo $bancoEf 'database/seed.sql'
    Executar-Arquivo $bancoEf 'database/schema.sql'
    Conferir ((Sql-Teste $bancoEf 'SELECT count(*) FROM produto') -eq '25') 'Instalação pelo EF também aceita o seed e o schema SQL'
    $antes = Impressao-Dados $bancoEf
    $null = Sql-Teste $bancoEf 'DROP TABLE "__EFMigrationsHistory"; DROP TABLE sessao_acesso; ALTER TABLE movimentacao_estoque DROP COLUMN operacao_id, DROP COLUMN motivo, DROP COLUMN observacao, DROP COLUMN estoque_esperado, DROP COLUMN quantidade_contada; ALTER TABLE produto DROP CONSTRAINT ck_produto_minimo; ALTER TABLE produto DROP COLUMN estoque_minimo; ALTER TABLE colaborador DROP COLUMN ativo;'
    $antesLegado = Impressao-Dados $bancoEf
    Executar-Arquivo $bancoEf 'database/schema.sql' $true
    Conferir ((Impressao-Dados $bancoEf) -eq $antesLegado) 'Schema recusa banco legado sem apagar dados'
    Atualizar-Ef $bancoEf
    Conferir ((Impressao-Dados $bancoEf) -eq $antes) 'Atualizador reconhece banco legado compatível e preserva os dados'
    $null = Sql-Teste $bancoEf 'DROP TABLE pim_seed_historico;'
    $contagens = Sql-Teste $bancoEf 'SELECT (SELECT count(*) FROM produto),(SELECT count(*) FROM pedido),(SELECT sum(estoque) FROM produto)'
    Executar-Arquivo $bancoEf 'database/seed.sql' $true
    Conferir ((Sql-Teste $bancoEf 'SELECT (SELECT count(*) FROM produto),(SELECT count(*) FROM pedido),(SELECT sum(estoque) FROM produto)') -eq $contagens) 'Seed recusa banco já populado sem duplicar ou alterar saldos'
    Conferir ((Sql-Teste $bancoEf "SELECT to_regclass('public.pim_seed_historico') IS NULL") -eq 't') 'Erro no seed desfaz a transação inteira'
} finally {
    try {
        foreach ($bancoCriado in $bancosTeste) {
            if ($bancoCriado -notmatch '^pim_scripts_[a-f0-9]{12}_(sql|ef)$') { throw 'Recusa de limpeza: nome fora do padrão de teste.' }
            $null = Sql-Teste 'postgres' ('DROP DATABASE "' + $bancoCriado + '" WITH (FORCE)')
            Write-Output "Banco temporário removido: $bancoCriado"
        }
    } finally {
        $env:PGPASSWORD = $pgAnterior
        $env:ConnectionStrings__DefaultConnection = $connAnterior
        $env:Logging__LogLevel__Default = $logAnterior
    }
}
