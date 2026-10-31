const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
function iniciar() {
  let agora = 100000000;
  let local = new Map([['adminToken', 'token']]);
  let eventos = {};
  let timer;
  let modal;
  let pedidos = 0;
  function node() {
    return {
      style: {},
      append() {},
      setAttribute() {},
      addEventListener(k, f) {
        this[k] = f;
      },
      showModal() {
        this.open = true;
      },
      close() {
        this.open = false;
      }
    };
  }
  const c = {
    getAdminToken: () => local.get('adminToken'),
    localStorage: { getItem: (k) => local.get(k) || null, setItem: (k, v) => local.set(k, v) },
    Date: { now: () => agora },
    clearAdminSession: () => {
      local.delete('adminToken');
      local.delete('adminUltimaAtividade');
    },
    window: {
      location: {
        replace(p) {
          this.destino = p;
        }
      },
      addEventListener(k, f) {
        eventos[k] = f;
      }
    },
    document: {
      body: {
        appendChild(n) {
          modal = n;
        }
      },
      createElement: node,
      addEventListener() {}
    },
    ADMIN_API_BASE_URL: 'http://teste',
    fetch: async () => {
      pedidos++;
      return { ok: true, status: 200 };
    },
    setInterval: (f) => (timer = f)
  };
  vm.createContext(c);
  vm.runInContext(
    fs.readFileSync(path.join(__dirname, '../frontend/js/admin-session.js'), 'utf8'),
    c
  );
  return {
    c,
    local,
    eventos,
    get modal() {
      return modal;
    },
    get pedidos() {
      return pedidos;
    },
    avancar(ms) {
      agora += ms;
    },
    verificar() {
      timer();
    }
  };
}
const tick = () => new Promise((r) => setImmediate(r));
test('Timer automático não renova a sessão', async () => {
  let x = iniciar();
  await tick();
  assert.equal(x.pedidos, 1);
  x.avancar(60000);
  x.verificar();
  await tick();
  assert.equal(x.pedidos, 1);
});
test('Após 29 minutos apresenta aviso sem renovar atividade', async () => {
  let x = iniciar();
  await tick();
  x.avancar(29 * 60000);
  x.verificar();
  assert.equal(x.modal.open, true);
  assert.equal(x.pedidos, 1);
});
test('Após 30 minutos limpa a sessão e redireciona', async () => {
  let x = iniciar();
  await tick();
  x.avancar(30 * 60000);
  x.verificar();
  assert.equal(x.local.has('adminToken'), false);
  assert.match(x.c.window.location.destino, /motivo=inatividade/);
});
test('Interação após expiração não reativa a sessão', async () => {
  let x = iniciar();
  await tick();
  x.avancar(30 * 60000);
  x.eventos.pointerdown();
  await tick();
  assert.equal(x.pedidos, 1);
  assert.equal(x.local.has('adminToken'), false);
});
test('Atividade compartilhada por outra aba fecha o aviso', async () => {
  let x = iniciar();
  await tick();
  x.avancar(29 * 60000);
  x.verificar();
  assert.equal(x.modal.open, true);
  x.local.set('adminUltimaAtividade', String(100000000 + 29 * 60000));
  x.eventos.storage({ key: 'adminUltimaAtividade' });
  assert.equal(x.modal.open, false);
});
