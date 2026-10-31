using Microsoft.EntityFrameworkCore;
using Pim.Data;
using Pim.Models;
namespace Pim.Repositories;

public class ProdutoRepository(PimDbContext db)
{
    public async Task<List<Produto>> ListarAsync(string? categoria, bool somenteDisponiveis)
    {
        var produtos = await db.Produtos.AsNoTracking().OrderBy(p => p.Categoria).ThenBy(p => p.Nome).ToListAsync();
        var componentes = await db.ComponentesKit.AsNoTracking().ToListAsync();
        var porId = produtos.ToDictionary(p => p.Id);
        foreach (var kit in produtos.Where(p => p.EhKit))
        {
            kit.Componentes = componentes.Where(c => c.IdKit == kit.Id).ToList();
            kit.Estoque = kit.Componentes.Count == 0 ? 0 : kit.Componentes.Min(c => porId.TryGetValue(c.IdProduto, out var p) && !p.EhKit && p.Status == "disponivel" ? (p.Estoque ?? 0) / c.Quantidade : 0);
        }
        return produtos.Where(p => (string.IsNullOrWhiteSpace(categoria) || string.Equals(p.Categoria, categoria, StringComparison.OrdinalIgnoreCase)) && (!somenteDisponiveis || (p.Status == "disponivel" && p.Estoque > 0))).ToList();
    }
    public async Task<Produto?> BuscarPorIdAsync(int id) => (await ListarAsync(null, false)).FirstOrDefault(p => p.Id == id);
    public async Task<List<string>> ListarCategoriasAsync() => await db.Produtos.AsNoTracking().Where(p => p.Categoria != null && p.Categoria != "").Select(p => p.Categoria!).Distinct().OrderBy(c => c).ToListAsync();
    public Task CriarAsync(Produto p) => SalvarAsync(p, true);
    public Task AtualizarAsync(Produto p) => SalvarAsync(p, false);
    private async Task SalvarAsync(Produto p, bool novo)
    {
        if (p.EhKit && (p.Componentes.Count == 0 || p.Componentes.Any(c => c.IdProduto <= 0 || c.Quantidade <= 0) || p.Componentes.Select(c => c.IdProduto).Distinct().Count() != p.Componentes.Count))
            throw new InvalidOperationException("Informe componentes diferentes e quantidades inteiras positivas para o kit.");
        if (!p.EhKit && p.Componentes.Count > 0)
            throw new InvalidOperationException("Produtos comuns não podem ter componentes.");
        await using var tx = await db.Database.BeginTransactionAsync();
        await db.Database.ExecuteSqlRawAsync("LOCK TABLE produto IN SHARE ROW EXCLUSIVE MODE");
        if (p.EhKit)
        {
            if (await db.ComponentesKit.AnyAsync(c => c.IdProduto == p.Id))
                throw new InvalidOperationException("Este produto é componente de outro kit e não pode virar kit.");
            var ids = p.Componentes.Select(c => c.IdProduto).ToList();
            if ((!novo && ids.Contains(p.Id)) || await db.Produtos.CountAsync(x => ids.Contains(x.Id) && !x.EhKit) != ids.Count)
                throw new InvalidOperationException("Componentes devem ser produtos individuais existentes, não o próprio kit ou outros kits.");
        }
        p.Estoque = p.EhKit ? 0 : p.Estoque ?? 0;
        if (novo)
            db.Produtos.Add(p);
        else
            db.Produtos.Update(p);
        await db.SaveChangesAsync();
        await db.ComponentesKit.Where(c => c.IdKit == p.Id).ExecuteDeleteAsync();
        foreach (var comp in p.Componentes)
            db.ComponentesKit.Add(new KitComponente { IdKit = p.Id, IdProduto = comp.IdProduto, Quantidade = comp.Quantidade });
        await db.SaveChangesAsync();
        await tx.CommitAsync();
        db.ChangeTracker.Clear();
        p.Estoque = (await BuscarPorIdAsync(p.Id))!.Estoque;
    }
    public async Task RemoverAsync(Produto p) => await db.Produtos.Where(x => x.Id == p.Id).ExecuteDeleteAsync();
}
