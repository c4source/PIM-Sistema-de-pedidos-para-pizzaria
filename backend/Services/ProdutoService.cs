using Pim.DTOs;
using Pim.Models;
using Pim.Repositories;

namespace Pim.Services
{
    public class ProdutoService
    {
        private readonly ProdutoRepository _produtoRepository;

        public ProdutoService(ProdutoRepository produtoRepository)
        {
            _produtoRepository = produtoRepository;
        }

        public async Task<IEnumerable<ProdutoResponseDto>> ListarAsync(string? categoria, bool somenteDisponiveis)
        {
            var produtos = await _produtoRepository.ListarAsync(categoria, somenteDisponiveis);

            return produtos.Select(ToResponse);
        }

        public async Task<IEnumerable<string>> ListarCategoriasAsync()
        {
            return await _produtoRepository.ListarCategoriasAsync();
        }

        public async Task<ProdutoResponseDto?> BuscarPorIdAsync(int id)
        {
            var produto = await _produtoRepository.BuscarPorIdAsync(id);

            if (produto == null)
                return null;

            return ToResponse(produto);
        }

        public async Task<ProdutoResponseDto> CriarAsync(ProdutoCreateDto dto)
        {
            var produto = new Produto
            {
                Nome = dto.Nome,
                Preco = dto.Preco,
                Descricao = dto.Descricao,
                Categoria = dto.Categoria,
                Status = dto.Status,
                Estoque = dto.Estoque,
                EhKit = dto.EhKit,
                Componentes = dto.Componentes ?? new(),
                ImagemUrl = dto.ImagemUrl
            };

            await _produtoRepository.CriarAsync(produto);

            return ToResponse(produto);
        }

        public async Task<bool> AtualizarAsync(int id, ProdutoUpdateDto dto)
        {
            var produto = await _produtoRepository.BuscarPorIdAsync(id);

            if (produto == null)
                return false;

            produto.Nome = dto.Nome;
            produto.Preco = dto.Preco;
            produto.Descricao = dto.Descricao;
            produto.Categoria = dto.Categoria;
            produto.Status = dto.Status;
            produto.Estoque = dto.Estoque;
            produto.EhKit = dto.EhKit;
            produto.Componentes = dto.Componentes ?? new();
            produto.ImagemUrl = dto.ImagemUrl;

            await _produtoRepository.AtualizarAsync(produto);

            return true;
        }

        public async Task<bool> RemoverAsync(int id)
        {
            var produto = await _produtoRepository.BuscarPorIdAsync(id);

            if (produto == null)
                return false;

            await _produtoRepository.RemoverAsync(produto);

            return true;
        }

        private static ProdutoResponseDto ToResponse(Produto produto)
        {
            return new ProdutoResponseDto
            {
                Id = produto.Id,
                Nome = produto.Nome,
                Preco = produto.Preco,
                Descricao = produto.Descricao,
                Categoria = produto.Categoria,
                Status = produto.Status,
                Estoque = produto.Estoque,
                EhKit = produto.EhKit,
                Componentes = produto.Componentes,
                ImagemUrl = produto.ImagemUrl
            };
        }
    }
}
