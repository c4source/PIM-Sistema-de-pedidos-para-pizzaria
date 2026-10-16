 using Npgsql;
using Pim.Models;

namespace Pim.Repositories
{
    public class MovimentacaoEstoqueRepository
    {
        private readonly string _connectionString;

        public MovimentacaoEstoqueRepository(IConfiguration configuration)
        {
            _connectionString =
                configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException(
                    "Connection string 'DefaultConnection' nao encontrada."
                );
        }

        public async Task<MovimentacaoEstoque> RegistrarAsync(
            MovimentacaoEstoque movimentacao)
        {
            await using var connection =
                new NpgsqlConnection(_connectionString);

            await connection.OpenAsync();

            await using var transaction =
                await connection.BeginTransactionAsync();

            try
            {
                // Busca o estoque atual e bloqueia o produto
                // durante esta movimentação.
                const string sqlEstoque = @"
                    SELECT estoque
                    FROM produto
                    WHERE codprod = @produtoId
                    FOR UPDATE;
                ";

                await using var commandEstoque =
                    new NpgsqlCommand(
                        sqlEstoque,
                        connection,
                        transaction
                    );

                commandEstoque.Parameters.AddWithValue(
                    "@produtoId",
                    movimentacao.ProdutoId
                );

                var resultadoEstoque =
                    await commandEstoque.ExecuteScalarAsync();

                if (resultadoEstoque == null)
                {
                    throw new KeyNotFoundException(
                        "Produto não encontrado."
                    );
                }

                var estoqueAtual =
                    Convert.ToInt32(resultadoEstoque);

                var novoEstoque = movimentacao.Tipo switch
                {
                    "entrada" =>
                        estoqueAtual + movimentacao.Quantidade,

                    "saida" =>
                        estoqueAtual - movimentacao.Quantidade,

                    _ => throw new ArgumentException(
                        "Tipo de movimentação inválido."
                    )
                };

                if (novoEstoque < 0)
                {
                    throw new InvalidOperationException(
                        "Estoque insuficiente."
                    );
                }

                // Atualiza a quantidade atual do produto.
                const string sqlAtualizarEstoque = @"
                    UPDATE produto
                    SET estoque = @novoEstoque
                    WHERE codprod = @produtoId;
                ";

                await using var commandAtualizar =
                    new NpgsqlCommand(
                        sqlAtualizarEstoque,
                        connection,
                        transaction
                    );

                commandAtualizar.Parameters.AddWithValue(
                    "@novoEstoque",
                    novoEstoque
                );

                commandAtualizar.Parameters.AddWithValue(
                    "@produtoId",
                    movimentacao.ProdutoId
                );

                await commandAtualizar.ExecuteNonQueryAsync();

                // Registra o histórico da movimentação.
                const string sqlMovimentacao = @"
                    INSERT INTO movimentacao_estoque
                    (
                        codprod,
                        id_colaborador,
                        tipo,
                        quantidade
                    )
                    VALUES
                    (
                        @produtoId,
                        @colaboradorId,
                        @tipo,
                        @quantidade
                    )
                    RETURNING id_movimentacao, data_hora;
                ";

                await using var commandMovimentacao =
                    new NpgsqlCommand(
                        sqlMovimentacao,
                        connection,
                        transaction
                    );

                commandMovimentacao.Parameters.AddWithValue(
                    "@produtoId",
                    movimentacao.ProdutoId
                );

                commandMovimentacao.Parameters.AddWithValue(
                    "@colaboradorId",
                    movimentacao.ColaboradorId
                );

                commandMovimentacao.Parameters.AddWithValue(
                    "@tipo",
                    movimentacao.Tipo
                );

                commandMovimentacao.Parameters.AddWithValue(
                    "@quantidade",
                    movimentacao.Quantidade
                );

                await using var reader =
                    await commandMovimentacao.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    movimentacao.Id =
                        reader.GetInt32(
                            reader.GetOrdinal("id_movimentacao")
                        );

                    movimentacao.DataHora =
                        reader.GetDateTime(
                            reader.GetOrdinal("data_hora")
                        );
                }

                await reader.CloseAsync();

                await transaction.CommitAsync();

                return movimentacao;
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
    }
}