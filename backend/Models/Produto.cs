using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Pim.Models
{
    [Table("produto")]
    public class Produto
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("codprod")]
        public int Id
        {
            get; set;
        }

        [Column("nome_produto")]
        [Required, StringLength(100)]
        public string Nome { get; set; } = string.Empty;

        [Column("preco", TypeName = "decimal(10,2)")]
        public decimal Preco
        {
            get; set;
        }

        [Column("descricao")]
        public string? Descricao
        {
            get; set;
        }

        [Column("categoria")]
        [Required, StringLength(30), RegularExpression("pizza|doce|bebida|combo")]
        public string? Categoria
        {
            get; set;
        }

        [Column("status_disponibilidade")]
        [Required, StringLength(20), RegularExpression("disponivel|indisponivel")]
        public string? Status
        {
            get; set;
        }

        [Column("estoque")]
        [Range(0, int.MaxValue)]
        public int? Estoque
        {
            get; set;
        }

        [Column("eh_kit")]
        public bool EhKit
        {
            get; set;
        }
        [NotMapped]
        public List<Pim.Models.KitComponente> Componentes { get; set; } = new();
        [Column("imagem_url"), StringLength(200)]
        public string? ImagemUrl
        {
            get; set;
        }
    }
}
