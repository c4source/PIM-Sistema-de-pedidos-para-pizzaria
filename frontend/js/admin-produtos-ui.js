var ProdutosUI = {
  filtrar: function (produtos, filtros) {
    function normalizar(texto) {
      return String(texto || '')
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .toLowerCase();
    }
    return produtos
      .filter(function (p) {
        var saldo = Number(p.estoque) || 0;
        var disponivel = p.disponivel !== false && saldo > 0;
        return (
          normalizar(p.nome).includes(normalizar(filtros.busca)) &&
          (filtros.categoria === 'todos' || p.categoria === filtros.categoria) &&
          (filtros.status === 'todos' ||
            (filtros.status === 'disponivel' && disponivel) ||
            (filtros.status === 'sem_estoque' && p.disponivel !== false && saldo === 0) ||
            (filtros.status === 'desativado' && p.disponivel === false) ||
            (filtros.status === 'indisponivel' && !disponivel)) &&
          (filtros.tipo === 'todos' || (filtros.tipo === 'kit' ? p.ehKit : !p.ehKit)) &&
          (filtros.estoque === 'todos' ||
            (filtros.estoque === 'zerado' && saldo === 0) ||
            (filtros.estoque === 'baixo' && saldo > 0 && saldo <= 5) ||
            (filtros.estoque === 'positivo' && saldo > 0))
        );
      })
      .sort(function (a, b) {
        var ad = a.disponivel !== false && a.estoque > 0;
        var bd = b.disponivel !== false && b.estoque > 0;
        return Number(bd) - Number(ad) || a.nome.localeCompare(b.nome, 'pt-BR');
      });
  },
  salvar: async function (acoes) {
    await acoes.persistir();
    acoes.fechar();
    acoes.notificar();
    try {
      await acoes.recarregar();
    } catch (erro) {
      acoes.avisar(
        'Alteração salva, mas não foi possível atualizar a lista. Atualize a página antes de continuar.'
      );
    }
  }
};
if (typeof module !== 'undefined') module.exports = ProdutosUI;
