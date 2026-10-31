using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using Pim.Data;
namespace Pim.Controllers;

public class LimiteEstoqueDto
{
    [Range(0, int.MaxValue)]
    public int EstoqueMinimo
    {
        get; set;
    }
}
[ApiController, Route("api/Produto"), Authorize(Roles = "Administrador,Colaborador")]
public class ProdutoEstoqueController(PimDbContext db) : ControllerBase
{
    [HttpPatch("{id:int}/estoque-minimo")]
    public async Task<IActionResult> Limite(int id, LimiteEstoqueDto dto)
    {
        var alterados = await db.Produtos.Where(p => p.Id == id && !p.EhKit)
            .ExecuteUpdateAsync(s => s.SetProperty(p => p.EstoqueMinimo, dto.EstoqueMinimo));
        return alterados == 1 ? NoContent() : BadRequest("Produto não encontrado ou é um kit. Configure os componentes individualmente.");
    }
}
