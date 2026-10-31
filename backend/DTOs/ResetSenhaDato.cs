namespace Pim.DTOs
{
    public class ResetSenhaDto
    {
        public string Email { get; set; } = string.Empty;
        public string Cpf { get; set; } = string.Empty; // Usaremos o CPF como prova de identidade
        public string NovaSenha { get; set; } = string.Empty;
    }
}
