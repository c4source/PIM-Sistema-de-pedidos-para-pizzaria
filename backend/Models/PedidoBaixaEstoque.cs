using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
namespace Pim.Models;
[Table("pedido_baixa_estoque")]
public class PedidoBaixaEstoque {
    [Column("id_pedido")] public int IdPedido { get; set; }
    [Column("id_produto")] public int IdProduto { get; set; }
    [Column("quantidade"), Range(1,int.MaxValue)] public int Quantidade { get; set; }
}
