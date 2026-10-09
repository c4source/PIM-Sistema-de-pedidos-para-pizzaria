

using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Pim.Models
{
    [Table("movimentacao_estoque")]
    public class MovimentacaoEstoque
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("id_movimentacao")]
        public int Id { get; set; }

        [Column("codprod")]
        public int ProdutoId { get; set; }

        [Column("id_colaborador")]
        public int ColaboradorId { get; set; }

        [Column("tipo")]
        public string Tipo { get; set; } = string.Empty;

        [Column("quantidade")]
        public int Quantidade { get; set; }

        [Column("data_hora")]
        public DateTime DataHora { get; set; }
    }
}