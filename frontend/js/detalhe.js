var quantityValueElement = document.getElementById('quantity-value');
var decreaseButton = document.querySelector('[data-action="decrease"]');
var increaseButton = document.querySelector('[data-action="increase"]');
var detailBackButton = document.getElementById('detail-back-button');
var detailAddButton = document.getElementById('detail-add-button');
var detailTitleElement = document.querySelector('.detail-title');
var detailImageElement = document.querySelector('.detail-image');
var productNameElement = document.querySelector('.detail-product-name');
var productPriceElement = document.querySelector('.detail-product-price');
var productDescriptionElement = document.querySelector('.detail-description-text');
var selectedProduct = JSON.parse(localStorage.getItem('produtoSelecionado'));
var quantity = 1;
var unitPrice = getProductPrice();

function updateQuantity() {
  quantityValueElement.textContent = quantity;
}

function updateDisplayedPrice() {
  productPriceElement.textContent = getFormattedPrice(unitPrice * quantity);
}

function getProductPrice() {
  var priceText = productPriceElement.textContent;
  return Number(priceText.replace('R$', '').replace(/\s/g, '').replace('.', '').replace(',', '.'));
}

function saveProductToCart() {
  if (!selectedProduct) {
    return;
  }

  var cart = JSON.parse(localStorage.getItem('carrinho')) || [];
  var product = {
    id: selectedProduct ? selectedProduct.id : null,
    nome: productNameElement.textContent,
    preco: unitPrice,
    quantidade: quantity,
    imagem: selectedProduct ? selectedProduct.imagem : ''
  };
  var existingProduct = cart.find(function (item) {
    if (item.id && product.id) {
      return item.id === product.id;
    }

    return item.nome === product.nome;
  });

  if (existingProduct) {
    existingProduct.quantidade += product.quantidade;
  } else {
    cart.push(product);
  }

  localStorage.setItem('carrinho', JSON.stringify(cart));
}

function loadSelectedProduct() {
  if (!selectedProduct) {
    productNameElement.textContent = 'Produto não encontrado';
    productDescriptionElement.textContent =
      'Volte ao cardápio e escolha um produto para ver os detalhes.';
    detailImageElement.removeAttribute('src');
    detailImageElement.alt = 'Produto não encontrado';
    detailImageElement.classList.add('detail-image--loading');
    detailAddButton.disabled = true;
    unitPrice = 0;
    updateDisplayedPrice();
    return;
  }

  detailTitleElement.textContent = selectedProduct.nome;
  detailImageElement.classList.add('detail-image--loading');
  detailImageElement.onload = function () {
    detailImageElement.classList.remove('detail-image--loading');
  };
  detailImageElement.src = selectedProduct.imagem;
  detailImageElement.alt = selectedProduct.nome;
  detailImageElement.classList.toggle(
    'detail-image--contain',
    selectedProduct.categoria === 'bebida'
  );
  productNameElement.textContent = selectedProduct.nome;
  unitPrice = selectedProduct.preco;
  updateDisplayedPrice();
  productDescriptionElement.textContent = selectedProduct.descricao;
}

function getFormattedPrice(price) {
  return 'R$ ' + price.toFixed(2).replace('.', ',');
}

increaseButton.addEventListener('click', function () {
  quantity += 1;
  updateQuantity();
  updateDisplayedPrice();
});

decreaseButton.addEventListener('click', function () {
  if (quantity > 1) {
    quantity -= 1;
    updateQuantity();
    updateDisplayedPrice();
  }
});

detailBackButton.addEventListener('click', function () {
  window.location.href = './index.html';
});

detailAddButton.addEventListener('click', function () {
  saveProductToCart();
  window.location.href = './carrinho.html';
});

loadSelectedProduct();
