var confirmationBackButton = document.getElementById('confirmation-back-button');
var confirmationHomeButton = document.getElementById('confirmation-home-button');
var confirmationOrderCode = document.getElementById('confirmation-order-code');
var confirmationOrderStatus = document.getElementById('confirmation-order-status');
var confirmationOrderType = document.getElementById('confirmation-order-type');
var confirmationOrderTime = document.getElementById('confirmation-order-time');
var confirmationPaymentMethod = document.getElementById('confirmation-payment-method');
var confirmationPaymentStatus = document.getElementById('confirmation-payment-status');
var confirmationSummaryList = document.querySelector('.confirmation-summary-list');
var confirmationTotalElement = document.querySelector('.confirmation-total');
var pedidoAtual = JSON.parse(localStorage.getItem('pedidoAtual'));

if (!pedidoAtual) {
  window.location.href = './index.html';
}

function formatPrice(value) {
  return 'R$ ' + value.toFixed(2).replace('.', ',');
}

function formatStatus(status) {
  if (!status) {
    return 'Recebido';
  }

  return status.charAt(0).toUpperCase() + status.slice(1);
}

function formatPaymentMethod(method) {
  if (method === 'dinheiro') {
    return 'Dinheiro';
  }

  if (method === 'cartao') {
    return 'Cartão';
  }

  if (method === 'pix') {
    return 'Pix';
  }

  return 'Não informado';
}

function formatPaymentStatus(status) {
  if (status === 'pendente') {
    return 'Pendente';
  }

  if (status === 'pago') {
    return 'Pago';
  }

  if (status === 'cancelado') {
    return 'Cancelado';
  }

  return 'Não informado';
}

function renderConfirmationSummary() {
  var tipoEntregaLabel = pedidoAtual.tipoEntrega === 'entrega' ? 'Entrega' : 'Retirada';
  var codigoCurto = pedidoAtual.codigo.replace('PED-', '').slice(-6);

  confirmationOrderCode.textContent = '#' + codigoCurto;
  confirmationOrderStatus.textContent = formatStatus(pedidoAtual.status);
  confirmationOrderType.textContent = tipoEntregaLabel;
  confirmationPaymentMethod.textContent = formatPaymentMethod(
    pedidoAtual.pagamento && pedidoAtual.pagamento.formaPagamento
  );
  confirmationPaymentStatus.textContent = formatPaymentStatus(
    pedidoAtual.pagamento && pedidoAtual.pagamento.statusPagamento
  );
  confirmationOrderTime.textContent = '30-45 min';
  confirmationSummaryList.innerHTML = '';

  if (!pedidoAtual.itens || pedidoAtual.itens.length === 0) {
    confirmationSummaryList.innerHTML =
      '<li class="confirmation-summary-item"><span>Nenhum item no pedido</span><strong>x0</strong></li>';
    confirmationTotalElement.innerHTML = '<span>Total do pedido</span><strong>R$ 0,00</strong>';
    return;
  }

  pedidoAtual.itens.forEach(function (item) {
    var listItem = document.createElement('li');
    var itemName = document.createElement('span');
    var itemQuantity = document.createElement('strong');

    listItem.className = 'confirmation-summary-item';
    itemName.textContent = item.nome;
    itemQuantity.textContent = 'x' + item.quantidade;

    listItem.appendChild(itemName);
    listItem.appendChild(itemQuantity);
    confirmationSummaryList.appendChild(listItem);
  });

  confirmationTotalElement.innerHTML =
    '<span>Total do pedido</span><strong>' + formatPrice(pedidoAtual.total) + '</strong>';
}

if (pedidoAtual) {
  renderConfirmationSummary();
  localStorage.removeItem('carrinho');
}

confirmationBackButton.addEventListener('click', function () {
  window.location.href = './checkout.html';
});

confirmationHomeButton.addEventListener('click', function () {
  localStorage.removeItem('carrinho');
  localStorage.removeItem('pedidoAtual');
  window.location.href = './index.html';
});
