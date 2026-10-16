var adminUsernameInput = document.getElementById('admin-username');
var adminPasswordInput = document.getElementById('admin-password');
var adminLoginButton = document.getElementById('admin-login-button');
var adminLoginError = document.getElementById('admin-login-error');
var adminBackButton = document.getElementById('admin-back-button');

if (hasAdminSession()) {
  window.location.href = './admin-dashboard.html';
}

function showAdminLoginError(message) {
  adminLoginError.textContent = message;
}

function clearAdminLoginError() {
  adminLoginError.textContent = '';
}

async function validateAdminLogin() {
  var email = adminUsernameInput.value.trim();
  var password = adminPasswordInput.value;

  if (!email || !password) {
    showAdminLoginError('Informe e-mail e senha.');
    return false;
  }

  adminLoginButton.disabled = true;
  clearAdminLoginError();

  try {
    var response = await fetch(ADMIN_API_BASE_URL + '/Auth/login-colaborador', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        email: email,
        senha: password
      })
    });

    if (!response.ok) {
      showAdminLoginError('E-mail ou senha inválidos.');
      return false;
    }

    var data = await response.json();

    if (!data.token) {
      showAdminLoginError('Login sem token retornado pela API.');
      return false;
    }

    if(data.trocaSenhaObrigatoria) {
      clearAdminSession();
      sessionStorage.setItem('trocaSenhaToken',data.token);
      window.location.href='./admin-trocar-senha.html';
      return true;
    }
    salvarSessaoAdmin(data);
    localStorage.setItem('adminToken', data.token);
    localStorage.setItem('adminNome', data.usuario || '');
    localStorage.setItem('adminPerfil', data.perfil || '');
    localStorage.setItem('adminLogado', 'true');
    window.location.href = './admin-dashboard.html';
    return true;
  } catch (error) {
    showAdminLoginError('Não foi possível conectar ao servidor.');
    return false;
  } finally {
    adminLoginButton.disabled = false;
  }
}

adminLoginButton.addEventListener('click', validateAdminLogin);

adminPasswordInput.addEventListener('keydown', function (event) {
  if (event.key === 'Enter') {
    validateAdminLogin();
  }
});

adminUsernameInput.addEventListener('input', clearAdminLoginError);
adminPasswordInput.addEventListener('input', clearAdminLoginError);

adminBackButton.addEventListener('click', function () {
  window.location.href = './index.html';
});
