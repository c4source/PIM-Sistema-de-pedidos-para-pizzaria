using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace Pim.Migrations
{
    /// <inheritdoc />
    public partial class InicialEntityFramework : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "cliente",
                columns: table => new
                {
                    id_cliente = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    nome_cliente = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    cpf_cliente = table.Column<string>(type: "character varying(11)", maxLength: 11, nullable: true),
                    celular_cliente = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    email_cliente = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    senha_cliente = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_cliente", x => x.id_cliente);
                });

            migrationBuilder.CreateTable(
                name: "colaborador",
                columns: table => new
                {
                    id_colaborador = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    perfil = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    trocar_senha = table.Column<bool>(type: "boolean", nullable: false),
                    versao_sessao = table.Column<int>(type: "integer", nullable: false),
                    nome_usuario = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    email_usuario = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    senha_usuario = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_colaborador", x => x.id_colaborador);
                    table.CheckConstraint("ck_colaborador_perfil", "perfil IN ('Administrador','Colaborador')");
                });

            migrationBuilder.CreateTable(
                name: "pedido",
                columns: table => new
                {
                    id_pedido = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    codigo = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    nome_cliente = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    telefone_cliente = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    tipo_entrega = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    rua_entrega = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: true),
                    numero_entrega = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    bairro_entrega = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    complemento_entrega = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: true),
                    observacoes = table.Column<string>(type: "text", nullable: true),
                    data_hora_pedido = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    status_pedido = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    valor_total = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_pedido", x => x.id_pedido);
                });

            migrationBuilder.CreateTable(
                name: "produto",
                columns: table => new
                {
                    codprod = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    nome_produto = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    preco = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    descricao = table.Column<string>(type: "text", nullable: true),
                    categoria = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    status_disponibilidade = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    estoque = table.Column<int>(type: "integer", nullable: false),
                    eh_kit = table.Column<bool>(type: "boolean", nullable: false),
                    imagem_url = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_produto", x => x.codprod);
                    table.CheckConstraint("ck_produto_categoria", "categoria IN ('pizza','doce','bebida','combo')");
                    table.CheckConstraint("ck_produto_estoque", "estoque >= 0");
                    table.CheckConstraint("ck_produto_preco", "preco > 0");
                    table.CheckConstraint("ck_produto_status", "status_disponibilidade IN ('disponivel','indisponivel')");
                });

            migrationBuilder.CreateTable(
                name: "pagamento",
                columns: table => new
                {
                    id_pagamento = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    id_pedido = table.Column<int>(type: "integer", nullable: false),
                    forma_pagamento = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    status_pagamento = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    valor_pago = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    data_hora_pagamento = table.Column<DateTime>(type: "timestamp without time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_pagamento", x => x.id_pagamento);
                    table.ForeignKey(
                        name: "FK_pagamento_pedido_id_pedido",
                        column: x => x.id_pedido,
                        principalTable: "pedido",
                        principalColumn: "id_pedido",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "itempedido",
                columns: table => new
                {
                    id_item_pedido = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    id_pedido = table.Column<int>(type: "integer", nullable: false),
                    codprod = table.Column<int>(type: "integer", nullable: false),
                    quantidade = table.Column<int>(type: "integer", nullable: false),
                    preco_unitario = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    subtotal = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_itempedido", x => x.id_item_pedido);
                    table.ForeignKey(
                        name: "FK_itempedido_pedido_id_pedido",
                        column: x => x.id_pedido,
                        principalTable: "pedido",
                        principalColumn: "id_pedido",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_itempedido_produto_codprod",
                        column: x => x.codprod,
                        principalTable: "produto",
                        principalColumn: "codprod",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "kit_componente",
                columns: table => new
                {
                    id_kit = table.Column<int>(type: "integer", nullable: false),
                    id_produto = table.Column<int>(type: "integer", nullable: false),
                    quantidade = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_kit_componente", x => new { x.id_kit, x.id_produto });
                    table.CheckConstraint("ck_kit_distinto", "id_kit <> id_produto");
                    table.CheckConstraint("ck_kit_quantidade", "quantidade > 0");
                    table.ForeignKey(
                        name: "FK_kit_componente_produto_id_kit",
                        column: x => x.id_kit,
                        principalTable: "produto",
                        principalColumn: "codprod",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_kit_componente_produto_id_produto",
                        column: x => x.id_produto,
                        principalTable: "produto",
                        principalColumn: "codprod",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "pedido_baixa_estoque",
                columns: table => new
                {
                    id_pedido = table.Column<int>(type: "integer", nullable: false),
                    id_produto = table.Column<int>(type: "integer", nullable: false),
                    quantidade = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_pedido_baixa_estoque", x => new { x.id_pedido, x.id_produto });
                    table.CheckConstraint("ck_baixa_quantidade", "quantidade > 0");
                    table.ForeignKey(
                        name: "FK_pedido_baixa_estoque_pedido_id_pedido",
                        column: x => x.id_pedido,
                        principalTable: "pedido",
                        principalColumn: "id_pedido",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_pedido_baixa_estoque_produto_id_produto",
                        column: x => x.id_produto,
                        principalTable: "produto",
                        principalColumn: "codprod",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_cliente_cpf_cliente",
                table: "cliente",
                column: "cpf_cliente",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_cliente_email_cliente",
                table: "cliente",
                column: "email_cliente",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_colaborador_email_usuario",
                table: "colaborador",
                column: "email_usuario",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_itempedido_codprod",
                table: "itempedido",
                column: "codprod");

            migrationBuilder.CreateIndex(
                name: "IX_itempedido_id_pedido",
                table: "itempedido",
                column: "id_pedido");

            migrationBuilder.CreateIndex(
                name: "IX_kit_componente_id_produto",
                table: "kit_componente",
                column: "id_produto");

            migrationBuilder.CreateIndex(
                name: "IX_pagamento_id_pedido",
                table: "pagamento",
                column: "id_pedido",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_pedido_codigo",
                table: "pedido",
                column: "codigo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_pedido_baixa_estoque_id_produto",
                table: "pedido_baixa_estoque",
                column: "id_produto");
            migrationBuilder.Sql("CREATE UNIQUE INDEX uq_colaborador_email_normalizado ON colaborador (lower(trim(email_usuario)))");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "cliente");

            migrationBuilder.DropTable(
                name: "colaborador");

            migrationBuilder.DropTable(
                name: "itempedido");

            migrationBuilder.DropTable(
                name: "kit_componente");

            migrationBuilder.DropTable(
                name: "pagamento");

            migrationBuilder.DropTable(
                name: "pedido_baixa_estoque");

            migrationBuilder.DropTable(
                name: "pedido");

            migrationBuilder.DropTable(
                name: "produto");
        }
    }
}
