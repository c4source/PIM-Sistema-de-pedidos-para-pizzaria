using System.ComponentModel.DataAnnotations;
namespace Pim.DTOs
{
    public class CheckoutMvpDto
    {
        [Required, StringLength(100)]
        public string NomeCliente { get; set; } = string.Empty;
        [Required, StringLength(20)]
        public string TelefoneCliente { get; set; } = string.Empty;
        [Required, RegularExpression("entrega|retirada")]
        public string TipoEntrega { get; set; } = string.Empty;
        [StringLength(150)]
        public string? Rua { get; set; }
        [StringLength(20)]
        public string? Numero { get; set; }
        [StringLength(100)]
        public string? Bairro { get; set; }
        [StringLength(150)]
        public string? Complemento { get; set; }
        public string? Observacoes { get; set; }
        [Required, RegularExpression("dinheiro|cartao|pix")]
        public string? FormaPagamento { get; set; }
        [Required, MinLength(1)]
        public List<ItemCheckoutMvpDto> Itens { get; set; } = new();
    }
}
