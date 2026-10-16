using Pim.DTOs;
using Pim.Models;
using Pim.Repositories;
using System.Security.Cryptography;
namespace Pim.Services;
public class ColaboradorService(ColaboradorRepository repository)
{
    public static ColaboradorResponseDto Resposta(Colaborador u)=>new(){Id=u.Id,Nome=u.Nome,Email=u.Email,Perfil=u.Perfil,TrocarSenha=u.TrocarSenha};
    public async Task<IEnumerable<ColaboradorResponseDto>> ListarAsync()=>(await repository.ListarAsync()).Select(Resposta);
    public async Task<ColaboradorResponseDto?> BuscarPorIdAsync(int id){var u=await repository.BuscarPorIdAsync(id);return u==null?null:Resposta(u);}
    public async Task<object> CriarAsync(ColaboradorCreateDto dto){
        var senha=Convert.ToHexString(RandomNumberGenerator.GetBytes(12));
        var u=new Colaborador{Nome=dto.Nome.Trim(),Email=dto.Email.Trim().ToLowerInvariant(),Perfil=dto.Perfil,Senha=BCrypt.Net.BCrypt.HashPassword(senha),TrocarSenha=true};
        await repository.CriarAsync(u);return new {colaborador=Resposta(u),senhaProvisoria=senha};
    }
    public async Task<(object? Dados, string? Erro)> ResetarSenhaAsync(int id, int autor)
    {
        var senha = Convert.ToHexString(RandomNumberGenerator.GetBytes(12));
        var resultado = await repository.ResetarSenhaAsync(id, autor, BCrypt.Net.BCrypt.HashPassword(senha));
        if (resultado.Usuario == null) return (null, resultado.Erro);
        return (new { colaborador = Resposta(resultado.Usuario), senhaProvisoria = senha }, null);
    }

    public Task<string?> AtualizarAsync(int id,ColaboradorUpdateDto dto,int autor)=>repository.AlterarAsync(id,new Colaborador{Nome=dto.Nome.Trim(),Email=dto.Email.Trim().ToLowerInvariant(),Perfil=dto.Perfil},autor);
    public Task<string?> RemoverAsync(int id,int autor)=>repository.AlterarAsync(id,null,autor);
}
