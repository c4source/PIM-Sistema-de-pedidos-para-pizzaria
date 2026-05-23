if (!requireAdminSession()) {
  throw new Error('Sessao admin ausente.');
}

var totalOrdersElement = document.getElementById('admin-total-orders');
var receivedOrdersElement = document.getElementById('admin-received-orders');
var preparingOrdersElement = document.getElementById('admin-preparing-orders');
var finishedOrdersElement = document.getElementById('admin-finished-orders');
var totalRevenueElement = document.getElementById('admin-total-revenue');
var recentOrdersList = document.getElementById('admin-recent-orders-list');
var emptyOrdersElement = document.getElementById('admin-empty-orders');
var logoutButton = document.getElementById('admin-logout-button');
var menuButton = document.getElementById('admin-menu-button');
var ordersLink = document.getElementById('admin-orders-link');
var productsLink = document.getElementById('admin-products-link');
var kitchenLink = document.getElementById('admin-kitchen-link');
var pedidos = [];

function formatPrice(value) {
  return 'R$ ' + value.toFixed(2).replace('.', ',');
}

function normalizeStatus(status) {
  return String(status || '').toLowerCase().replace(/\s+/g, '_');
}

function formatStatus(status) {
  var normalizedStatus = normalizeStatus(status);

  if (normalizedStatus === 'recebido') {
    return 'Recebido';
  }

  if (normalizedStatus === 'em_preparo') {
    return 'Em preparo';
  }

  if (normalizedStatus === 'pronto') {
    return 'Pronto';
  }

  if (normalizedStatus === 'finalizado' || normalizedStatus === 'finalizados') {
    return 'Finalizado';
  }

  if (normalizedStatus === 'cancelado') {
    return 'Cancelado';
  }

  return status || 'Sem status';
}

function formatDeliveryType(tipoEntrega) {
  return tipoEntrega === 'entrega' ? 'Entrega' : 'Retirada';
}

function formatOrderCode(codigo) {
  if (!codigo) {
    return '#PED000';
  }

  const apenasNumeros = String(codigo).replace(/\D/g, '');

  if (!apenasNumeros) {
    return '#PED000';
  }

  const numeroFormatado = apenasNumeros.slice(-3).padStart(3, '0');

  return '#PED' + numeroFormatado;
}

function formatDateTime(dataHora) {
  if (!dataHora) {
    return 'Data não informada';
  }

  var date = new Date(dataHora);

  if (isNaN(date.getTime())) {
    return 'Data não informada';
  }

  return date.toLocaleString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
}

function getOrderTotal(order) {
  return Number(order.total) || 0;
}

function getOrderTime(order) {
  var time = new Date(order.dataHora).getTime();
  return isNaN(time) ? 0 : time;
}

function renderMetrics() {
  var receivedOrders = pedidos.filter(function (pedido) {
    return normalizeStatus(pedido.status) === 'recebido';
  }).length;

  var preparingOrders = pedidos.filter(function (pedido) {
    return normalizeStatus(pedido.status) === 'em_preparo';
  }).length;

  var finishedOrders = pedidos.filter(function (pedido) {
    var status = normalizeStatus(pedido.status);
    return status === 'finalizado' || status === 'finalizados';
  }).length;

  var totalRevenue = pedidos.reduce(function (total, pedido) {
    return total + getOrderTotal(pedido);
  }, 0);

  totalOrdersElement.textContent = pedidos.length;
  receivedOrdersElement.textContent = receivedOrders;
  preparingOrdersElement.textContent = preparingOrders;
  finishedOrdersElement.textContent = finishedOrders;
  totalRevenueElement.textContent = formatPrice(totalRevenue);
}

function sortOrdersByDate(orders) {
  return orders.slice().sort(function (firstOrder, secondOrder) {
    return getOrderTime(secondOrder) - getOrderTime(firstOrder);
  });
}

function createRecentOrderElement(order) {
  var orderElement = document.createElement('article');
  var orderTop = document.createElement('div');
  var orderCode = document.createElement('strong');
  var orderDate = document.createElement('span');
  var customerName = document.createElement('p');
  var orderDetails = document.createElement('p');
  var orderStatus = document.createElement('span');

  orderElement.className = 'admin-recent-order';
  orderTop.className = 'admin-recent-order-top';
  orderCode.className = 'admin-recent-order-code';
  orderDate.className = 'admin-recent-order-date';
  customerName.className = 'admin-recent-order-customer';
  orderDetails.className = 'admin-recent-order-details';
  orderStatus.className = 'admin-recent-order-status admin-status-' + normalizeStatus(order.status);

  orderCode.textContent = formatOrderCode(order.codigo);
  orderDate.textContent = formatDateTime(order.dataHora);
  customerName.textContent = order.cliente && order.cliente.nome ? order.cliente.nome : 'Cliente não informado';
  orderDetails.textContent = formatDeliveryType(order.tipoEntrega) + ' • ' + formatPrice(getOrderTotal(order));
  orderStatus.textContent = 'Status: ' + formatStatus(order.status);

  orderTop.appendChild(orderCode);
  orderTop.appendChild(orderDate);
  orderElement.appendChild(orderTop);
  orderElement.appendChild(customerName);
  orderElement.appendChild(orderDetails);
  orderElement.appendChild(orderStatus);

  return orderElement;
}

function renderRecentOrders() {
  recentOrdersList.innerHTML = '';

  if (pedidos.length === 0) {
    recentOrdersList.hidden = true;
    emptyOrdersElement.hidden = false;
    return;
  }

  recentOrdersList.hidden = false;
  emptyOrdersElement.hidden = true;

  sortOrdersByDate(pedidos).slice(0, 5).forEach(function (pedido) {
    recentOrdersList.appendChild(createRecentOrderElement(pedido));
  });
}

function showLoadError() {
  recentOrdersList.hidden = true;
  emptyOrdersElement.hidden = false;
  emptyOrdersElement.querySelector('.admin-empty-title').textContent = 'Não foi possível carregar os pedidos.';
  emptyOrdersElement.querySelector('.admin-empty-text').textContent = 'Verifique se o backend está rodando e tente novamente.';
}

async function loadDashboardOrders() {
  try {
    pedidos = await fetchAdminOrders();
    renderMetrics();
    renderRecentOrders();
  } catch (error) {
    showLoadError();
  }
}

function setupNavigation() {
  logoutButton.addEventListener('click', function () {
    clearAdminSession();
    window.location.href = './admin-login.html';
  });

  menuButton.addEventListener('click', function () {
    window.location.href = './index.html';
  });

  ordersLink.addEventListener('click', function () {
    window.location.href = './admin-pedidos.html';
  });

  productsLink.addEventListener('click', function () {
    window.location.href = './admin-produtos.html';
  });

  kitchenLink.addEventListener('click', function () {
    window.location.href = './admin-cozinha.html';
  });
}

setupNavigation();
loadDashboardOrders();
