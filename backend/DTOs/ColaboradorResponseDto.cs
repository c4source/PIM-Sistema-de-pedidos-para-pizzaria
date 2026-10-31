namespace Pim.DTOs
{
    public class ColaboradorResponseDto
    {
        public int Id
        {
            get; set;
        }
        public string Perfil { get; set; } = "";
        public bool TrocarSenha
        {
            get; set;
        }
        public string Nome { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
    }
}
