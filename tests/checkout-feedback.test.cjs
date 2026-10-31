const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
async function erro(status, body) {
  const context = { fetch: async () => ({ ok: false, status, text: async () => body }) };
  vm.createContext(context);
  vm.runInContext(
    fs.readFileSync(require('node:path').join(__dirname, '../frontend/js/api.js'), 'utf8'),
    context
  );
  return context.finalizarPedido({});
}
test('Falta de estoque preserva mensagem específica da API', async () => {
  await assert.rejects(
    erro(400, 'Quantidade disponível: 1. Quantidade solicitada: 2.'),
    /disponível: 1/
  );
});
test('Validação por campo é apresentada em texto legível', async () => {
  await assert.rejects(
    erro(400, JSON.stringify({ errors: { Nome: ['Informe seu nome.'] } })),
    /Informe seu nome/
  );
});
test('Falha interna não expõe mensagem técnica do servidor', async () => {
  await assert.rejects(
    erro(500, 'Erro SQL interno'),
    (e) => !e.message.includes('SQL') && e.message.includes('instantes')
  );
});
