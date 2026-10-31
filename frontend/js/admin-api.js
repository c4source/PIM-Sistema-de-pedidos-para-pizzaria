var ADMIN_API_BASE_URL = 'http://localhost:5162/api';

function getAdminToken() {
  return localStorage.getItem('adminToken');
}

function hasAdminSession() {
  return Boolean(getAdminToken());
}

function clearAdminSession() {
  var tokenAnterior = getAdminToken();
  if (tokenAnterior) {
    try {
      Promise.resolve(
        fetch(ADMIN_API_BASE_URL + '/Auth/sair', {
          method: 'POST',
          headers: { Authorization: 'Bearer ' + tokenAnterior },
          keepalive: true
        })
      ).catch(function () {});
    } catch (_) {}
  }
  localStorage.removeItem('adminUltimaAtividade');
  sessionStorage.removeItem('trocaSenhaToken');
  localStorage.removeItem('adminId');
  localStorage.removeItem('adminToken');
  localStorage.removeItem('adminNome');
  localStorage.removeItem('adminPerfil');
  localStorage.removeItem('adminLogado');
}

function redirectToAdminLogin() {
  window.location.href = './admin-login.html';
}

function requireAdminSession() {
  if (!hasAdminSession()) {
    redirectToAdminLogin();
    return false;
  }

  return true;
}

function handleUnauthorized(response) {
  if (response.status === 401) {
    clearAdminSession();
    redirectToAdminLogin();
    return true;
  }

  return false;
}

function normalizeApiStatus(status) {
  return String(status || '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, '_');
}

function normalizeApiProduct(product) {
  var status = String(
    product.status || product.Status || product.status_disponibilidade || ''
  ).toLowerCase();
  var isUnavailable =
    product.disponivel === false ||
    status === 'false' ||
    status === 'indisponivel' ||
    status === 'indisponível';

  return {
    id: product.id || product.Id || product.codprod,
    ehKit: Boolean(product.ehKit),
    componentes: product.componentes || [],
    nome: product.nome || product.Nome || product.nome_produto || '',
    categoria: product.categoria || product.Categoria || '',
    preco: Number(product.preco || product.Preco || 0),
    imagem: product.imagemUrl || product.ImagemUrl || product.imagem || product.imagem_url || '',
    descricao: product.descricao || product.Descricao || '',
    estoque:
      Number.isInteger(Number(product.estoque || product.Estoque)) &&
      Number(product.estoque || product.Estoque) >= 0
        ? Number(product.estoque || product.Estoque)
        : 0,
    disponivel: !isUnavailable
  };
}

function createProductPayload(productData) {
  return {
    ehKit: Boolean(productData.ehKit),
    componentes: productData.componentes || [],
    nome: productData.nome,
    preco: productData.preco,
    descricao: productData.descricao,
    categoria: productData.categoria,
    status: productData.disponivel === false ? 'indisponivel' : 'disponivel',
    estoque: productData.estoque,
    imagemUrl: productData.imagem
  };
}

function normalizeApiOrder(apiOrder) {
  var rua = apiOrder.ruaEntrega || apiOrder.RuaEntrega;
  var numero = apiOrder.numeroEntrega || apiOrder.NumeroEntrega;
  var bairro = apiOrder.bairroEntrega || apiOrder.BairroEntrega;
  var complemento = apiOrder.complementoEntrega || apiOrder.ComplementoEntrega;
  var itens = apiOrder.itens || apiOrder.Itens || [];

  return {
    id: apiOrder.id || apiOrder.Id,
    codigo: apiOrder.codigo || apiOrder.Codigo,
    cliente: {
      nome: apiOrder.nomeCliente || apiOrder.NomeCliente,
      telefone: apiOrder.telefoneCliente || apiOrder.TelefoneCliente
    },
    observacoes: apiOrder.observacoes || apiOrder.Observacoes,
    dataHora: apiOrder.dataHora || apiOrder.DataHora,
    status: normalizeApiStatus(apiOrder.status || apiOrder.Status),
    total: Number(apiOrder.valorTotal || apiOrder.ValorTotal || 0),
    tipoEntrega: apiOrder.tipoEntrega || apiOrder.TipoEntrega,
    endereco:
      rua || numero || bairro || complemento
        ? {
            rua: rua,
            numero: numero,
            bairro: bairro,
            complemento: complemento
          }
        : null,
    pagamento: {
      formaPagamento: apiOrder.formaPagamento || apiOrder.FormaPagamento,
      statusPagamento: apiOrder.statusPagamento || apiOrder.StatusPagamento
    },
    itens: itens.map(function (item) {
      return {
        id: item.id || item.Id,
        codProd: item.codProd || item.CodProd,
        nome: item.produto || item.Produto || 'Produto não informado',
        quantidade: item.quantidade || item.Quantidade || 0,
        precoUnitario: Number(item.precoUnitario || item.PrecoUnitario || 0),
        subtotal: Number(item.subtotal || item.Subtotal || 0)
      };
    })
  };
}

async function fetchAdminOrders() {
  var response = await fetch(ADMIN_API_BASE_URL + '/Pedido', {
    headers: {
      Authorization: 'Bearer ' + getAdminToken()
    }
  });

  if (handleUnauthorized(response)) {
    return [];
  }

  if (!response.ok) {
    throw new Error('Não foi possível carregar os pedidos.');
  }

  var orders = await response.json();
  return orders.map(normalizeApiOrder);
}

async function updateAdminOrderStatus(orderId, status) {
  var response = await fetch(ADMIN_API_BASE_URL + '/Pedido/' + orderId + '/status', {
    method: 'PATCH',
    headers: {
      Authorization: 'Bearer ' + getAdminToken(),
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ status: status })
  });

  if (handleUnauthorized(response)) {
    return false;
  }

  if (!response.ok) {
    throw new Error('Não foi possível atualizar o status do pedido.');
  }

  return true;
}

async function fetchAdminProducts() {
  var response = await fetch(ADMIN_API_BASE_URL + '/Produto', {
    headers: {
      Authorization: 'Bearer ' + getAdminToken()
    }
  });

  if (handleUnauthorized(response)) {
    return [];
  }

  if (!response.ok) {
    throw new Error('Não foi possível carregar os produtos.');
  }

  var products = await response.json();
  return products.map(normalizeApiProduct);
}

async function createAdminProduct(productData) {
  var response = await fetch(ADMIN_API_BASE_URL + '/Produto', {
    method: 'POST',
    headers: {
      Authorization: 'Bearer ' + getAdminToken(),
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(createProductPayload(productData))
  });

  if (handleUnauthorized(response)) {
    return null;
  }

  if (!response.ok) {
    throw new Error((await response.text()) || 'Não foi possível cadastrar o produto.');
  }

  return normalizeApiProduct(await response.json());
}

async function updateAdminProduct(productId, productData) {
  var response = await fetch(ADMIN_API_BASE_URL + '/Produto/' + productId, {
    method: 'PUT',
    headers: {
      Authorization: 'Bearer ' + getAdminToken(),
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(createProductPayload(productData))
  });

  if (handleUnauthorized(response)) {
    return false;
  }

  if (!response.ok) {
    throw new Error((await response.text()) || 'Não foi possível atualizar o produto.');
  }

  return true;
}

async function deleteAdminProduct(productId) {
  var response = await fetch(ADMIN_API_BASE_URL + '/Produto/' + productId, {
    method: 'DELETE',
    headers: {
      Authorization: 'Bearer ' + getAdminToken()
    }
  });

  if (handleUnauthorized(response)) {
    return false;
  }

  if (!response.ok) {
    throw new Error((await response.text()) || 'Não foi possível excluir o produto.');
  }

  return true;
}

function salvarSessaoAdmin(data) {
  clearAdminSession();
  localStorage.setItem('adminToken', data.token);
  localStorage.setItem('adminId', data.id);
  localStorage.setItem('adminNome', data.usuario);
  localStorage.setItem('adminPerfil', data.perfil);
  localStorage.setItem('adminLogado', 'true');
}
async function adminRequest(path, options) {
  options = options || {};
  options.headers = Object.assign(
    { 'Content-Type': 'application/json', Authorization: 'Bearer ' + getAdminToken() },
    options.headers || {}
  );
  var response = await fetch(ADMIN_API_BASE_URL + path, options);
  if (response.status === 401) {
    clearAdminSession();
    redirectToAdminLogin();
    throw new Error('Sessão expirada. Entre novamente.');
  }
  if (response.status === 403)
    throw new Error('Somente administradores podem gerenciar colaboradores.');
  if (!response.ok) {
    var text = await response.text();
    try {
      var problem = JSON.parse(text);
      text = problem.errors
        ? Object.values(problem.errors).flat().join(' ')
        : problem.title || text;
    } catch (_) {}
    throw new Error(text);
  }
  return response.status === 204 ? null : response.json();
}
