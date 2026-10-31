using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Pim.Migrations
{
    /// <inheritdoc />
    public partial class SincronizacaoMovimentacoesMobile : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "operacao_id",
                table: "movimentacao_estoque",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_movimentacao_estoque_operacao_id",
                table: "movimentacao_estoque",
                column: "operacao_id",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_movimentacao_estoque_operacao_id",
                table: "movimentacao_estoque");

            migrationBuilder.DropColumn(
                name: "operacao_id",
                table: "movimentacao_estoque");
        }
    }
}
