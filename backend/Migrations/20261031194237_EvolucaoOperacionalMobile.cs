using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Pim.Migrations
{
    /// <inheritdoc />
    public partial class EvolucaoOperacionalMobile : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "estoque_minimo",
                table: "produto",
                type: "integer",
                nullable: false,
                defaultValue: 5);

            migrationBuilder.AddColumn<int>(
                name: "estoque_esperado",
                table: "movimentacao_estoque",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "motivo",
                table: "movimentacao_estoque",
                type: "character varying(30)",
                maxLength: 30,
                nullable: false,
                defaultValue: "outro");

            migrationBuilder.AddColumn<string>(
                name: "observacao",
                table: "movimentacao_estoque",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "quantidade_contada",
                table: "movimentacao_estoque",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "ativo",
                table: "colaborador",
                type: "boolean",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_produto_minimo",
                table: "produto",
                sql: "estoque_minimo >= 0");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_produto_minimo",
                table: "produto");

            migrationBuilder.DropColumn(
                name: "estoque_minimo",
                table: "produto");

            migrationBuilder.DropColumn(
                name: "estoque_esperado",
                table: "movimentacao_estoque");

            migrationBuilder.DropColumn(
                name: "motivo",
                table: "movimentacao_estoque");

            migrationBuilder.DropColumn(
                name: "observacao",
                table: "movimentacao_estoque");

            migrationBuilder.DropColumn(
                name: "quantidade_contada",
                table: "movimentacao_estoque");

            migrationBuilder.DropColumn(
                name: "ativo",
                table: "colaborador");
        }
    }
}
