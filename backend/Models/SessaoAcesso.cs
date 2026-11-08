using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
namespace Pim.Models;

[Table("sessao_acesso")]
public class SessaoAcesso
{
    [Key, Column("id")]
    public Guid Id
    {
        get; set;
    }
    [Column("id_colaborador")]
    public int ColaboradorId
    {
        get; set;
    }
    [Column("ultima_atividade")]
    public DateTime UltimaAtividade
    {
        get; set;
    }
}
