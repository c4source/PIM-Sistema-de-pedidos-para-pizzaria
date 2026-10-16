using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.IdentityModel.Tokens;
using Pim.DTOs;
using Pim.Models;
using Pim.Repositories;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
namespace Pim.Controllers;
[Route("api/[controller]"),ApiController]
public class AuthController(IConfiguration config,ColaboradorRepository repository):ControllerBase
{
    [HttpPost("login-colaborador")]
    public async Task<IActionResult> LoginColaborador(LoginDto dto){
        if(string.IsNullOrWhiteSpace(dto.Email)||string.IsNullOrEmpty(dto.Senha))return BadRequest("Informe e-mail e senha.");
        var u=await repository.BuscarPorEmailAsync(dto.Email);bool valido=false;
        if(u!=null){try{valido=BCrypt.Net.BCrypt.Verify(dto.Senha,u.Senha);}catch(BCrypt.Net.SaltParseException){}}
        if(!valido)return Unauthorized("E-mail ou senha incorretos.");
        return Ok(Sessao(u!));
    }
    [HttpGet("sessao"),Authorize(Roles="Administrador,Colaborador")]
    public async Task<IActionResult> SessaoAtual(){var u=await repository.BuscarPorIdAsync(int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!));return Ok(new {id=u!.Id,usuario=u.Nome,perfil=u.Perfil});}
    [HttpPost("trocar-senha"),Authorize(Roles="TrocaSenha")]
    public async Task<IActionResult> TrocarSenha(TrocarSenhaDto dto){
        if(Encoding.UTF8.GetByteCount(dto.NovaSenha)>72 || string.IsNullOrWhiteSpace(dto.NovaSenha))return BadRequest("A senha deve ter de 8 a 72 caracteres e no máximo 72 bytes.");
        var id=int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);var u=await repository.BuscarPorIdAsync(id);
        if(u==null)return Unauthorized();
        if(BCrypt.Net.BCrypt.Verify(dto.NovaSenha,u.Senha))return BadRequest("Escolha uma senha diferente da provisória.");
        if(!await repository.TrocarSenhaAsync(id,int.Parse(User.FindFirstValue("versao")!),BCrypt.Net.BCrypt.HashPassword(dto.NovaSenha)))return Unauthorized("Esta solicitação já foi utilizada. Entre novamente.");
        u.TrocarSenha=false;u.VersaoSessao++;return Ok(Sessao(u));
    }
    private object Sessao(Colaborador u){
        var papel=u.TrocarSenha?"TrocaSenha":u.Perfil;
        var claims=new[]{new Claim(ClaimTypes.NameIdentifier,u.Id.ToString()),new Claim(ClaimTypes.Name,u.Nome),new Claim(ClaimTypes.Email,u.Email),new Claim(ClaimTypes.Role,papel),new Claim("versao",u.VersaoSessao.ToString())};
        var key=new SymmetricSecurityKey(Encoding.UTF8.GetBytes(config["Jwt:Key"]!));
        var jwt=new JwtSecurityToken(config["Jwt:Issuer"],config["Jwt:Audience"],claims,expires:DateTime.UtcNow.AddMinutes(u.TrocarSenha?15:480),signingCredentials:new SigningCredentials(key,SecurityAlgorithms.HmacSha256));
        return new {token=new JwtSecurityTokenHandler().WriteToken(jwt),id=u.Id,usuario=u.Nome,perfil=u.Perfil,trocaSenhaObrigatoria=u.TrocarSenha};
    }
}
