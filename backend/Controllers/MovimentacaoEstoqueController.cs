using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pim.DTOs;
using Pim.Services;
using System.Security.Claims;

namespace Pim.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Colaborador")]
    public class MovimentacaoEstoqueController : ControllerBase
    {
        private readonly MovimentacaoEstoqueService _service;

        public MovimentacaoEstoqueController(
            MovimentacaoEstoqueService service)
        {
            _service = service;
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