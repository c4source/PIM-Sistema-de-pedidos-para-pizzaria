const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const root = path.join(__dirname, '..');
function ctx(data) {
  const local = new Map(),
    session = new Map();
  const elements = {};
  let body;
  for (const id of [
    'admin-username',
    'admin-password',
    'admin-login-button',
    'admin-login-error',
    'admin-back-button'
  ])
    elements[id] = { value: '', addEventListener() {} };
  elements['admin-username'].value = 'teste@example.com';
  elements['admin-password'].value = ' senha com espaços ';
  const c = {
    localStorage: {
      getItem: (k) => local.get(k) || null,
      setItem: (k, v) => local.set(k, String(v)),
      removeItem: (k) => local.delete(k)
    },
    sessionStorage: {
      getItem: (k) => session.get(k) || null,
      setItem: (k, v) => session.set(k, String(v)),
      removeItem: (k) => session.delete(k)
    },
    document: { getElementById: (k) => elements[k] },
    window: { location: {} },
    fetch: async (url, options) => {
      body = JSON.parse(options.body);
      return { ok: true, json: async () => data };
    },
    console
  };
  vm.createContext(c);
  for (const file of ['admin-api.js', 'admin-login.js'])
    vm.runInContext(fs.readFileSync(path.join(root, 'frontend/js', file), 'utf8'), c);
  return {
    c,
    local,
    session,
    elements,
    get body() {
      return body;
    }
  };
}
test('Senha provisória direciona à troca sem liberar sessão administrativa', async () => {
  const x = ctx({
    token: 'restrito',
    usuario: 'Teste',
    perfil: 'Administrador',
    trocaSenhaObrigatoria: true
  });
  await x.c.validateAdminLogin();
  assert.equal(x.session.get('trocaSenhaToken'), 'restrito');
  assert.equal(x.local.has('adminToken'), false);
  assert.equal(x.c.window.location.href, './admin-trocar-senha.html');
});
test('Login normal armazena perfil e preserva espaços da senha', async () => {
  const x = ctx({
    token: 'normal',
    id: 9,
    usuario: 'Teste',
    perfil: 'Colaborador',
    trocaSenhaObrigatoria: false
  });
  await x.c.validateAdminLogin();
  assert.equal(x.local.get('adminPerfil'), 'Colaborador');
  assert.equal(x.local.get('adminId'), '9');
  assert.equal(x.body.senha, ' senha com espaços ');
  assert.equal(x.c.window.location.href, './admin-dashboard.html');
});
test('Sair limpa token normal e token de primeiro acesso', () => {
  const x = ctx({});
  x.local.set('adminToken', 'normal');
  x.session.set('trocaSenhaToken', 'restrito');
  x.c.clearAdminSession();
  assert.equal(x.local.has('adminToken'), false);
  assert.equal(x.session.has('trocaSenhaToken'), false);
});
