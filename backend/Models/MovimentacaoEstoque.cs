

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
        public int Id
        {
            get; set;
        }

        [Column("motivo"), Required, StringLength(30)]
        public string Motivo { get; set; } = "outro";
        [Column("observacao"), StringLength(500)]
        public string? Observacao
        {
            get; set;
        }
        [Column("estoque_esperado"), Range(0, int.MaxValue)]
        public int? EstoqueEsperado
        {
            get; set;
        }
        [Column("quantidade_contada"), Range(0, int.MaxValue)]
        public int? QuantidadeContada
        {
            get; set;
        }

        [Column("operacao_id")]
        public Guid? OperacaoId
        {
            get; set;
        }

        [Column("codprod")]
        public int ProdutoId
        {
            get; set;
        }

        [Column("id_colaborador")]
        public int ColaboradorId
        {
            get; set;
        }

        [Column("tipo")]
        public string Tipo { get; set; } = string.Empty;

        [Column("quantidade")]
        public int Quantidade
        {
            get; set;
        }

        [Column("data_hora")]
        public DateTime DataHora
        {
            get; set;
        }
    }
}
