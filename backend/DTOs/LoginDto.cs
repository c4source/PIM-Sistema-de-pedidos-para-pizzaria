using System.ComponentModel.DataAnnotations;
﻿namespace Pim.DTOs
{
    public class LoginDto
    {
        [Required, EmailAddress, StringLength(100)]
        public string Email { get; set; } = string.Empty;
        [Required]
        public string Senha { get; set; } = string.Empty;
    }
}