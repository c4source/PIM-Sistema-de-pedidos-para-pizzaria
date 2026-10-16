using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage;
namespace Pim.Data;

public static class AtualizadorBanco
{
    public static async Task ExecutarAsync(PimDbContext db)
    {
        var criador = db.GetService<IRelationalDatabaseCreator>();
        if (await criador.ExistsAsync())
        {
            var temProduto = await db.Database.SqlQueryRaw<bool>("SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='produto') AS \"Value\"").SingleAsync();
            var temHistorico = await db.Database.SqlQueryRaw<bool>("SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='__EFMigrationsHistory') AS \"Value\"").SingleAsync();
            if (temHistorico)
                temHistorico = await db.Database.SqlQueryRaw<int>("SELECT count(*)::int AS \"Value\" FROM \"__EFMigrationsHistory\" WHERE \"MigrationId\" = '20261016222636_InicialEntityFramework'").SingleAsync() > 0;
            if (temProduto && !temHistorico)
            {
                // Só importa cópias do schema conhecido, nunca tenta reconstruir tabelas incompatíveis.
                var compativel = await db.Database.SqlQueryRaw<bool>("SELECT NOT EXISTS (SELECT 1 FROM (VALUES ('cliente','id_cliente'),('colaborador','senha_usuario'),('produto','codprod'),('produto','estoque'),('pedido','nome_cliente'),('pedido','telefone_cliente'),('pedido','rua_entrega'),('itempedido','preco_unitario'),('pagamento','status_pagamento')) AS esperado(tabela,coluna) WHERE NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name=esperado.tabela AND column_name=esperado.coluna)) AS \"Value\"").SingleAsync();
                if (!compativel) throw new InvalidOperationException("Banco antigo incompatível com o schema deste projeto. Nenhuma tabela foi recriada. Confira a documentação de atualização.");
                await using var tx = await db.Database.BeginTransactionAsync();
                foreach (var nome in new[] { "002", "003", "004" })
                {
                    await using var stream = typeof(AtualizadorBanco).Assembly.GetManifestResourceStream($"Pim.Sql.{nome}.sql")!;
                    using var reader = new StreamReader(stream);
                    var sql = await reader.ReadToEndAsync();
                    sql = System.Text.RegularExpressions.Regex.Replace(sql, @"(?im)^\s*(BEGIN|COMMIT);\s*$", "");
                    await db.Database.ExecuteSqlRawAsync(sql);
                }
                await tx.CommitAsync();
                Console.WriteLine("Banco anterior reconhecido e registrado no histórico do Entity Framework.");
            }
        }
        await db.Database.MigrateAsync();
        Console.WriteLine("Banco atualizado com sucesso. Dados existentes preservados.");
    }
}
