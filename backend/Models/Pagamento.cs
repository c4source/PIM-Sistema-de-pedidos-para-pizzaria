using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Pim.Models
{
    [Table("pagamento")]
    public class Pagamento
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("id_pagamento")]
        public int Id { get; set; }

        [Column("id_pedido")]
        public int IdPedido { get; set; }

        [Column("forma_pagamento")]
        [Required, StringLength(20)]
        public string FormaPagamento { get; set; } = string.Empty;

        [Column("status_pagamento")]
        [Required, StringLength(20)]
        public string StatusPagamento { get; set; } = "pendente";

        [Column("valor_pago")]
        public decimal ValorPago { get; set; }

        [Column("data_hora_pagamento")]
        public DateTime DataHoraPagamento { get; set; } = DateTime.Now;

        [ForeignKey("IdPedido")]
        public virtual Pedido? Pedido { get; set; }
    }
}
