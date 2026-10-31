using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pim.DTOs;
using Pim.Services;
using System.Security.Claims;

namespace Pim.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Administrador,Colaborador")]
    public class MovimentacaoEstoqueController : ControllerBase
    {
        private readonly MovimentacaoEstoqueService _service;

        public MovimentacaoEstoqueController(
            MovimentacaoEstoqueService service)
        {
            _service = service;
        }

        [HttpGet("responsaveis")]
        public async Task<IActionResult> Responsaveis() => Ok(await _service.ResponsaveisAsync());

        [HttpGet]
        public async Task<IActionResult> Listar([FromQuery] int pagina = 1, [FromQuery] int tamanho = 30, [FromQuery] int? produto = null, [FromQuery] int? autor = null, [FromQuery] string? tipo = null, [FromQuery] DateOnly? de = null, [FromQuery] DateOnly? ate = null)
        {
            if (pagina < 1 || pagina > 1000000 || tamanho < 1 || tamanho > 100)
                return BadRequest("Paginação inválida.");
            if (produto <= 0 || autor <= 0 || tipo != null && tipo != "entrada" && tipo != "saida" || de > ate)
                return BadRequest("Filtros inválidos.");
            return Ok(await _service.ListarAsync(pagina, tamanho, produto, autor, tipo, de, ate));
        }

        [HttpPost]
        public async Task<ActionResult> Registrar(
            MovimentacaoEstoqueCreateDto dto)
        {
            var colaboradorIdClaim =
                User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (!int.TryParse(
                colaboradorIdClaim,
                out var colaboradorId))
            {
                return Unauthorized(
                    "Identificação do colaborador não encontrada no token."
                );
            }

            try
            {
                var movimentacao =
                    await _service.RegistrarAsync(
                        dto,
                        colaboradorId
                    );

                return StatusCode(
                    StatusCodes.Status201Created,
                    movimentacao
                );
            }
            catch (Pim.Repositories.ConflitoContagemException e) { return Conflict(e.Message); }
            catch (KeyNotFoundException e)
            {
                return NotFound(e.Message);
            }
            catch (ArgumentException e)
            {
                return BadRequest(e.Message);
            }
            catch (InvalidOperationException e)
            {
                return BadRequest(e.Message);
            }
        }
    }
}
