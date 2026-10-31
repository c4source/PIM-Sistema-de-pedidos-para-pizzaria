if (!requireAdminSession()) {
  throw new Error('Sessao admin ausente.');
}

initializeKitchenQueue();

function initializeKitchenQueue() {
  var backDashboardButton = document.getElementById('admin-kitchen-back-dashboard');
  var ordersLinkButton = document.getElementById('admin-kitchen-orders-link');
  var logoutButton = document.getElementById('admin-kitchen-logout');
  var receivedCountElement = document.getElementById('kitchen-received-count');
  var preparingCountElement = document.getElementById('kitchen-preparing-count');
  var readyCountElement = document.getElementById('kitchen-ready-count');
  var totalCountElement = document.getElementById('kitchen-total-count');
  var receivedListElement = document.getElementById('kitchen-received-list');
  var preparingListElement = document.getElementById('kitchen-preparing-list');
  var readyListElement = document.getElementById('kitchen-ready-list');
  var pedidos = [];

  function normalizeStatus(status) {
    return String(status || '')
      .toLowerCase()
      .replace(/\s+/g, '_');
  }

  function formatPrice(value) {
    return 'R$ ' + (Number(value) || 0).toFixed(2).replace('.', ',');
  }

  function formatStatus(status) {
    var normalizedStatus = normalizeStatus(status);

    if (normalizedStatus === 'recebido') return 'Recebido';
    if (normalizedStatus === 'em_preparo') return 'Em preparo';
    if (normalizedStatus === 'pronto') return 'Pronto';

    return status || 'Sem status';
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

  function getOrdersByStatus(status) {
    return pedidos
      .filter(function (pedido) {
        return normalizeStatus(pedido.status) === status;
      })
      .sort(function (firstOrder, secondOrder) {
        return getOrderTime(firstOrder) - getOrderTime(secondOrder);
      });
  }

  function getQueueOrders() {
    return pedidos.filter(function (pedido) {
      var status = normalizeStatus(pedido.status);
      return status === 'recebido' || status === 'em_preparo' || status === 'pronto';
    });
  }

  function createInfoRow(label, value) {
    var row = document.createElement('p');
    var strong = document.createElement('strong');
    var span = document.createElement('span');

    row.className = 'admin-kitchen-info-row';
    strong.textContent = label + ': ';
    span.textContent = value;

    row.appendChild(strong);
    row.appendChild(span);

    return row;
  }

  function createAddressText(endereco) {
    if (!endereco) {
      return 'Endereço não informado';
    }

    return endereco.rua + ', nº ' + endereco.numero + ' - ' + endereco.bairro;
  }

  function createItemsList(items) {
    var list = document.createElement('ul');

    list.className = 'admin-kitchen-order-items';

    if (!items || items.length === 0) {
      var emptyItem = document.createElement('li');
      emptyItem.textContent = 'Nenhum item informado';
      list.appendChild(emptyItem);
      return list;
    }

    items.forEach(function (item) {
      var listItem = document.createElement('li');
      var quantity = Number(item.quantidade) || 0;
      listItem.textContent = item.nome + ' x' + quantity;
      list.appendChild(listItem);
    });

    return list;
  }

  function getObservation(order) {
    return order.observacao || order.observacoes || order.observacaoPedido || '';
  }

  function canAdvanceStatus(currentStatus, nextStatus) {
    var status = normalizeStatus(currentStatus);

    return (
      (status === 'recebido' && nextStatus === 'em_preparo') ||
      (status === 'em_preparo' && nextStatus === 'pronto')
    );
  }

  async function updateOrderStatus(orderCode, nextStatus) {
    var order = pedidos.find(function (pedido) {
      return pedido.codigo === orderCode;
    });

    if (!order || !canAdvanceStatus(order.status, nextStatus)) {
      return;
    }

    try {
      await updateAdminOrderStatus(order.id, nextStatus);
      pedidos = await fetchAdminOrders();
      renderKitchen();
    } catch (error) {
      alert('Não foi possível atualizar o status do pedido.');
    }
  }

  function createActionButton(label, nextStatus, orderCode) {
    var button = document.createElement('button');

    button.type = 'button';
    button.className = 'admin-kitchen-action-button';
    button.textContent = label;
    button.addEventListener('click', function () {
      updateOrderStatus(orderCode, nextStatus);
    });

    return button;
  }

  function createOrderActions(order) {
    var actions = document.createElement('div');
    var status = normalizeStatus(order.status);

    actions.className = 'admin-kitchen-actions';

    if (status === 'recebido') {
      actions.appendChild(createActionButton('Iniciar preparo', 'em_preparo', order.codigo));
      return actions;
    }

    if (status === 'em_preparo') {
      actions.appendChild(createActionButton('Marcar como pronto', 'pronto', order.codigo));
      return actions;
    }

    var readyBadge = document.createElement('p');
    readyBadge.className = 'admin-kitchen-ready-note';
    readyBadge.textContent = 'Pedido pronto';
    actions.appendChild(readyBadge);

    return actions;
  }

  function createKitchenOrderCard(order) {
    var card = document.createElement('article');
    var top = document.createElement('div');
    var codeGroup = document.createElement('div');
    var shortCode = document.createElement('strong');
    var statusBadge = document.createElement('span');
    var details = document.createElement('div');
    var itemsTitle = document.createElement('h3');
    var observation = getObservation(order);

    card.className = 'admin-kitchen-order-card';
    top.className = 'admin-kitchen-order-top';
    codeGroup.className = 'admin-kitchen-code-group';
    shortCode.className = 'admin-kitchen-order-code';
    statusBadge.className =
      'admin-kitchen-status-badge admin-kitchen-status-' + normalizeStatus(order.status);
    details.className = 'admin-kitchen-details';
    itemsTitle.className = 'admin-kitchen-items-title';

    shortCode.textContent = 'Pedido ' + formatOrderCode(order.codigo);
    statusBadge.textContent = formatStatus(order.status);
    itemsTitle.textContent = 'Itens';

    codeGroup.appendChild(shortCode);
    top.appendChild(codeGroup);
    top.appendChild(statusBadge);

    details.appendChild(
      createInfoRow(
        'Cliente',
        order.cliente && order.cliente.nome ? order.cliente.nome : 'Cliente não informado'
      )
    );
    details.appendChild(createInfoRow('Tipo', formatDeliveryType(order.tipoEntrega)));
    details.appendChild(createInfoRow('Horário', formatDateTime(order.dataHora)));
    details.appendChild(createInfoRow('Total', formatPrice(order.total)));

    if (order.tipoEntrega === 'entrega') {
      details.appendChild(createInfoRow('Endereço', createAddressText(order.endereco)));
    }

    if (observation) {
      details.appendChild(createInfoRow('Observação', observation));
    }

    card.appendChild(top);
    card.appendChild(details);
    card.appendChild(itemsTitle);
    card.appendChild(createItemsList(order.itens));
    card.appendChild(createOrderActions(order));

    return card;
  }

  function createEmptyState(message) {
    var emptyState = document.createElement('p');

    emptyState.className = 'admin-kitchen-empty-state';
    emptyState.textContent = message;

    return emptyState;
  }

  function renderColumn(listElement, orders, emptyMessage) {
    listElement.innerHTML = '';

    if (orders.length === 0) {
      listElement.appendChild(createEmptyState(emptyMessage));
      return;
    }

    orders.forEach(function (order) {
      listElement.appendChild(createKitchenOrderCard(order));
    });
  }

  function updateSummary() {
    var receivedOrders = getOrdersByStatus('recebido');
    var preparingOrders = getOrdersByStatus('em_preparo');
    var readyOrders = getOrdersByStatus('pronto');

    receivedCountElement.textContent = receivedOrders.length;
    preparingCountElement.textContent = preparingOrders.length;
    readyCountElement.textContent = readyOrders.length;
    totalCountElement.textContent = getQueueOrders().length;
  }

  function renderKitchen() {
    renderColumn(receivedListElement, getOrdersByStatus('recebido'), 'Nenhum pedido recebido.');
    renderColumn(
      preparingListElement,
      getOrdersByStatus('em_preparo'),
      'Nenhum pedido em preparo.'
    );
    renderColumn(readyListElement, getOrdersByStatus('pronto'), 'Nenhum pedido pronto.');
    updateSummary();
  }

  function showLoadError() {
    renderColumn(receivedListElement, [], 'Não foi possível carregar os pedidos.');
    renderColumn(preparingListElement, [], 'Verifique se o backend está rodando.');
    renderColumn(readyListElement, [], 'Tente novamente em instantes.');
  }

  async function loadKitchenOrders() {
    try {
      pedidos = await fetchAdminOrders();
      renderKitchen();
    } catch (error) {
      showLoadError();
    }
  }

  backDashboardButton.addEventListener('click', function () {
    window.location.href = './admin-dashboard.html';
  });

  ordersLinkButton.addEventListener('click', function () {
    window.location.href = './admin-pedidos.html';
  });

  logoutButton.addEventListener('click', function () {
    clearAdminSession();
    window.location.href = './admin-login.html';
  });

  loadKitchenOrders();
}
