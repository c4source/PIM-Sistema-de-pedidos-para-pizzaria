using System.ComponentModel.DataAnnotations;
namespace Pim.DTOs;

public class TrocarSenhaDto
{
    [Required, StringLength(72, MinimumLength = 8)] public string NovaSenha { get; set; } = "";
    [Required, Compare(nameof(NovaSenha))] public string ConfirmacaoSenha { get; set; } = "";
}
