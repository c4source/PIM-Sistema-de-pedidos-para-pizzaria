using System.ComponentModel.DataAnnotations;
namespace Pim.DTOs
{
    public class ProdutoUpdateDto
    {
        [Required, StringLength(100, MinimumLength=3)]
        public string Nome { get; set; } = string.Empty;
        [Range(typeof(decimal),"0.01","99999999.99", ParseLimitsInInvariantCulture=true, ConvertValueInInvariantCulture=true)]
        public decimal Preco { get; set; }
        public string? Descricao { get; set; }
        [Required, RegularExpression("pizza|doce|bebida|combo")]
        public string? Categoria { get; set; }
        [Required, RegularExpression("disponivel|indisponivel")]
        public string? Status { get; set; }
        [Range(0,int.MaxValue)]
        public int? Estoque { get; set; }
        public bool EhKit { get; set; }
        [Required]
        public List<Pim.Models.KitComponente> Componentes { get; set; } = new();
        [StringLength(200)]
        public string? ImagemUrl { get; set; }
    }
}
