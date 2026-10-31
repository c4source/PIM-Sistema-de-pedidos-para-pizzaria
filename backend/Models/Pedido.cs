using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Pim.Models
{
    [Table("pedido")]
    public class Pedido
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("id_pedido")]
        public int Id
        {
            get; set;
        }

        [Column("codigo")]
        [StringLength(50)]
        public string? Codigo
        {
            get; set;
        }

        [Column("nome_cliente")]
        [Required, StringLength(100)]
        public string NomeCliente { get; set; } = string.Empty;

        [Column("telefone_cliente")]
        [Required, StringLength(20)]
        public string TelefoneCliente { get; set; } = string.Empty;

        [Column("tipo_entrega")]
        [Required, StringLength(20)]
        public string TipoEntrega { get; set; } = Models.TipoEntrega.Retirada;

        [Column("rua_entrega")]
        [StringLength(150)]
        public string? RuaEntrega
        {
            get; set;
        }

        [Column("numero_entrega")]
        [StringLength(20)]
        public string? NumeroEntrega
        {
            get; set;
        }

        [Column("bairro_entrega")]
        [StringLength(100)]
        public string? BairroEntrega
        {
            get; set;
        }

        [Column("complemento_entrega")]
        [StringLength(150)]
        public string? ComplementoEntrega
        {
            get; set;
        }

        [Column("observacoes")]
        public string? Observacoes
        {
            get; set;
        }

        [Column("data_hora_pedido")]
        public DateTime DataHora { get; set; } = DateTime.Now;

        [Column("status_pedido")]
        [Required, StringLength(20)]
        public string Status { get; set; } = PedidoStatus.Recebido;

        [Column("valor_total")]
        public decimal ValorTotal
        {
            get; set;
        }

        public List<ItemPedido> Itens { get; set; } = new();
        public Pagamento? Pagamento
        {
            get; set;
        }
    }
}
