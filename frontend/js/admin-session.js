(function () {
  if (!getAdminToken()) return;
  var limite = 30 * 60 * 1000,
    aviso = 29 * 60 * 1000,
    enviando = false,
    ultimoEnvio = 0;
  var chave = 'adminUltimaAtividade';
  if (!localStorage.getItem(chave)) localStorage.setItem(chave, String(Date.now()));
  var modal = document.createElement('dialog');
  modal.setAttribute('aria-labelledby', 'sessao-aviso-titulo');
  modal.style.cssText =
    'margin:auto;padding:28px;border:1px solid #dce3eb;border-radius:20px;width:min(420px,calc(100vw - 32px));color:#263244;background:white;box-shadow:0 20px 80px #17212c40;text-align:center';
  var titulo = document.createElement('h2');
  titulo.id = 'sessao-aviso-titulo';
  titulo.textContent = 'Sua sessão está prestes a expirar';
  titulo.style.fontSize = '1.2rem';
  var texto = document.createElement('p');
  texto.textContent = 'Você está há algum tempo sem interagir. Deseja continuar conectado?';
  texto.style.cssText = 'margin:18px 0;line-height:1.6';
  var botao = document.createElement('button');
  botao.type = 'button';
  botao.textContent = 'Continuar conectado';
  botao.className = 'primary-button';
  botao.style.cssText = 'padding:12px 18px;min-height:44px;border-radius:10px;cursor:pointer';
  modal.append(titulo, texto, botao);
  document.body.appendChild(modal);
  function encerrar() {
    clearAdminSession();
    window.location.replace('./admin-login.html?motivo=inatividade');
  }
  function verificar() {
    if (!getAdminToken()) {
      window.location.replace('./admin-login.html');
      return false;
    }
    var tempo = Date.now() - Number(localStorage.getItem(chave) || 0);
    if (tempo >= limite) {
      encerrar();
      return false;
    }
    if (tempo >= aviso && !modal.open) modal.showModal();
    if (tempo < aviso && modal.open) modal.close();
    return true;
  }
  async function atividade(forcar) {
    if (!verificar() || enviando || (!forcar && (modal.open || Date.now() - ultimoEnvio < 60000)))
      return;
    enviando = true;
    ultimoEnvio = Date.now();
    try {
      var response = await fetch(ADMIN_API_BASE_URL + '/Auth/atividade', {
        method: 'POST',
        headers: { Authorization: 'Bearer ' + getAdminToken() }
      });
      if (response.status === 401) {
        encerrar();
        return;
      }
      if (response.ok) {
        localStorage.setItem(chave, String(Date.now()));
        if (modal.open) modal.close();
      }
    } catch (_) {
      /* Sem conexão, mantém o prazo local; a API valida novamente ao reconectar. */
    } finally {
      enviando = false;
    }
  }
  botao.addEventListener('click', function () {
    atividade(true);
  });
  modal.addEventListener('cancel', function (event) {
    event.preventDefault();
  });
  ['pointerdown', 'keydown', 'scroll', 'pointermove', 'touchstart'].forEach(function (event) {
    window.addEventListener(
      event,
      function () {
        atividade(false);
      },
      { passive: true }
    );
  });
  window.addEventListener('focus', verificar);
  document.addEventListener('visibilitychange', verificar);
  window.addEventListener('storage', function (event) {
    if (event.key === chave || event.key === 'adminToken') verificar();
  });
  setInterval(verificar, 5000);
  atividade(true);
})();
