using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
namespace Pim.Models;
[Table("kit_componente")]
public class KitComponente {
    [Column("id_kit")] public int IdKit { get; set; }
    [Column("id_produto"), Range(1,int.MaxValue)] public int IdProduto { get; set; }
    [Column("quantidade"), Range(1,int.MaxValue)] public int Quantidade { get; set; }
}
