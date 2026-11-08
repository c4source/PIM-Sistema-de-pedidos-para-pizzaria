using System.ComponentModel.DataAnnotations;
namespace Pim.DTOs
{
    public class ItemCheckoutMvpDto
    {
        [Range(1, int.MaxValue)]
        public int IdProduto
        {
            get; set;
        }
        [Range(1, int.MaxValue)]
        public int Quantidade
        {
            get; set;
        }
        public decimal? PrecoUnitario
        {
            get; set;
        }
    }
}
