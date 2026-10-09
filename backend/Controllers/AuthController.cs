using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using Npgsql;
using NpgsqlTypes;
using Pim.DTOs;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Pim.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly string _connectionString;
        private readonly IConfiguration _config;

        public AuthController(IConfiguration config)
        {
            _config = config;
            _connectionString = config.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Connection string 'DefaultConnection' nao encontrada.");
        }

        /// <summary>
        /// Login para funcionários e administradores.
        /// </summary>
        [HttpPost("login-colaborador")]
        public async Task<ActionResult> LoginColaborador([FromBody] LoginDto login)
        {
            var colaborador = await BuscarColaboradorPorEmailAsync(login.Email);

            if (colaborador == null || !BCrypt.Net.BCrypt.Verify(login.Senha, colaborador.Senha))
            {
                return Unauthorized("E-mail ou senha de colaborador incorretos.");
            }

            var token = GerarToken(colaborador.Id,colaborador.Nome, colaborador.Email, "Colaborador");

            return Ok(new
            {
                token,
                usuario = colaborador.Nome,
                perfil = "Colaborador"
            });
        }

        private async Task<ColaboradorLogin?> BuscarColaboradorPorEmailAsync(string email)
        {
            const string sql = @"
                SELECT id_colaborador, nome_usuario, email_usuario, senha_usuario
                FROM colaborador
                WHERE email_usuario = @email;
            ";

            await using var connection = new NpgsqlConnection(_connectionString);
            await connection.OpenAsync();

            await using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.Add("@email", NpgsqlDbType.Varchar).Value = email;

            await using var reader = await command.ExecuteReaderAsync();

            if (!await reader.ReadAsync())
                return null;

            return new ColaboradorLogin
            {
                Id = reader.GetInt32(reader.GetOrdinal("id_colaborador")),
                Nome = reader.GetString(reader.GetOrdinal("nome_usuario")),
                Email = reader.GetString(reader.GetOrdinal("email_usuario")),
                Senha = reader.GetString(reader.GetOrdinal("senha_usuario"))
            };
        }

        // Método privado para gerar token do colaborador.
        private string GerarToken(int id,string nome, string email, string papel)
        {
            var jwtKey = _config["Jwt:Key"];

            if (string.IsNullOrWhiteSpace(jwtKey))
            {
                throw new InvalidOperationException("A chave JWT não foi configurada em appsettings.json.");
            }

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {   
                new Claim(ClaimTypes.NameIdentifier, id.ToString()),
                new Claim(ClaimTypes.Name, nome),
                new Claim(ClaimTypes.Email, email),
                new Claim(ClaimTypes.Role, papel),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: claims,
                expires: DateTime.Now.AddHours(8),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private class ColaboradorLogin
        {
            public int Id { get; set; }
            public string Nome { get; set; } = string.Empty;
            public string Email { get; set; } = string.Empty;
            public string Senha { get; set; } = string.Empty;
        }
    }
}