using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Pim.Models
{
    [Table("colaborador")]
    public class Colaborador
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("id_colaborador")]
        public int Id { get; set; }
        [Column("perfil"), Required, StringLength(20)]
        public string Perfil { get; set; } = "Colaborador";
        [Column("trocar_senha")]
        public bool TrocarSenha { get; set; }
        [Column("versao_sessao")]
        public int VersaoSessao { get; set; } = 1;

        [Column("nome_usuario")]
        [Required, StringLength(100)]
        public string Nome { get; set; } = string.Empty;

        [Column("email_usuario")]
        [Required, EmailAddress, StringLength(100)]
        public string Email { get; set; } = string.Empty;

        [Column("senha_usuario")]
        [Required, StringLength(100)]
        public string Senha { get; set; } = string.Empty;
    }
}
