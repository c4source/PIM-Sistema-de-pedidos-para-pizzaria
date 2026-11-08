const { test } = require('node:test');
const assert = require('node:assert/strict');
const ui = require('../frontend/js/admin-produtos-ui.js');
const produtos = [
  { id: 1, nome: 'Água mineral', categoria: 'bebida', estoque: 10, disponivel: true, ehKit: false },
  { id: 2, nome: 'Combo Família', categoria: 'combo', estoque: 3, disponivel: true, ehKit: true },
  { id: 3, nome: 'Pizza Frango', categoria: 'pizza', estoque: 0, disponivel: true, ehKit: false },
  { id: 4, nome: 'Pizza Doce', categoria: 'doce', estoque: 8, disponivel: false, ehKit: false }
];
const filtros = { busca: '', categoria: 'todos', status: 'todos', tipo: 'todos', estoque: 'todos' };
test('Busca ignora acentos e diferenciação de maiúsculas', () => {
  assert.deepEqual(
    ui.filtrar(produtos, { ...filtros, busca: 'AGUA' }).map((p) => p.id),
    [1]
  );
});
test('Busca, categoria, tipo e estoque combinam entre si', () => {
  assert.deepEqual(
    ui
      .filtrar(produtos, {
        ...filtros,
        busca: 'familia',
        categoria: 'combo',
        tipo: 'kit',
        estoque: 'baixo'
      })
      .map((p) => p.id),
    [2]
  );
});
test('Disponibilidade considera saldo sem sobrescrever a escolha manual', () => {
  assert.deepEqual(
    ui.filtrar(produtos, { ...filtros, status: 'disponivel' }).map((p) => p.id),
    [1, 2]
  );
  assert.deepEqual(
    ui.filtrar(produtos, { ...filtros, estoque: 'zerado' }).map((p) => p.id),
    [3]
  );
  assert.equal(produtos[2].disponivel, true);
  assert.equal(produtos[3].disponivel, false);
});
test('Baixo estoque inclui 1 a 5 e exclui saldo zero', () => {
  const rows = [0, 1, 5, 6].map((n) => ({ nome: String(n), estoque: n }));
  assert.deepEqual(
    ui.filtrar(rows, { ...filtros, estoque: 'baixo' }).map((p) => p.estoque),
    [1, 5]
  );
});
test('Edição salva fecha pop-up e informa sucesso antes de atualizar lista', async () => {
  let events = [];
  await ui.salvar({
    persistir: async () => events.push('salvou'),
    fechar: () => events.push('fechou'),
    notificar: () => events.push('sucesso'),
    recarregar: async () => events.push('lista'),
    avisar: () => events.push('aviso')
  });
  assert.deepEqual(events, ['salvou', 'fechou', 'sucesso', 'lista']);
});
test('Falha ao salvar mantém formulário e dados para correção', async () => {
  let events = [];
  await assert.rejects(
    ui.salvar({
      persistir: async () => {
        throw Error('falha');
      },
      fechar: () => events.push('fechou'),
      notificar: () => events.push('sucesso')
    }),
    /falha/
  );
  assert.deepEqual(events, []);
});
test('Falha na lista após salvar preserva confirmação e mostra aviso separado', async () => {
  let events = [];
  await ui.salvar({
    persistir: async () => events.push('salvou'),
    fechar: () => events.push('fechou'),
    notificar: () => events.push('sucesso'),
    recarregar: async () => {
      throw Error('rede');
    },
    avisar: (msg) => events.push(msg)
  });
  assert.deepEqual(events.slice(0, 3), ['salvou', 'fechou', 'sucesso']);
  assert.match(events[3], /Alteração salva/);
});

test('Situação de venda distingue saldo zerado de desativação manual', () => {
  assert.deepEqual(
    ui.filtrar(produtos, { ...filtros, status: 'sem_estoque' }).map((p) => p.id),
    [3]
  );
  assert.deepEqual(
    ui.filtrar(produtos, { ...filtros, status: 'desativado' }).map((p) => p.id),
    [4]
  );
});
