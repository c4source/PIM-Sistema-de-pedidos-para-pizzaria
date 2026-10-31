using Microsoft.EntityFrameworkCore;
using Pim.Data;
using Pim.Models;

namespace Pim.Repositories;

public class MovimentacaoEstoqueRepository(PimDbContext db)
{
    public async Task<MovimentacaoEstoque> RegistrarAsync(MovimentacaoEstoque movimento)
    {
        await using var transaction = await db.Database.BeginTransactionAsync();
        // Mesmo bloqueio dos pedidos: saldo e histórico são confirmados juntos.
        await db.Database.ExecuteSqlRawAsync("LOCK TABLE produto IN SHARE ROW EXCLUSIVE MODE");
        if (movimento.OperacaoId.HasValue)
        {
            var existente = await db.MovimentacoesEstoque.AsNoTracking()
                .SingleOrDefaultAsync(m => m.OperacaoId == movimento.OperacaoId);
            if (existente != null)
            {
                if (existente.ColaboradorId != movimento.ColaboradorId ||
                    existente.ProdutoId != movimento.ProdutoId || existente.Tipo != movimento.Tipo ||
                    existente.Quantidade != movimento.Quantidade || existente.Motivo != movimento.Motivo ||
                    existente.Observacao != movimento.Observacao || existente.EstoqueEsperado != movimento.EstoqueEsperado || existente.QuantidadeContada != movimento.QuantidadeContada)
                    throw new ArgumentException("Identificador de operação já utilizado com outros dados.");
                await transaction.CommitAsync();
                return existente;
            }
        }
        var produto = await db.Produtos.SingleOrDefaultAsync(p => p.Id == movimento.ProdutoId)
            ?? throw new KeyNotFoundException("Produto não encontrado.");
        if (produto.EhKit)
            throw new InvalidOperationException("Movimente os componentes do kit individualmente.");
        if (movimento.EstoqueEsperado.HasValue && produto.Estoque != movimento.EstoqueEsperado)
            throw new ConflitoContagemException($"O estoque de {produto.Nome} mudou de {movimento.EstoqueEsperado} para {produto.Estoque} unidades. Atualize o saldo e faça uma nova contagem; este lançamento não foi aplicado.");
        long saldo = (long)(produto.Estoque ?? 0) +
            (movimento.Tipo == "entrada" ? movimento.Quantidade : -(long)movimento.Quantidade);
        if (saldo < 0)
            throw new InvalidOperationException($"Estoque insuficiente para {produto.Nome}. Quantidade solicitada: {movimento.Quantidade}. Saldo atual: {produto.Estoque ?? 0} unidades. Confira o saldo ou descarte este lançamento e registre a quantidade correta.");
        if (saldo > int.MaxValue)
            throw new InvalidOperationException("A quantidade excede o limite de estoque.");
        produto.Estoque = (int)saldo;
        db.MovimentacoesEstoque.Add(movimento);
        await db.SaveChangesAsync();
        await transaction.CommitAsync();
        return movimento;
    }

    public async Task<object> ResponsaveisAsync() => await db.Colaboradores.AsNoTracking()
        .Where(c => db.MovimentacoesEstoque.Any(m => m.ColaboradorId == c.Id)).OrderBy(c => c.Nome)
        .Select(c => new { c.Id, c.Nome }).ToListAsync();

    public async Task<object> ListarAsync(int pagina, int tamanho, int? produto, int? autor, string? tipo, DateOnly? de, DateOnly? ate)
    {
        var query = from m in db.MovimentacoesEstoque.AsNoTracking()
                    join p in db.Produtos on m.ProdutoId equals p.Id
                    join c in db.Colaboradores on m.ColaboradorId equals c.Id
                    orderby m.Id descending
                    select new
                    {
                        m.Id,
                        m.OperacaoId,
                        m.ProdutoId,
                        Produto = p.Nome,
                        m.ColaboradorId,
                        Colaborador = c.Nome,
                        m.Tipo,
                        m.Quantidade,
                        m.Motivo,
                        m.Observacao,
                        m.EstoqueEsperado,
                        m.QuantidadeContada,
                        m.DataHora
                    };
        if (produto.HasValue)
            query = query.Where(m => m.ProdutoId == produto);
        if (autor.HasValue)
            query = query.Where(m => m.ColaboradorId == autor);
        if (tipo != null)
            query = query.Where(m => m.Tipo == tipo);
        if (de.HasValue)
        {
            var inicio = de.Value.ToDateTime(TimeOnly.MinValue);
            query = query.Where(m => m.DataHora >= inicio);
        }
        if (ate.HasValue)
        {
            var fim = ate.Value.ToDateTime(TimeOnly.MaxValue);
            query = query.Where(m => m.DataHora <= fim);
        }
        return new
        {
            pagina,
            tamanho,
            total = await query.CountAsync(),
            itens = await query.Skip((pagina - 1) * tamanho).Take(tamanho).ToListAsync()
        };
    }
}
