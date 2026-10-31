using Microsoft.EntityFrameworkCore;
using Pim.Models;
namespace Pim.Data;

public class PimDbContext(DbContextOptions<PimDbContext> options) : DbContext(options)
{
    public DbSet<SessaoAcesso> Sessoes => Set<SessaoAcesso>();
    public DbSet<Produto> Produtos => Set<Produto>();
    public DbSet<Pedido> Pedidos => Set<Pedido>();
    public DbSet<ItemPedido> ItensPedido => Set<ItemPedido>();
    public DbSet<Pagamento> Pagamentos => Set<Pagamento>();
    public DbSet<Cliente> Clientes => Set<Cliente>();
    public DbSet<Colaborador> Colaboradores => Set<Colaborador>();
    public DbSet<KitComponente> ComponentesKit => Set<KitComponente>();
    public DbSet<PedidoBaixaEstoque> BaixasEstoque => Set<PedidoBaixaEstoque>();

    public DbSet<MovimentacaoEstoque> MovimentacoesEstoque => Set<MovimentacaoEstoque>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        b.Entity<SessaoAcesso>().HasOne<Colaborador>().WithMany().HasForeignKey(s => s.ColaboradorId).OnDelete(DeleteBehavior.Cascade);
        b.Entity<SessaoAcesso>().HasIndex(s => s.ColaboradorId);
        b.Entity<Produto>().ToTable(t =>
        {
            t.HasCheckConstraint("ck_produto_preco", "preco > 0");
            t.HasCheckConstraint("ck_produto_estoque", "estoque >= 0");
            t.HasCheckConstraint("ck_produto_categoria", "categoria IN ('pizza','doce','bebida','combo')");
            t.HasCheckConstraint("ck_produto_status", "status_disponibilidade IN ('disponivel','indisponivel')");
        });
        b.Entity<KitComponente>().ToTable(t => { t.HasCheckConstraint("ck_kit_quantidade", "quantidade > 0"); t.HasCheckConstraint("ck_kit_distinto", "id_kit <> id_produto"); });
        b.Entity<PedidoBaixaEstoque>().ToTable(t => t.HasCheckConstraint("ck_baixa_quantidade", "quantidade > 0"));
        b.Entity<Colaborador>().ToTable(t => t.HasCheckConstraint("ck_colaborador_perfil", "perfil IN ('Administrador','Colaborador')"));
        b.Entity<Colaborador>().Property(c => c.Perfil).HasDefaultValue("Colaborador");
        b.Entity<Colaborador>().Property(c => c.TrocarSenha).HasDefaultValue(false);
        b.Entity<Colaborador>().Property(c => c.VersaoSessao).HasDefaultValue(1);
        b.Entity<Produto>().Property(p => p.EhKit).HasDefaultValue(false);
        b.Entity<Produto>().Property(p => p.Estoque).IsRequired().HasDefaultValue(0);
        b.Entity<Produto>().Property(p => p.Preco).HasPrecision(10, 2);
        b.Entity<Produto>().Property(p => p.Categoria).IsRequired();
        b.Entity<Produto>().Property(p => p.Status).IsRequired();
        b.Entity<Pedido>().HasIndex(p => p.Codigo).IsUnique();
        b.Entity<Pedido>().Property(p => p.DataHora).HasColumnType("timestamp without time zone").HasDefaultValueSql("CURRENT_TIMESTAMP");
        b.Entity<Pedido>().Property(p => p.ValorTotal).HasPrecision(10, 2);
        b.Entity<ItemPedido>().HasOne(i => i.Pedido).WithMany(p => p.Itens).HasForeignKey(i => i.IdPedido).OnDelete(DeleteBehavior.Restrict);
        b.Entity<ItemPedido>().HasOne(i => i.Produto).WithMany().HasForeignKey(i => i.CodProd).OnDelete(DeleteBehavior.Restrict);
        b.Entity<ItemPedido>().Property(i => i.PrecoUnitario).HasPrecision(10, 2);
        b.Entity<ItemPedido>().Property(i => i.Subtotal).HasPrecision(10, 2);
        b.Entity<Pagamento>().HasOne(p => p.Pedido).WithOne(p => p.Pagamento).HasForeignKey<Pagamento>(p => p.IdPedido).OnDelete(DeleteBehavior.Restrict);
        b.Entity<Pagamento>().Property(p => p.DataHoraPagamento).HasColumnType("timestamp without time zone").HasDefaultValueSql("CURRENT_TIMESTAMP");
        b.Entity<Pagamento>().Property(p => p.ValorPago).HasPrecision(10, 2);
        b.Entity<KitComponente>().HasKey(k => new { k.IdKit, k.IdProduto });
        b.Entity<KitComponente>().HasOne<Produto>().WithMany().HasForeignKey(k => k.IdKit).OnDelete(DeleteBehavior.Cascade);
        b.Entity<KitComponente>().HasOne<Produto>().WithMany().HasForeignKey(k => k.IdProduto).OnDelete(DeleteBehavior.Restrict);
        b.Entity<MovimentacaoEstoque>(e =>
{
    e.ToTable("movimentacao_estoque", t =>
    {
        t.HasCheckConstraint(
            "movimentacao_estoque_quantidade_check",
            "quantidade > 0");

        t.HasCheckConstraint(
            "movimentacao_estoque_tipo_check",
            "tipo IN ('entrada', 'saida')");
    });

    e.Property(m => m.Tipo)
        .HasMaxLength(10)
        .IsRequired();

    e.Property(m => m.DataHora)
        .HasColumnType("timestamp without time zone")
        .HasDefaultValueSql("CURRENT_TIMESTAMP");

    e.HasOne<Produto>()
        .WithMany()
        .HasForeignKey(m => m.ProdutoId)
        .OnDelete(DeleteBehavior.Restrict)
        .HasConstraintName("fk_movimentacao_produto");

    e.HasOne<Colaborador>()
        .WithMany()
        .HasForeignKey(m => m.ColaboradorId)
        .OnDelete(DeleteBehavior.Restrict)
        .HasConstraintName("fk_movimentacao_colaborador");
});
        b.Entity<PedidoBaixaEstoque>().HasKey(p => new { p.IdPedido, p.IdProduto });
        b.Entity<PedidoBaixaEstoque>().HasOne<Pedido>().WithMany().HasForeignKey(p => p.IdPedido).OnDelete(DeleteBehavior.Restrict);
        b.Entity<PedidoBaixaEstoque>().HasOne<Produto>().WithMany().HasForeignKey(p => p.IdProduto).OnDelete(DeleteBehavior.Restrict);
        b.Entity<Cliente>().HasIndex(c => c.Email).IsUnique();
        b.Entity<Cliente>().HasIndex(c => c.Cpf).IsUnique();
        // Índice funcional preserva a unicidade de e-mail sem distinguir maiúsculas.
        b.Entity<Colaborador>().HasIndex(c => c.Email).IsUnique();
        b.Entity<Colaborador>().Property(c => c.VersaoSessao).IsConcurrencyToken();
    }
}
