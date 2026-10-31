using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;
using System.Security.Claims;
using System.Text.Json.Serialization;
using Pim.Repositories;
using Pim.Data;
using Microsoft.EntityFrameworkCore;
using Pim.Services;


namespace Pim
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);
            // Segredos por máquina; variáveis de ambiente mantêm precedência.
            builder.Configuration.AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: false)
                ;
            if (builder.Environment.IsDevelopment())
                builder.Configuration.AddUserSecrets<Program>(optional: true);
            builder.Configuration.AddEnvironmentVariables().AddCommandLine(args);
            var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
            var jwtKey = builder.Configuration["Jwt:Key"];
            if (string.IsNullOrWhiteSpace(connectionString))
                throw new InvalidOperationException("Configure ConnectionStrings:DefaultConnection por User Secrets, appsettings.Local.json ou variável de ambiente.");
            if (string.IsNullOrWhiteSpace(jwtKey) || Encoding.UTF8.GetByteCount(jwtKey) < 32 || jwtKey.StartsWith("GERE_"))
                throw new InvalidOperationException("Configure uma chave JWT aleatória com pelo menos 32 bytes no appsettings.Local.json ou por variável de ambiente.");

            // 1. CONFIGURAÇÃO DOS CONTROLLERS
            builder.Services.AddControllers()
                .AddJsonOptions(options =>
                {
                    options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
                    options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
                });

            builder.Services.AddEndpointsApiExplorer();

            // 2. CONFIGURAÇÃO DO SWAGGER
            builder.Services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo
                {
                    Title = "API do Sistema de Pedidos - PIM",
                    Version = "v1"
                });

                // Configuração do esquema de segurança JWT
                var securityScheme = new OpenApiSecurityScheme
                {
                    Name = "Authorization",
                    Type = SecuritySchemeType.Http,
                    Scheme = "bearer",
                    BearerFormat = "JWT",
                    In = ParameterLocation.Header,
                    Description = "Informe o token JWT para acessar rotas protegidas."
                };

                c.AddSecurityDefinition("Bearer", securityScheme);

                c.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference
                            {
                                Type = ReferenceType.SecurityScheme,
                                Id = "Bearer"
                            }
                        },
                        Array.Empty<string>()
                    }
                });
            });

            builder.Services.AddDbContext<PimDbContext>(options =>
                options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

            // 3. BANCO DE DADOS
            builder.Services.AddScoped<ProdutoRepository>();
            builder.Services.AddScoped<ProdutoService>();

            builder.Services.AddScoped<PedidoRepository>();
            builder.Services.AddScoped<PedidoService>();

            builder.Services.AddScoped<ColaboradorRepository>();
            builder.Services.AddScoped<ColaboradorService>();

            builder.Services.AddScoped<MovimentacaoEstoqueRepository>();
            builder.Services.AddScoped<MovimentacaoEstoqueService>();

            // 4. AUTENTICAÇÃO JWT
            builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddJwtBearer(options =>
                {
                    options.Events = new JwtBearerEvents
                    {
                        OnTokenValidated = async context =>
                        {
                            var principal = context.Principal!;
                            if (!int.TryParse(principal.FindFirstValue(ClaimTypes.NameIdentifier), out var id) || !int.TryParse(principal.FindFirstValue("versao"), out var versao))
                            {
                                context.Fail("Sessão inválida.");
                                return;
                            }
                            var repo = context.HttpContext.RequestServices.GetRequiredService<ColaboradorRepository>();
                            var u = await repo.BuscarPorIdAsync(id);
                            if (u == null || u.VersaoSessao != versao || principal.FindFirstValue(ClaimTypes.Role) != (u.TrocarSenha ? "TrocaSenha" : u.Perfil))
                            {
                                context.Fail("Sessão revogada.");
                                return;
                            }
                            if (!u.TrocarSenha)
                            {
                                var db = context.HttpContext.RequestServices.GetRequiredService<PimDbContext>();
                                if (!Guid.TryParse(principal.FindFirstValue("sid"), out var sid) || !await db.Sessoes.AnyAsync(s => s.Id == sid && s.ColaboradorId == id && s.UltimaAtividade > DateTime.UtcNow.AddMinutes(-30)))
                                    context.Fail("Sessão encerrada por inatividade.");
                            }
                        }
                    };
                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidateAudience = true,
                        ValidateLifetime = true,
                        ValidateIssuerSigningKey = true,
                        ValidIssuer = builder.Configuration["Jwt:Issuer"],
                        ValidAudience = builder.Configuration["Jwt:Audience"],
                        IssuerSigningKey = new SymmetricSecurityKey(
                            Encoding.UTF8.GetBytes(jwtKey))
                    };
                });

            // 5. CORS
            builder.Services.AddCors(options =>
            {
                options.AddPolicy("AllowAll", policy =>
                {
                    policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
                });
            });

            var app = builder.Build();

            if (args.Contains("--atualizar-banco"))
            {
                using var scope = app.Services.CreateScope();
                AtualizadorBanco.ExecutarAsync(scope.ServiceProvider.GetRequiredService<PimDbContext>()).GetAwaiter().GetResult();
                return;
            }

            // Middlewares
            app.UseCors("AllowAll");

            app.UseSwagger();
            app.UseSwaggerUI();

            app.UseAuthentication();
            app.UseAuthorization();
            app.MapControllers();

            app.Run();
        }
    }
}
