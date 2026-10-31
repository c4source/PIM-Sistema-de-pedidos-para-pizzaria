using Pim.Models;

namespace Pim.DTOs
{
    public class PedidoResultadoDto
    {
        public bool Sucesso
        {
            get; set;
        }
        public string? Mensagem
        {
            get; set;
        }
        public int? IdPedido
        {
            get; set;
        }
        public string? Codigo
        {
            get; set;
        }
        public string? Status
        {
            get; set;
        }
        public decimal? ValorTotal
        {
            get; set;
        }

        public static PedidoResultadoDto Falha(string mensagem)
        {
            return new PedidoResultadoDto
            {
                Sucesso = false,
                Mensagem = mensagem
            };
        }

        public static PedidoResultadoDto Ok(Pedido pedido)
        {
            return new PedidoResultadoDto
            {
                Sucesso = true,
                IdPedido = pedido.Id,
                Codigo = pedido.Codigo,
                Status = pedido.Status,
                ValorTotal = pedido.ValorTotal,
                Mensagem = "Pedido recebido."
            };
        }
    }
}
