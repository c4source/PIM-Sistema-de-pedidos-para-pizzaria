using Pim.DTOs;
using Pim.Models;
using Pim.Repositories;

namespace Pim.Services
{
    public class PedidoService
    {
        private readonly PedidoRepository _pedidoRepository;

        public PedidoService(PedidoRepository pedidoRepository)
        {
            _pedidoRepository = pedidoRepository;
        }

        public async Task<PedidoResultadoDto> CheckoutMvpAsync(CheckoutMvpDto dto)
        {
            var tipoEntrega = NormalizarTipoEntrega(dto.TipoEntrega);

            if (string.IsNullOrWhiteSpace(dto.NomeCliente))
                return PedidoResultadoDto.Falha("Nome do cliente e obrigatorio.");

            if (string.IsNullOrWhiteSpace(dto.TelefoneCliente))
                return PedidoResultadoDto.Falha("Telefone do cliente e obrigatorio.");

            if (tipoEntrega == null)
                return PedidoResultadoDto.Falha("Tipo de entrega invalido. Use: entrega ou retirada.");

            if (tipoEntrega == TipoEntrega.Entrega &&
                (string.IsNullOrWhiteSpace(dto.Rua) ||
                 string.IsNullOrWhiteSpace(dto.Numero) ||
                 string.IsNullOrWhiteSpace(dto.Bairro)))
            {
                return PedidoResultadoDto.Falha("Rua, numero e bairro sao obrigatorios para entrega.");
            }

            if (dto.Itens == null || !dto.Itens.Any())
                return PedidoResultadoDto.Falha("O pedido precisa ter pelo menos um item.");

            if (!FormaPagamentoValida(dto.FormaPagamento))
                return PedidoResultadoDto.Falha("Forma de pagamento invalida. Use: dinheiro, cartao ou pix.");

            var pedido = new Pedido
            {
                Codigo = $"PED-{DateTime.Now:yyyyMMddHHmmssfff}-{Guid.NewGuid().ToString("N")[..8]}",
                NomeCliente = dto.NomeCliente.Trim(),
                TelefoneCliente = dto.TelefoneCliente.Trim(),
                TipoEntrega = tipoEntrega,
                RuaEntrega = tipoEntrega == TipoEntrega.Entrega ? dto.Rua?.Trim() : null,
                NumeroEntrega = tipoEntrega == TipoEntrega.Entrega ? dto.Numero?.Trim() : null,
                BairroEntrega = tipoEntrega == TipoEntrega.Entrega ? dto.Bairro?.Trim() : null,
                ComplementoEntrega = tipoEntrega == TipoEntrega.Entrega ? dto.Complemento?.Trim() : null,
                Observacoes = dto.Observacoes,
                DataHora = DateTime.Now,
                Status = PedidoStatus.Recebido
            };

            decimal totalProdutos = 0;

            foreach (var itemDto in dto.Itens)
            {
                if (itemDto.IdProduto <= 0)
                    return PedidoResultadoDto.Falha("Todos os itens precisam informar um produto.");

                if (itemDto.Quantidade <= 0)
                    return PedidoResultadoDto.Falha("Todos os itens precisam ter quantidade maior que zero.");

                var produto = await _pedidoRepository.BuscarProdutoPorIdAsync(itemDto.IdProduto);

                if (produto == null)
                    return PedidoResultadoDto.Falha($"Produto {itemDto.IdProduto} nao encontrado.");



                var itemPedido = new ItemPedido
                {
                    CodProd = itemDto.IdProduto,
                    Quantidade = itemDto.Quantidade,
                    PrecoUnitario = produto.Preco,
                    Subtotal = itemDto.Quantidade * produto.Preco
                };

                pedido.Itens.Add(itemPedido);
                totalProdutos += itemPedido.Subtotal;
            }

            pedido.ValorTotal = totalProdutos;

            pedido.Pagamento = new Pagamento
            {
                FormaPagamento = dto.FormaPagamento!.Trim().ToLower(),
                StatusPagamento = "pendente",
                ValorPago = pedido.ValorTotal,
                DataHoraPagamento = DateTime.Now
            };

            try { await _pedidoRepository.SalvarPedidoAsync(pedido); }
            catch (InvalidOperationException ex) { return PedidoResultadoDto.Falha(ex.Message); }
            catch (OverflowException) { return PedidoResultadoDto.Falha("Quantidade informada muito grande."); }

            return PedidoResultadoDto.Ok(pedido);
        }

        public async Task<IEnumerable<PedidoResponseDto>> ListarAsync()
        {
            var pedidos = await _pedidoRepository.ListarPedidosAsync();
            return pedidos.Select(ToResponse);
        }

        public async Task<PedidoResponseDto?> BuscarPorIdAsync(int id)
        {
            var pedido = await _pedidoRepository.BuscarPedidoCompletoAsync(id);

            if (pedido == null)
                return null;

            return ToResponse(pedido);
        }

        public async Task<(bool Sucesso, string Mensagem)> AprovarAsync(int id)
        {
            var pedido = await _pedidoRepository.BuscarPedidoCompletoAsync(id);

            if (pedido == null)
                return (false, "Pedido nao encontrado.");

            if (pedido.Status == PedidoStatus.Cancelado || pedido.Status == PedidoStatus.Finalizado)
                return (false, "Pedido finalizado ou cancelado nao pode mudar de status.");

            await _pedidoRepository.AtualizarStatusAsync(id, PedidoStatus.EmPreparo);

            return (true, $"Pedido {id} enviado para preparo.");
        }

        public async Task<(bool Sucesso, string Mensagem)> AtualizarStatusAsync(int id, AtualizarStatusPedidoDto dto)
        {
            var pedido = await _pedidoRepository.BuscarPedidoCompletoAsync(id);

            if (pedido == null)
                return (false, "Pedido nao encontrado.");

            var novoStatus = NormalizarStatus(dto.Status, PedidoStatus.StatusOperacionais);

            if (novoStatus == null)
                return (false, "Status invalido. Use: recebido, em_preparo, pronto, finalizado ou cancelado.");

            if (novoStatus == PedidoStatus.Cancelado) return await CancelarPelaLojaAsync(id);
            if (pedido.Status == PedidoStatus.Cancelado || pedido.Status == PedidoStatus.Finalizado) return (false,"Pedido cancelado ou finalizado não pode mudar de status.");
            await _pedidoRepository.AtualizarStatusAsync(id, novoStatus);

            return (true, $"Status do pedido {id} atualizado para {novoStatus}.");
        }

        public async Task<(bool Sucesso, string Mensagem)> CancelarPelaLojaAsync(int id)
        {
            var pedido = await _pedidoRepository.BuscarPedidoCompletoAsync(id);

            if (pedido == null)
                return (false, "Pedido nao encontrado.");

            if (pedido.Status == PedidoStatus.Finalizado)
                return (false, "Pedido finalizado nao pode ser cancelado.");

            if (pedido.Status == PedidoStatus.Cancelado)
                return (false, "Pedido ja esta cancelado.");

            try { await _pedidoRepository.CancelarPedidoAsync(pedido); }
            catch (InvalidOperationException ex) { return (false,ex.Message); }

            return (true, $"Pedido {id} cancelado.");
        }

        private static PedidoResponseDto ToResponse(Pedido pedido)
        {
            return new PedidoResponseDto
            {
                Id = pedido.Id,
                Codigo = pedido.Codigo,
                NomeCliente = pedido.NomeCliente,
                TelefoneCliente = pedido.TelefoneCliente,
                Observacoes = pedido.Observacoes,
                DataHora = pedido.DataHora,
                Status = pedido.Status,
                ValorTotal = pedido.ValorTotal,
                TipoEntrega = pedido.TipoEntrega,
                RuaEntrega = pedido.RuaEntrega,
                NumeroEntrega = pedido.NumeroEntrega,
                BairroEntrega = pedido.BairroEntrega,
                ComplementoEntrega = pedido.ComplementoEntrega,
                FormaPagamento = pedido.Pagamento?.FormaPagamento,
                StatusPagamento = pedido.Pagamento?.StatusPagamento,
                Itens = pedido.Itens.Select(item => new ItemPedidoResponseDto
                {
                    Id = item.Id,
                    CodProd = item.CodProd,
                    Produto = item.Produto?.Nome,
                    Quantidade = item.Quantidade,
                    PrecoUnitario = item.PrecoUnitario,
                    Subtotal = item.Subtotal
                }).ToList()
            };
        }

        private static string? NormalizarTipoEntrega(string? tipoEntrega)
        {
            if (string.Equals(tipoEntrega?.Trim(), TipoEntrega.Entrega, StringComparison.CurrentCultureIgnoreCase))
                return TipoEntrega.Entrega;

            if (string.Equals(tipoEntrega?.Trim(), TipoEntrega.Retirada, StringComparison.CurrentCultureIgnoreCase))
                return TipoEntrega.Retirada;

            return null;
        }

        private static bool FormaPagamentoValida(string? formaPagamento)
        {
            var forma = formaPagamento?.Trim().ToLower();
            return forma == "dinheiro" || forma == "cartao" || forma == "pix";
        }

        private static string? NormalizarStatus(string status, IEnumerable<string> statusValidos)
        {
            return statusValidos.FirstOrDefault(s =>
                string.Equals(s, status?.Trim(), StringComparison.CurrentCultureIgnoreCase));
        }
    }
}