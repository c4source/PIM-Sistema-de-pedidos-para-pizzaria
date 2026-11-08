using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Pim.Models
{
    [Table("cliente")]
    public class Cliente
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("id_cliente")]
        public int Id
        {
            get; set;
        }

        [Column("nome_cliente")]
        [Required, StringLength(100)]
        public string Nome { get; set; } = string.Empty;

        [Column("cpf_cliente")]
        [StringLength(11)]
        public string? Cpf
        {
            get; set;
        }

        [Column("celular_cliente")]
        [StringLength(20)]
        public string? Celular
        {
            get; set;
        }

        [Column("email_cliente")]
        [EmailAddress, StringLength(100)]
        public string? Email
        {
            get; set;
        }

        [Column("senha_cliente")]
        [StringLength(100)]
        public string? Senha
        {
            get; set;
        }
    }
}
