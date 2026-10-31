namespace Pim.DTOs
{
    public class ItemPedidoResponseDto
    {
        public int Id
        {
            get; set;
        }
        public int CodProd
        {
            get; set;
        }
        public string? Produto
        {
            get; set;
        }
        public int Quantidade
        {
            get; set;
        }
        public decimal PrecoUnitario
        {
            get; set;
        }
        public decimal Subtotal
        {
            get; set;
        }
    }
}
