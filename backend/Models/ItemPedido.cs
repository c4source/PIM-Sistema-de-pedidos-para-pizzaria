using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Pim.Models
{
    [Table("itempedido")]
    public class ItemPedido
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("id_item_pedido")]
        public int Id
        {
            get; set;
        }

        [Column("id_pedido")]
        public int IdPedido
        {
            get; set;
        }

        [Column("codprod")]
        public int CodProd
        {
            get; set;
        }

        [Column("quantidade")]
        public int Quantidade
        {
            get; set;
        }

        [Column("preco_unitario")]
        public decimal PrecoUnitario
        {
            get; set;
        }

        [Column("subtotal")]
        public decimal Subtotal
        {
            get; set;
        }

        [ForeignKey("IdPedido")]
        public virtual Pedido? Pedido
        {
            get; set;
        }

        [ForeignKey("CodProd")]
        public virtual Produto? Produto
        {
            get; set;
        }
    }
}
