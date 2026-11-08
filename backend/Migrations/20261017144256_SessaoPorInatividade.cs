using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Pim.Migrations
{
    /// <inheritdoc />
    public partial class SessaoPorInatividade : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "sessao_acesso",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    id_colaborador = table.Column<int>(type: "integer", nullable: false),
                    ultima_atividade = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_sessao_acesso", x => x.id);
                    table.ForeignKey(
                        name: "FK_sessao_acesso_colaborador_id_colaborador",
                        column: x => x.id_colaborador,
                        principalTable: "colaborador",
                        principalColumn: "id_colaborador",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_sessao_acesso_id_colaborador",
                table: "sessao_acesso",
                column: "id_colaborador");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "sessao_acesso");
        }
    }
}
