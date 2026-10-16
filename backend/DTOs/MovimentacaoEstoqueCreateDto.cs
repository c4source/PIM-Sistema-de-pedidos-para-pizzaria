namespace Pim.DTOs
{
    public class MovimentacaoEstoqueCreateDto
    {
        public int ProdutoId { get; set; }

        public string Tipo { get; set; } = string.Empty;

        public int Quantidade { get; set; }
    }
}