if (!requireAdminSession()) {
  throw new Error('Sessao admin ausente.');
}

var ordersBackDashboardButton = document.getElementById('admin-orders-back-dashboard');
var ordersLogoutButton = document.getElementById('admin-orders-logout');
var ordersListElement = document.getElementById('admin-orders-list');
var ordersEmptyElement = document.getElementById('admin-orders-empty');
var filterButtons = document.querySelectorAll('.admin-orders-filter-chip');
var pedidos = [];
var currentFilter = 'todos';

function formatPrice(value) {
  return 'R$ ' + (Number(value) || 0).toFixed(2).replace('.', ',');
}

function normalizeStatus(status) {
  return String(status || '')
    .toLowerCase()
    .replace(/\s+/g, '_');
}

function formatStatus(status) {
  var normalizedStatus = normalizeStatus(status);

  if (normalizedStatus === 'recebido') return 'Recebido';
  if (normalizedStatus === 'em_preparo') return 'Em preparo';
  if (normalizedStatus === 'pronto') return 'Pronto';
  if (normalizedStatus === 'finalizado') return 'Finalizado';
  if (normalizedStatus === 'cancelado') return 'Cancelado';

  return status || 'Sem status';
}

function formatPaymentMethod(method) {
  if (method === 'dinheiro') return 'Dinheiro';
  if (method === 'cartao') return 'Cartão';
  if (method === 'pix') return 'Pix';

  return 'Não informado';
}

function formatPaymentStatus(status) {
  if (status === 'pendente') return 'Pendente';
  if (status === 'pago') return 'Pago';
  if (status === 'cancelado') return 'Cancelado';

  return 'Não informado';
}

function formatDeliveryType(tipoEntrega) {
  return tipoEntrega === 'entrega' ? 'Entrega' : 'Retirada';
}

function formatOrderCode(codigo) {
  return (
    '#' +
    String(codigo || '000000')
      .replace('PED-', '')
      .slice(-6)
  );
}

function formatPhone(phone) {
  var digits = String(phone || '').replace(/\D/g, '');

  if (digits.length === 11) {
    return '(' + digits.slice(0, 2) + ') ' + digits.slice(2, 7) + '-' + digits.slice(7);
  }

  if (digits.length === 10) {
    return '(' + digits.slice(0, 2) + ') ' + digits.slice(2, 6) + '-' + digits.slice(6);
  }

  return phone || 'Telefone não informado';
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

function getOrderTime(order) {
  var time = new Date(order.dataHora).getTime();
  return isNaN(time) ? 0 : time;
}

function getSortedOrders() {
  return pedidos.slice().sort(function (firstOrder, secondOrder) {
    return getOrderTime(secondOrder) - getOrderTime(firstOrder);
  });
}

function getFilteredOrders() {
  if (currentFilter === 'todos') {
    return getSortedOrders();
  }

  return getSortedOrders().filter(function (pedido) {
    return normalizeStatus(pedido.status) === currentFilter;
  });
}

function canUpdateStatus(currentStatus, nextStatus) {
  var status = normalizeStatus(currentStatus);

  return (
    (status === 'recebido' && (nextStatus === 'em_preparo' || nextStatus === 'cancelado')) ||
    (status === 'em_preparo' && nextStatus === 'pronto') ||
    (status === 'pronto' && nextStatus === 'finalizado')
  );
}

async function updateOrderStatus(orderCode, nextStatus) {
  var order = pedidos.find(function (pedido) {
    return pedido.codigo === orderCode;
  });

  if (!order || !canUpdateStatus(order.status, nextStatus)) {
    return;
  }

  try {
    await updateAdminOrderStatus(order.id, nextStatus);
    pedidos = await fetchAdminOrders();
    renderOrders();
  } catch (error) {
    alert('Não foi possível atualizar o status do pedido.');
  }
}

function createInfoRow(label, value) {
  var row = document.createElement('p');
  var strong = document.createElement('strong');
  var span = document.createElement('span');

  row.className = 'admin-order-info-row';
  strong.textContent = label + ': ';
  span.textContent = value;

  row.appendChild(strong);
  row.appendChild(span);

  return row;
}

function createItemsList(items) {
  var list = document.createElement('ul');

  list.className = 'admin-order-items-list';

  if (!items || items.length === 0) {
    var emptyItem = document.createElement('li');
    emptyItem.textContent = 'Nenhum item informado';
    list.appendChild(emptyItem);
    return list;
  }

  items.forEach(function (item) {
    var listItem = document.createElement('li');
    listItem.textContent = '- ' + item.nome + ' x' + item.quantidade;
    list.appendChild(listItem);
  });

  return list;
}

function createAddressText(endereco) {
  if (!endereco) {
    return 'Endereço não informado';
  }

  return endereco.rua + ', nº ' + endereco.numero + ' - ' + endereco.bairro;
}

function createStatusActions(order) {
  var actions = document.createElement('div');
  var status = normalizeStatus(order.status);

  actions.className = 'admin-order-actions';

  if (status === 'recebido') {
    actions.appendChild(createStatusButton('Iniciar preparo', 'em_preparo', order.codigo, true));
    actions.appendChild(createStatusButton('Cancelar', 'cancelado', order.codigo, false));
    return actions;
  }

  if (status === 'em_preparo') {
    actions.appendChild(createStatusButton('Marcar como pronto', 'pronto', order.codigo, true));
    return actions;
  }

  if (status === 'pronto') {
    actions.appendChild(createStatusButton('Finalizar pedido', 'finalizado', order.codigo, true));
    return actions;
  }

  var readOnlyText = document.createElement('p');
  readOnlyText.className = 'admin-order-readonly-note';
  readOnlyText.textContent = status === 'cancelado' ? 'Pedido cancelado' : 'Pedido finalizado';
  actions.appendChild(readOnlyText);

  return actions;
}

function createStatusButton(label, nextStatus, orderCode, isPrimary) {
  var button = document.createElement('button');

  button.type = 'button';
  button.className = isPrimary
    ? 'admin-order-action-button admin-order-action-primary'
    : 'admin-order-action-button admin-order-action-secondary';
  button.textContent = label;

  button.addEventListener('click', function () {
    updateOrderStatus(orderCode, nextStatus);
  });

  return button;
}

function createOrderCard(order) {
  var card = document.createElement('article');
  var top = document.createElement('div');
  var codeGroup = document.createElement('div');
  var shortCode = document.createElement('strong');
  var fullCode = document.createElement('span');
  var statusBadge = document.createElement('span');
  var details = document.createElement('div');
  var itemsTitle = document.createElement('h3');

  card.className = 'admin-order-card';
  top.className = 'admin-order-card-top';
  codeGroup.className = 'admin-order-code-group';
  shortCode.className = 'admin-order-short-code';
  fullCode.className = 'admin-order-full-code';
  statusBadge.className = 'admin-order-status-badge admin-status-' + normalizeStatus(order.status);
  details.className = 'admin-order-details-grid';
  itemsTitle.className = 'admin-order-items-title';

  shortCode.textContent = 'Pedido ' + formatOrderCode(order.codigo);
  fullCode.textContent = 'Código completo: ' + (order.codigo || 'Não informado');
  statusBadge.textContent = formatStatus(order.status);
  itemsTitle.textContent = 'Itens';

  codeGroup.appendChild(shortCode);
  codeGroup.appendChild(fullCode);
  top.appendChild(codeGroup);
  top.appendChild(statusBadge);

  details.appendChild(
    createInfoRow(
      'Cliente',
      order.cliente && order.cliente.nome ? order.cliente.nome : 'Cliente não informado'
    )
  );
  details.appendChild(
    createInfoRow(
      'Telefone',
      order.cliente ? formatPhone(order.cliente.telefone) : 'Telefone não informado'
    )
  );
  details.appendChild(createInfoRow('Tipo', formatDeliveryType(order.tipoEntrega)));
  details.appendChild(createInfoRow('Total', formatPrice(order.total)));
  details.appendChild(createInfoRow('Data/hora', formatDateTime(order.dataHora)));
  details.appendChild(
    createInfoRow(
      'Pagamento',
      formatPaymentMethod(order.pagamento && order.pagamento.formaPagamento)
    )
  );
  details.appendChild(
    createInfoRow(
      'Status do pagamento',
      formatPaymentStatus(order.pagamento && order.pagamento.statusPagamento)
    )
  );

  if (order.tipoEntrega === 'entrega') {
    details.appendChild(createInfoRow('Endereço', createAddressText(order.endereco)));
  }

  card.appendChild(top);
  card.appendChild(details);
  card.appendChild(itemsTitle);
  card.appendChild(createItemsList(order.itens));
  card.appendChild(createStatusActions(order));

  return card;
}

function updateEmptyState(filteredOrders) {
  if (filteredOrders.length > 0) {
    ordersListElement.hidden = false;
    ordersEmptyElement.hidden = true;
    return;
  }

  ordersListElement.hidden = true;
  ordersEmptyElement.hidden = false;

  if (pedidos.length === 0) {
    ordersEmptyElement.querySelector('.admin-orders-empty-title').textContent =
      'Nenhum pedido encontrado.';
    ordersEmptyElement.querySelector('.admin-orders-empty-text').textContent =
      'Quando um cliente finalizar um pedido, ele aparecerá aqui.';
  } else {
    ordersEmptyElement.querySelector('.admin-orders-empty-title').textContent =
      'Nenhum pedido encontrado para este filtro.';
    ordersEmptyElement.querySelector('.admin-orders-empty-text').textContent = '';
  }
}

function renderOrders() {
  var filteredOrders = getFilteredOrders();

  ordersListElement.innerHTML = '';
  updateEmptyState(filteredOrders);

  filteredOrders.forEach(function (pedido) {
    ordersListElement.appendChild(createOrderCard(pedido));
  });
}

function setActiveFilter(selectedButton) {
  filterButtons.forEach(function (button) {
    button.classList.remove('is-active');
  });

  selectedButton.classList.add('is-active');
  currentFilter = selectedButton.dataset.status;
  renderOrders();
}

function showLoadError() {
  ordersListElement.hidden = true;
  ordersEmptyElement.hidden = false;
  ordersEmptyElement.querySelector('.admin-orders-empty-title').textContent =
    'Não foi possível carregar os pedidos.';
  ordersEmptyElement.querySelector('.admin-orders-empty-text').textContent =
    'Verifique se o backend está rodando e tente novamente.';
}

async function loadOrdersFromApi() {
  try {
    pedidos = await fetchAdminOrders();
    renderOrders();
  } catch (error) {
    showLoadError();
  }
}

filterButtons.forEach(function (button) {
  button.addEventListener('click', function () {
    setActiveFilter(button);
  });
});

ordersBackDashboardButton.addEventListener('click', function () {
  window.location.href = './admin-dashboard.html';
});

ordersLogoutButton.addEventListener('click', function () {
  clearAdminSession();
  window.location.href = './admin-login.html';
});

loadOrdersFromApi();
