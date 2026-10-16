using Pim.DTOs;
using Pim.Models;
using Pim.Repositories;

namespace Pim.Services
{
    public class MovimentacaoEstoqueService
    {
        private readonly MovimentacaoEstoqueRepository _repository;

        public MovimentacaoEstoqueService(
            MovimentacaoEstoqueRepository repository)
        {
            _repository = repository;
        }

        public async Task<MovimentacaoEstoque> RegistrarAsync(
            MovimentacaoEstoqueCreateDto dto,
            int colaboradorId)
        {
            if (dto.ProdutoId <= 0)
            {
                throw new ArgumentException(
                    "Produto inválido."
                );
            }

            if (dto.Quantidade <= 0)
            {
                throw new ArgumentException(
                    "A quantidade deve ser maior que zero."
                );
            }

            var tipo = dto.Tipo
                .Trim()
                .ToLower();

            if (tipo != "entrada" && tipo != "saida")
            {
                throw new ArgumentException(
                    "Tipo de movimentação inválido."
                );
            }

            var movimentacao = new MovimentacaoEstoque
            {
                ProdutoId = dto.ProdutoId,
                ColaboradorId = colaboradorId,
                Tipo = tipo,
                Quantidade = dto.Quantidade
            };

            return await _repository.RegistrarAsync(
                movimentacao
            );
        }
    }
}