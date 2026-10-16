using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pim.DTOs;
using Pim.Services;

namespace Pim.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PedidoController : ControllerBase
    {
        private readonly PedidoService _pedidoService;

        public PedidoController(PedidoService pedidoService)
        {
            _pedidoService = pedidoService;
        }

        [AllowAnonymous]
        [HttpPost("checkout-mvp")]
        public async Task<IActionResult> CheckoutMvp(CheckoutMvpDto dto)
        {
            try
            {
                var resultado = await _pedidoService.CheckoutMvpAsync(dto);

                if (!resultado.Sucesso)
                    return BadRequest(resultado.Mensagem);

                return Ok(new
                {
                    idPedido = resultado.IdPedido,
                    codigo = resultado.Codigo,
                    status = resultado.Status,
                    valorTotal = resultado.ValorTotal,
                    mensagem = resultado.Mensagem
                });
            }
            catch (Exception ex)
            {
                var mensagemErro = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, $"Erro Detalhado: {mensagemErro}");
            }
        }

        [Authorize(Roles = "Administrador,Colaborador")]
        [HttpGet]
        public async Task<ActionResult<IEnumerable<PedidoResponseDto>>> GetPedidos()
        {
            var pedidos = await _pedidoService.ListarAsync();
            return Ok(pedidos);
        }

        [Authorize(Roles = "Administrador,Colaborador")]
        [HttpGet("{id}")]
        public async Task<ActionResult<PedidoResponseDto>> GetPedido(int id)
        {
            var pedido = await _pedidoService.BuscarPorIdAsync(id);

            if (pedido == null)
                return NotFound("Pedido nao encontrado.");

            return Ok(pedido);
        }

        [Authorize(Roles = "Administrador,Colaborador")]
        [HttpPatch("{id}/aprovar")]
        public async Task<IActionResult> AprovarPedido(int id, AprovarPedidoDto dto)
        {
            var resultado = await _pedidoService.AprovarAsync(id);

            if (!resultado.Sucesso)
                return BadRequest(resultado.Mensagem);

            return Ok(new
            {
                message = resultado.Mensagem,
                status = "em_preparo"
            });
        }

        [Authorize(Roles = "Administrador,Colaborador")]
        [HttpPatch("{id}/status")]
        public async Task<IActionResult> AtualizarStatus(int id, AtualizarStatusPedidoDto dto)
        {
            var resultado = await _pedidoService.AtualizarStatusAsync(id, dto);

            if (!resultado.Sucesso)
                return BadRequest(resultado.Mensagem);

            return Ok(new
            {
                message = resultado.Mensagem
            });
        }

        [Authorize(Roles = "Administrador,Colaborador")]
        [HttpPatch("{id}/cancelar-loja")]
        public async Task<IActionResult> CancelarPelaLoja(int id, CancelarPedidoDto dto)
        {
            var resultado = await _pedidoService.CancelarPelaLojaAsync(id);

            if (!resultado.Sucesso)
                return BadRequest(resultado.Mensagem);

            return Ok(new
            {
                message = resultado.Mensagem
            });
        }
    }
}