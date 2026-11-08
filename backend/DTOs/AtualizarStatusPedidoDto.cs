using System.ComponentModel.DataAnnotations;
namespace Pim.DTOs
{
    public class AtualizarStatusPedidoDto
    {
        [Required, RegularExpression("recebido|em_preparo|pronto|finalizado|cancelado")]
        public string Status { get; set; } = string.Empty;
    }
}
