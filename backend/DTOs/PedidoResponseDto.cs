namespace Pim.DTOs
{
    public class PedidoResponseDto
    {
        public int Id
        {
            get; set;
        }
        public string? Codigo
        {
            get; set;
        }
        public string NomeCliente { get; set; } = string.Empty;
        public string TelefoneCliente { get; set; } = string.Empty;
        public string? Observacoes
        {
            get; set;
        }
        public DateTime DataHora
        {
            get; set;
        }
        public string Status { get; set; } = string.Empty;
        public decimal ValorTotal
        {
            get; set;
        }
        public string TipoEntrega { get; set; } = string.Empty;
        public string? RuaEntrega
        {
            get; set;
        }
        public string? NumeroEntrega
        {
            get; set;
        }
        public string? BairroEntrega
        {
            get; set;
        }
        public string? ComplementoEntrega
        {
            get; set;
        }
        public string? FormaPagamento
        {
            get; set;
        }
        public string? StatusPagamento
        {
            get; set;
        }
        public List<ItemPedidoResponseDto> Itens { get; set; } = new();
    }
}
