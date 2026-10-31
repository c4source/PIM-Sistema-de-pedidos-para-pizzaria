using Microsoft.EntityFrameworkCore;
using Pim.Data;
using Pim.Models;
namespace Pim.Repositories;

public class PedidoRepository(PimDbContext db)
{
    public Task<Produto?> BuscarProdutoPorIdAsync(int id) => db.Produtos.AsNoTracking().FirstOrDefaultAsync(p => p.Id == id);
    private IQueryable<Pedido> ComDetalhes() => db.Pedidos.AsNoTracking().Include(p => p.Itens).ThenInclude(i => i.Produto).Include(p => p.Pagamento);
    public Task<List<Pedido>> ListarPedidosAsync() => ComDetalhes().OrderByDescending(p => p.DataHora).ThenByDescending(p => p.Id).ToListAsync();
    public Task<Pedido?> BuscarPedidoCompletoAsync(int id) => ComDetalhes().FirstOrDefaultAsync(p => p.Id == id);
    public async Task AtualizarStatusAsync(int id, string status)
    {
        var linhas = await db.Pedidos.Where(p => p.Id == id && p.Status != "cancelado" && p.Status != "finalizado").ExecuteUpdateAsync(s => s.SetProperty(p => p.Status, status));
        if (linhas == 0)
            throw new InvalidOperationException("Pedido cancelado, finalizado ou não encontrado.");
    }
    public async Task SalvarPedidoAsync(Pedido pedido)
    {
        await using var tx = await db.Database.BeginTransactionAsync();
        // O bloqueio protege saldo e composição durante toda a transação do EF.
        await db.Database.ExecuteSqlRawAsync("LOCK TABLE produto IN SHARE ROW EXCLUSIVE MODE");
        var produtos = await db.Produtos.ToDictionaryAsync(p => p.Id);
        var componentes = await db.ComponentesKit.AsNoTracking().ToListAsync();
        var baixas = new Dictionary<int, int>();
        foreach (var item in pedido.Itens)
        {
            if (!produtos.TryGetValue(item.CodProd, out var p) || p.Status != "disponivel")
                throw new InvalidOperationException("Produto indisponível.");
            item.PrecoUnitario = p.Preco;
            item.Subtotal = p.Preco * item.Quantidade;
            var partes = p.EhKit ? componentes.Where(c => c.IdKit == p.Id).ToList() : new List<KitComponente> { new() { IdProduto = p.Id, Quantidade = 1 } };
            if (partes.Count == 0)
                throw new InvalidOperationException("Kit sem componentes.");
            if (p.EhKit)
            {
                var possiveis = partes.Min(c => produtos.TryGetValue(c.IdProduto, out var componente) && componente.Status == "disponivel" ? (componente.Estoque ?? 0) / c.Quantidade : 0);
                var solicitados = pedido.Itens.Where(i => i.CodProd == p.Id).Sum(i => i.Quantidade);
                if (solicitados > possiveis)
                    throw new InvalidOperationException($"Não há estoque suficiente para o combo {p.Nome}. Quantidade disponível: {possiveis}. Quantidade solicitada: {solicitados}. Ajuste a quantidade no carrinho.");
            }
            foreach (var parte in partes)
            {
                if (!produtos.TryGetValue(parte.IdProduto, out var componente) || componente.EhKit || componente.Status != "disponivel")
                    throw new InvalidOperationException("Componente do kit indisponível.");
                baixas[parte.IdProduto] = checked(baixas.GetValueOrDefault(parte.IdProduto) + checked(parte.Quantidade * item.Quantidade));
            }
        }
        foreach (var baixa in baixas)
        {
            var p = produtos[baixa.Key];
            if (p.Estoque < baixa.Value)
                throw new InvalidOperationException($"Estoque insuficiente para {p.Nome}. Quantidade disponível: {p.Estoque ?? 0}. Quantidade necessária para este pedido: {baixa.Value}. Ajuste os produtos ou combos no carrinho.");
            p.Estoque -= baixa.Value;
        }
        pedido.ValorTotal = pedido.Itens.Sum(i => i.Subtotal);
        if (pedido.Pagamento != null)
            pedido.Pagamento.ValorPago = pedido.ValorTotal;
        db.Pedidos.Add(pedido);
        await db.SaveChangesAsync();
        foreach (var baixa in baixas)
            db.BaixasEstoque.Add(new()
            {
                IdPedido = pedido.Id,
                IdProduto = baixa.Key,
                Quantidade = baixa.Value
            });
        await db.SaveChangesAsync();
        await tx.CommitAsync();
        db.ChangeTracker.Clear();
    }
    public async Task CancelarPedidoAsync(Pedido pedido)
    {
        await using var tx = await db.Database.BeginTransactionAsync();
        await db.Database.ExecuteSqlRawAsync("LOCK TABLE produto IN SHARE ROW EXCLUSIVE MODE");
        // Uma atualização condicional impede devolução duplicada ou reabertura concorrente.
        if (await db.Pedidos.Where(p => p.Id == pedido.Id && p.Status != "cancelado" && p.Status != "finalizado").ExecuteUpdateAsync(s => s.SetProperty(p => p.Status, "cancelado")) != 1)
            throw new InvalidOperationException("Pedido já cancelado ou finalizado.");
        var baixas = await db.BaixasEstoque.AsNoTracking().Where(b => b.IdPedido == pedido.Id).ToListAsync();
        if (baixas.Count == 0)
            baixas = pedido.Itens.GroupBy(i => i.CodProd).Select(g => new PedidoBaixaEstoque { IdPedido = pedido.Id, IdProduto = g.Key, Quantidade = g.Sum(i => i.Quantidade) }).ToList();
        foreach (var baixa in baixas)
            await db.Produtos.Where(p => p.Id == baixa.IdProduto).ExecuteUpdateAsync(s => s.SetProperty(p => p.Estoque, p => p.Estoque + baixa.Quantidade));
        await db.Pagamentos.Where(p => p.IdPedido == pedido.Id).ExecuteUpdateAsync(s => s.SetProperty(p => p.StatusPagamento, "cancelado"));
        await tx.CommitAsync();
    }
}
