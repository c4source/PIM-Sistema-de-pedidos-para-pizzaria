using System.ComponentModel.DataAnnotations;
namespace Pim.DTOs
{
    public class ProdutoCreateDto
    {
        [Required(ErrorMessage = "O nome é obrigatório.")]
        [StringLength(100, MinimumLength = 3, ErrorMessage = "O nome deve ter de 3 a 100 caracteres.")]
        public string Nome { get; set; } = string.Empty;

        [Range(typeof(decimal), "0.01", "99999999.99",
        ParseLimitsInInvariantCulture = true, ConvertValueInInvariantCulture = true,
        ErrorMessage = "O preço deve ser maior que zero.")]
        public decimal Preco
        {
            get; set;
        }
        public string? Descricao
        {
            get; set;
        }
        [Required(ErrorMessage = "A categoria é obrigatória.")]
        [RegularExpression(
        "^(pizza|doce|bebida|combo)$",
         ErrorMessage = "Categoria inválida."
        )]
        public string? Categoria
        {
            get; set;
        }

        [Required(ErrorMessage = "O status é obrigatório.")]
        [RegularExpression(
        "^(disponivel|indisponivel)$",
        ErrorMessage = "Status inválido."
        )]
        public string? Status
        {
            get; set;
        }
        [Range(0, int.MaxValue,
        ErrorMessage = "O estoque não pode ser negativo.")]
        public int? Estoque
        {
            get; set;
        }
        public bool EhKit
        {
            get; set;
        }
        [Required]
        public List<Pim.Models.KitComponente> Componentes { get; set; } = new();
        [StringLength(200)]
        public string? ImagemUrl
        {
            get; set;
        }
    }
}
