using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Npgsql;
using Pim.DTOs;
using Pim.Services;
using System.Security.Claims;
namespace Pim.Controllers;
[Route("api/[controller]"), ApiController, Authorize(Roles="Administrador")]
public class ColaboradoresController(ColaboradorService service):ControllerBase {
    private int Autor => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    [HttpGet] public async Task<IActionResult> Listar()=>Ok(await service.ListarAsync());
    [HttpGet("{id:int}")] public async Task<IActionResult> Buscar(int id){var u=await service.BuscarPorIdAsync(id);return u==null?NotFound("Colaborador não encontrado."):Ok(u);}
    [HttpPost] public async Task<IActionResult> Criar(ColaboradorCreateDto dto){
        if(dto.Nome.Trim().Length<2)return BadRequest("Informe o nome.");
        try{return StatusCode(201,await service.CriarAsync(dto));}catch(DbUpdateException ex) when(ex.InnerException is PostgresException { SqlState: "23505" }){return Conflict("E-mail já cadastrado.");}
    }
    [HttpPut("{id:int}")] public async Task<IActionResult> Atualizar(int id,ColaboradorUpdateDto dto){
        if(dto.Nome.Trim().Length<2)return BadRequest("Informe o nome.");
        try{var erro=await service.AtualizarAsync(id,dto,Autor);return erro==null?NoContent():BadRequest(erro);}catch(PostgresException ex) when(ex.SqlState=="23505"){return Conflict("E-mail já cadastrado.");}
    }
    [HttpPost("{id:int}/resetar-senha")]
    [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
    public async Task<IActionResult> ResetarSenha(int id)
    {
        var resultado = await service.ResetarSenhaAsync(id, Autor);
        if (resultado.Erro == "Colaborador não encontrado.") return NotFound(resultado.Erro);
        return resultado.Erro == null ? Ok(resultado.Dados) : BadRequest(resultado.Erro);
    }

    [HttpDelete("{id:int}")] public async Task<IActionResult> Remover(int id){var erro=await service.RemoverAsync(id,Autor);return erro==null?NoContent():BadRequest(erro);}
}
