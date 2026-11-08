using System.ComponentModel.DataAnnotations;
namespace Pim.DTOs
{
    public class MovimentacaoEstoqueCreateDto
    {
        [Required, RegularExpression("reposicao|perda|consumo_interno|correcao|contagem|outro")]
        public string Motivo { get; set; } = "outro";
        [StringLength(500)]
        public string? Observacao
        {
            get; set;
        }
        [Range(0, int.MaxValue)]
        public int? EstoqueEsperado
        {
            get; set;
        }
        [Range(0, int.MaxValue)]
        public int? QuantidadeContada
        {
            get; set;
        }
        public Guid? OperacaoId
        {
            get; set;
        }

        [Range(1, int.MaxValue)]
        public int ProdutoId
        {
            get; set;
        }

        [Required, RegularExpression("entrada|saida")]
        public string Tipo { get; set; } = string.Empty;

        [Range(1, int.MaxValue)]
        public int Quantidade
        {
            get; set;
        }
    }
}
