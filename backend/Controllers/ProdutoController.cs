using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pim.DTOs;
using Pim.Services;
using Npgsql;

namespace Pim.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProdutoController : ControllerBase
    {
        private readonly ProdutoService _produtoService;

        public ProdutoController(ProdutoService produtoService)
        {
            _produtoService = produtoService;
        }

        [AllowAnonymous]
        [HttpGet]
        public async Task<ActionResult<IEnumerable<ProdutoResponseDto>>> GetProduto(
            [FromQuery] string? categoria,
            [FromQuery] bool somenteDisponiveis = false)
        {
            var produtos = await _produtoService.ListarAsync(categoria, somenteDisponiveis);
            return Ok(produtos);
        }

        [AllowAnonymous]
        [HttpGet("categorias")]
        public async Task<ActionResult<IEnumerable<string>>> GetCategorias()
        {
            var categorias = await _produtoService.ListarCategoriasAsync();
            return Ok(categorias);
        }

        [AllowAnonymous]
        [HttpGet("{id}")]
        public async Task<ActionResult<ProdutoResponseDto>> GetProduto(int id)
        {
            var produto = await _produtoService.BuscarPorIdAsync(id);

            if (produto == null)
                return NotFound("Produto nao encontrado.");

            return Ok(produto);
        }

        [Authorize(Roles = "Administrador,Colaborador")]
        [HttpPost]
        public async Task<ActionResult<ProdutoResponseDto>> PostProduto(ProdutoCreateDto dto)
        {
            try {
            var produtoCriado = await _produtoService.CriarAsync(dto);

            return CreatedAtAction(nameof(GetProduto), new { id = produtoCriado.Id }, produtoCriado);
            } catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
        }

        [Authorize(Roles = "Administrador,Colaborador")]
        [HttpPut("{id}")]
        public async Task<IActionResult> PutProduto(int id, ProdutoUpdateDto dto)
        {
            try {
            var atualizado = await _produtoService.AtualizarAsync(id, dto);

            if (!atualizado)
                return NotFound("Produto nao encontrado.");

            return NoContent();
            } catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
        }

        [Authorize(Roles = "Administrador,Colaborador")]
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProduto(int id)
        {
            try {
            var removido = await _produtoService.RemoverAsync(id);

            if (!removido)
                return NotFound("Produto nao encontrado.");

            return NoContent();
            } catch (PostgresException ex) when (ex.SqlState is "23503" or "23001") { return Conflict("Produto vinculado a um kit ou pedido. Desative-o em vez de excluir."); }
        }
    }
}