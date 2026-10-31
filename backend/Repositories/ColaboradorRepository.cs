using Microsoft.EntityFrameworkCore;
using Pim.Data;
using Pim.Models;
namespace Pim.Repositories;

public class ColaboradorRepository(PimDbContext db)
{
    public Task<List<Colaborador>> ListarAsync() => db.Colaboradores.AsNoTracking().OrderBy(c => c.Nome).ToListAsync();
    public Task<Colaborador?> BuscarPorIdAsync(int id) => db.Colaboradores.AsNoTracking().FirstOrDefaultAsync(c => c.Id == id);
    public Task<Colaborador?> BuscarPorEmailAsync(string email)
    {
        var normalizado = email.Trim().ToLowerInvariant();
        return db.Colaboradores.AsNoTracking().FirstOrDefaultAsync(c => c.Email.Trim().ToLower() == normalizado);
    }
    public async Task CriarAsync(Colaborador u)
    {
        u.TrocarSenha = true;
        db.Colaboradores.Add(u);
        await db.SaveChangesAsync();
        db.ChangeTracker.Clear();
    }
    private Task<bool> AutorValido(int id) => db.Colaboradores.AnyAsync(c => c.Id == id && c.Perfil == "Administrador" && !c.TrocarSenha);
    public async Task<string?> AlterarAsync(int id, Colaborador? novo, int autorId)
    {
        await using var tx = await db.Database.BeginTransactionAsync();
        await db.Database.ExecuteSqlRawAsync("LOCK TABLE colaborador IN SHARE ROW EXCLUSIVE MODE");
        if (!await AutorValido(autorId))
            return "Acesso de administrador necessário.";
        var u = await db.Colaboradores.SingleOrDefaultAsync(c => c.Id == id);
        if (u == null)
            return "Colaborador não encontrado.";
        if (novo == null && id == autorId)
            return "Você não pode excluir a própria conta.";
        if (u.Perfil == "Administrador" && (novo == null || novo.Perfil != "Administrador") && !await db.Colaboradores.AnyAsync(c => c.Id != id && c.Perfil == "Administrador" && !c.TrocarSenha))
            return "Não é possível remover o último administrador com acesso ativo.";
        if (novo == null)
            db.Colaboradores.Remove(u);
        else
        {
            u.Nome = novo.Nome;
            u.Email = novo.Email;
            u.Perfil = novo.Perfil;
            u.VersaoSessao++;
        }
        await db.SaveChangesAsync();
        await tx.CommitAsync();
        db.ChangeTracker.Clear();
        return null;
    }
    public async Task<(Colaborador? Usuario, string? Erro)> ResetarSenhaAsync(int id, int autorId, string hash)
    {
        await using var tx = await db.Database.BeginTransactionAsync();
        await db.Database.ExecuteSqlRawAsync("LOCK TABLE colaborador IN SHARE ROW EXCLUSIVE MODE");
        if (!await AutorValido(autorId))
            return (null, "Acesso de administrador necessário.");
        if (id == autorId)
            return (null, "Peça a outro administrador para resetar sua senha.");
        var u = await db.Colaboradores.SingleOrDefaultAsync(c => c.Id == id);
        if (u == null)
            return (null, "Colaborador não encontrado.");
        u.Senha = hash;
        u.TrocarSenha = true;
        u.VersaoSessao++;
        await db.SaveChangesAsync();
        await tx.CommitAsync();
        db.ChangeTracker.Clear();
        return (u, null);
    }
    public async Task<bool> TrocarSenhaAsync(int id, int versao, string hash) => await db.Colaboradores.Where(c => c.Id == id && c.VersaoSessao == versao && c.TrocarSenha).ExecuteUpdateAsync(s => s.SetProperty(c => c.Senha, hash).SetProperty(c => c.TrocarSenha, false).SetProperty(c => c.VersaoSessao, c => c.VersaoSessao + 1)) == 1;
}
