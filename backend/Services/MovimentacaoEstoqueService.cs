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

        public Task<object> ResponsaveisAsync() => _repository.ResponsaveisAsync();
        public Task<object> ListarAsync(int pagina, int tamanho, int? produto, int? autor, string? tipo, DateOnly? de, DateOnly? ate) => _repository.ListarAsync(pagina, tamanho, produto, autor, tipo, de, ate);

        public async Task<MovimentacaoEstoque> RegistrarAsync(
            MovimentacaoEstoqueCreateDto dto,
            int colaboradorId)
        {
            if (dto.OperacaoId == Guid.Empty)
                throw new ArgumentException("Identificador de operação inválido.");
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

            if (dto.EstoqueEsperado.HasValue != dto.QuantidadeContada.HasValue)
                throw new ArgumentException("Contagem exige saldo de referência e quantidade contada.");
            if (dto.EstoqueEsperado.HasValue)
            {
                var diferenca = (long)dto.QuantidadeContada!.Value - dto.EstoqueEsperado.Value;
                if (dto.Motivo != "contagem" || diferenca == 0 || Math.Abs(diferenca) != dto.Quantidade || (diferenca > 0 ? "entrada" : "saida") != tipo)
                    throw new ArgumentException("Diferença de contagem inválida.");
            }
            else if (dto.Motivo == "contagem")
                throw new ArgumentException("Informe os dados da contagem.");
            var movimentacao = new MovimentacaoEstoque
            {
                OperacaoId = dto.OperacaoId,
                Motivo = dto.Motivo,
                Observacao = string.IsNullOrWhiteSpace(dto.Observacao) ? null : dto.Observacao.Trim(),
                EstoqueEsperado = dto.EstoqueEsperado,
                QuantidadeContada = dto.QuantidadeContada,
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
