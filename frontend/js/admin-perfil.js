(async function () {
  try {
    var data = await adminRequest('/Auth/sessao');
    localStorage.setItem('adminPerfil', data.perfil);
    var link = document.getElementById('admin-colaboradores-link');
    link.hidden = data.perfil !== 'Administrador';
  } catch (error) {
    console.error(error.message);
  }
})();
