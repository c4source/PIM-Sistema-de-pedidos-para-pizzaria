using System.ComponentModel.DataAnnotations;
namespace Pim.DTOs;
public class ColaboradorCreateDto
{
    [Required, StringLength(100, MinimumLength=2)] public string Nome { get; set; } = "";
    [Required, EmailAddress, StringLength(100)] public string Email { get; set; } = "";
    [Required, RegularExpression("Administrador|Colaborador")] public string Perfil { get; set; } = "Colaborador";
}
