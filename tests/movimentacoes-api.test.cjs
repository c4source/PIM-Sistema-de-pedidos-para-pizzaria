const assert = require('node:assert/strict');
const { randomUUID, randomBytes } = require('node:crypto');
const fs = require('node:fs');
const base = process.env.PIM_TEST_API || 'http://localhost:5163/api';
const limpeza = process.env.PIM_TEST_CLEANUP_SQL;
if (!limpeza)
  throw Error('Informe PIM_TEST_CLEANUP_SQL para permitir a limpeza dos dados de teste.');
const produtos = [],
  usuarios = [],
  sessoes = [];
let token;
async function req(path, method = 'GET', body, status = 200, credencial = token) {
  const r = await fetch(base + path, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(credencial ? { Authorization: 'Bearer ' + credencial } : {})
    },
    body: body ? JSON.stringify(body) : undefined
  });
  const raw = await r.text();
  assert.equal(
    r.status,
    status,
    method + ' ' + path + ': ' + (r.status >= 400 ? raw : 'status inesperado')
  );
  try {
    return JSON.parse(raw);
  } catch {
    return raw;
  }
}
function lembrar(t) {
  const sid = JSON.parse(Buffer.from(t.split('.')[1], 'base64url')).sid;
  if (sid) sessoes.push(sid);
  return t;
}
async function saldo(id, n) {
  assert.equal((await req('/Produto/' + id)).estoque, n);
}
async function criar(estoque, kit = false, componentes = []) {
  const p = await req(
    '/Produto',
    'POST',
    {
      nome: 'Teste Sync ' + randomUUID(),
      preco: 10,
      categoria: kit ? 'combo' : 'pizza',
      status: 'disponivel',
      estoque,
      ehKit: kit,
      componentes
    },
    201
  );
  produtos.push(p.id);
  return p.id;
}
function mov(produtoId, tipo, quantidade, operacaoId = randomUUID()) {
  return { produtoId, tipo, quantidade, operacaoId };
}
async function run() {
  token = lembrar(
    (
      await req('/Auth/login-colaborador', 'POST', {
        email: process.env.PIM_TEST_ADMIN_EMAIL || 'admin@pim.com',
        senha: process.env.PIM_TEST_ADMIN_PASSWORD || '123456'
      })
    ).token
  );
  const q = await criar(6);
  await req('/Produto/' + q + '/estoque-minimo', 'PATCH', { estoqueMinimo: 3 }, 204);
  assert.equal((await req('/Produto/' + q)).estoqueMinimo, 3);
  const contagem = {
    ...mov(q, 'saida', 2),
    motivo: 'contagem',
    estoqueEsperado: 6,
    quantidadeContada: 4,
    observacao: 'Inventário de teste'
  };
  await req('/MovimentacaoEstoque', 'POST', contagem, 201);
  await req('/MovimentacaoEstoque', 'POST', contagem, 201);
  await saldo(q, 4);
  await req(
    '/MovimentacaoEstoque',
    'POST',
    { ...mov(q, 'saida', 3), motivo: 'contagem', estoqueEsperado: 6, quantidadeContada: 3 },
    409
  );
  await saldo(q, 4);
  const filtrado = await req('/MovimentacaoEstoque?produto=' + q + '&tipo=saida');
  assert.equal(filtrado.total, 1);
  assert.equal(filtrado.itens[0].observacao, 'Inventário de teste');
  await req(
    '/MovimentacaoEstoque',
    'POST',
    { ...mov(q, 'entrada', 1), motivo: 'contagem', estoqueEsperado: 4 },
    400
  );
  const p = await criar(5);
  const entrada = mov(p, 'entrada', 2);
  const respostas = await Promise.all([
    req('/MovimentacaoEstoque', 'POST', entrada, 201),
    req('/MovimentacaoEstoque', 'POST', entrada, 201)
  ]);
  assert.equal(respostas[0].id, respostas[1].id);
  await saldo(p, 7);
  await req('/MovimentacaoEstoque', 'POST', { ...entrada, quantidade: 3 }, 400);
  await saldo(p, 7);
  const saidas = [mov(p, 'saida', 5), mov(p, 'saida', 5)];
  const concorrentes = await Promise.all(
    saidas.map(async (body) => {
      const r = await fetch(base + '/MovimentacaoEstoque', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token },
        body: JSON.stringify(body)
      });
      return { body, status: r.status };
    })
  );
  assert.deepEqual(concorrentes.map((r) => r.status).sort(), [201, 400]);
  await saldo(p, 2);
  const rejeitada = concorrentes.find((r) => r.status === 400).body;
  await req('/MovimentacaoEstoque', 'POST', mov(p, 'entrada', 3), 201);
  await req('/MovimentacaoEstoque', 'POST', rejeitada, 201);
  await saldo(p, 0);
  await req('/MovimentacaoEstoque', 'POST', mov(p, 'entrada', 0), 400);
  await req(
    '/MovimentacaoEstoque',
    'POST',
    mov(p, 'entrada', 1, '00000000-0000-0000-0000-000000000000'),
    400
  );
  const kit = await criar(0, true, [{ idProduto: p, quantidade: 1 }]);
  await req('/MovimentacaoEstoque', 'POST', mov(kit, 'entrada', 1), 400);
  await req('/MovimentacaoEstoque', 'POST', mov(p, 'entrada', 2147483647), 201);
  await req('/MovimentacaoEstoque', 'POST', mov(p, 'entrada', 1), 400);
  await saldo(p, 2147483647);
  const email = 'sync-' + randomUUID() + '@example.test';
  const criado = await req(
    '/Colaboradores',
    'POST',
    { nome: 'Teste Sync Mobile', email, perfil: 'Colaborador' },
    201
  );
  usuarios.push(criado.colaborador.id);
  const provisorio = (
    await req('/Auth/login-colaborador', 'POST', { email, senha: criado.senhaProvisoria })
  ).token;
  await req('/MovimentacaoEstoque', 'POST', mov(p, 'entrada', 1), 403, provisorio);
  const nova = randomBytes(20).toString('base64url');
  const colaborador = lembrar(
    (
      await req(
        '/Auth/trocar-senha',
        'POST',
        { novaSenha: nova, confirmacaoSenha: nova },
        200,
        provisorio
      )
    ).token
  );
  await req('/MovimentacaoEstoque', 'POST', entrada, 400, colaborador);
  await req('/Colaboradores', 'GET', undefined, 403, colaborador);
  await req('/MovimentacaoEstoque', 'POST', mov(p, 'saida', 1), 201, colaborador);
  await req('/Colaboradores/' + criado.colaborador.id, 'DELETE', undefined, 400);
  await req('/Colaboradores/' + criado.colaborador.id + '/ativo', 'PATCH', { ativo: false }, 204);
  await req('/Auth/sessao', 'GET', undefined, 401, colaborador);
  await req('/Auth/login-colaborador', 'POST', { email, senha: nova }, 401);
  assert.equal(
    (await req('/Colaboradores')).find((u) => u.id === criado.colaborador.id).ativo,
    false
  );
  await req('/Colaboradores/' + criado.colaborador.id + '/ativo', 'PATCH', { ativo: true }, 204);
  const reativado = lembrar(
    (await req('/Auth/login-colaborador', 'POST', { email, senha: nova })).token
  );
  await req('/Auth/sessao', 'GET', undefined, 200, reativado);
  const autorClaims = JSON.parse(Buffer.from(token.split('.')[1], 'base64url'));
  const autorId = Number(
    autorClaims.nameid ??
      autorClaims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
      autorClaims.sub
  );
  await req('/Colaboradores/' + autorId + '/ativo', 'PATCH', { ativo: false }, 400);
  const historico = await req('/MovimentacaoEstoque?tamanho=100');
  assert.equal(historico.itens.filter((m) => m.operacaoId === entrada.operacaoId).length, 1);
  assert.ok(historico.itens.some((m) => m.produtoId === p && m.produto && m.colaborador));
  await req('/MovimentacaoEstoque?pagina=0', 'GET', undefined, 400);
  await req('/MovimentacaoEstoque', 'GET', undefined, 401, null);
  console.log(
    'OK: idempotência concorrente, saldo atômico, rejeição/reenvio, limites, kits, filtros, contagem concorrente e suspensão de acesso.'
  );
}
run()
  .catch((e) => {
    console.error(e.message);
    process.exitCode = 1;
  })
  .finally(() => {
    const sql = ['BEGIN;'];
    if (produtos.length) {
      const ids = produtos.join(',');
      sql.push(
        'DELETE FROM movimentacao_estoque WHERE codprod IN (' + ids + ');',
        'DELETE FROM kit_componente WHERE id_kit IN (' + ids + ');',
        'DELETE FROM produto WHERE codprod IN (' + ids + ');'
      );
    }
    if (sessoes.length)
      sql.push(
        'DELETE FROM sessao_acesso WHERE id IN (' +
          sessoes.map((s) => "'" + s + "'").join(',') +
          ');'
      );
    if (usuarios.length)
      sql.push('DELETE FROM colaborador WHERE id_colaborador IN (' + usuarios.join(',') + ');');
    sql.push('COMMIT;');
    fs.writeFileSync(limpeza, sql.join('\n'));
  });
