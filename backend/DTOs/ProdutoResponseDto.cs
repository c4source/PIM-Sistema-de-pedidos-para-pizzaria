namespace Pim.DTOs
{
    public class ProdutoResponseDto
    {
        public int Id
        {
            get; set;
        }
        public string Nome { get; set; } = string.Empty;
        public decimal Preco
        {
            get; set;
        }
        public string? Descricao
        {
            get; set;
        }
        public string? Categoria
        {
            get; set;
        }
        public string? Status
        {
            get; set;
        }
        public int? Estoque
        {
            get; set;
        }
        public bool EhKit
        {
            get; set;
        }
        public List<Pim.Models.KitComponente> Componentes { get; set; } = new();
        public string? ImagemUrl
        {
            get; set;
        }
    }
}
