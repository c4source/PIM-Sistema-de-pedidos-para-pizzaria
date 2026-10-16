if (requireAdminSession()) {
  initializeAdminProducts();
}

function initializeAdminProducts() {
  var allowedCategories = ['pizza', 'doce', 'bebida', 'combo'];
  var productsTotalElement = document.getElementById('admin-products-total');
  var productsAvailableElement = document.getElementById('admin-products-available');
  var productsUnavailableElement = document.getElementById('admin-products-unavailable');
  var productsStockTotalElement = document.getElementById('admin-products-stock-total');
  var productsBackDashboardButton = document.getElementById('admin-products-back-dashboard');
  var productsLogoutButton = document.getElementById('admin-products-logout');
  var productModal = document.getElementById('produto-form-modal');
  var createProductButton = document.getElementById('criar-produto');
  var productsForm = document.getElementById('admin-products-form');
  var productFormTitle = document.getElementById('product-form-title');
  var productIdInput = document.getElementById('product-id');
  var productNameInput = document.getElementById('product-name');
  var productCategoryInput = document.getElementById('product-category');
  var productPriceInput = document.getElementById('product-price');
  var productDescriptionInput = document.getElementById('product-description');
  var productImageInput = document.getElementById('product-image');
  var productStockInput = document.getElementById('product-stock');
  var productKitInput = document.getElementById('product-is-kit');
  var kitList = document.getElementById('kit-components-list');
  function atualizarTipoKit() {
    document.getElementById('kit-components-panel').hidden = !productKitInput.checked;
    productStockInput.disabled = productKitInput.checked;
    document.querySelector('label[for="product-stock"] .admin-products-label').textContent = productKitInput.checked ? 'Kits possíveis' : 'Estoque';
    if (productKitInput.checked) calcularKitsPossiveis();
  }
  function calcularKitsPossiveis() {
    if (!productKitInput.checked) return;
    var quantidades = new Map();
    var valido = kitList.children.length > 0;
    Array.from(kitList.children).forEach(function(row){
      var id = Number(row.querySelector('select').value);
      var quantidade = Number(row.querySelector('input').value);
      if (!id || !Number.isInteger(quantidade) || quantidade <= 0) { valido = false; return; }
      quantidades.set(id, (quantidades.get(id) || 0) + quantidade);
    });
    var possiveis = Infinity;
    quantidades.forEach(function(quantidade, id){
      var produto = produtos.find(function(p){return Number(p.id) === id;});
      if (!produto || produto.ehKit || produto.disponivel === false) { possiveis = 0; return; }
      possiveis = Math.min(possiveis, Math.floor(produto.estoque / quantidade));
    });
    productStockInput.value = valido && Number.isFinite(possiveis) ? possiveis : 0;
  }
  kitList.addEventListener('input', calcularKitsPossiveis);
  kitList.addEventListener('change', calcularKitsPossiveis);
  function adicionarComponente(comp) {
    var row = document.createElement('div'); row.className = 'kit-componente';
    var label = document.createElement('label'); label.textContent = 'Produto';
    var select = document.createElement('select'); select.className = 'admin-products-input';
    var placeholder = document.createElement('option'); placeholder.value = ''; placeholder.textContent = 'Selecione um produto'; select.appendChild(placeholder);
    produtos.filter(function(p){return !p.ehKit && Number(p.id)!==Number(productIdInput.value);}).forEach(function(p){var option=document.createElement('option');option.value=p.id;option.textContent=p.nome;select.appendChild(option);});
    select.value = comp ? comp.idProduto : '';
    var qtyLabel = document.createElement('label'); qtyLabel.textContent='Quantidade';
    var qty = document.createElement('input'); qty.type='number';qty.min='1';qty.step='1';qty.value=comp?comp.quantidade:1;qty.className='admin-products-input';
    var remove=document.createElement('button');remove.type='button';remove.textContent='×';remove.title='Remover componente';remove.setAttribute('aria-label','Remover componente');remove.addEventListener('click',function(){row.remove();calcularKitsPossiveis();});
    label.appendChild(select);qtyLabel.appendChild(qty);row.append(label,qtyLabel,remove);kitList.appendChild(row);calcularKitsPossiveis();
  }
  productKitInput.addEventListener('change',function(){atualizarTipoKit();if(productKitInput.checked && !kitList.children.length)adicionarComponente();});
  document.getElementById('kit-add-component').addEventListener('click',function(){adicionarComponente();});
  var productAvailableInput = document.getElementById('product-available');
  var productSubmitButton = document.getElementById('product-submit-button');
  var productCancelEditButton = document.getElementById('product-cancel-edit-button');
  var productFormError = document.getElementById('product-form-error');
  var productsListElement = document.getElementById('admin-products-list');
  var productsEmptyElement = document.getElementById('admin-products-empty');
  var categoryFilterButtons = document.querySelectorAll('[data-category]');
  var statusFilterButtons = document.querySelectorAll('[data-status]');
  var selectedCategory = 'todos';
  var selectedStatus = 'todos';
  var produtos = [];

  function loadLocalProducts() {
    try {
      return normalizeProducts(JSON.parse(localStorage.getItem('produtos')) || []);
    } catch (error) {
      return [];
    }
  }

  function normalizeProducts(productsList) {
    if (!Array.isArray(productsList)) {
      return [];
    }

    return productsList.map(function (product) {
      return {
        id: product.id || product.codprod,
        ehKit: Boolean(product.ehKit),
        componentes: product.componentes || [],
        nome: product.nome || product.nome_produto || '',
        categoria: product.categoria || '',
        preco: Number(product.preco) || 0,
        imagem: product.imagem || product.imagemUrl || product.imagem_url || '',
        descricao: product.descricao || '',
        estoque: Number.isInteger(Number(product.estoque)) && Number(product.estoque) >= 0 ? Number(product.estoque) : 0,
        disponivel: normalizeAvailability(product)
      };
    });
  }

  function normalizeAvailability(product) {
    var status = String(product.status || product.status_disponibilidade || '').toLowerCase();

    if (product.disponivel === false || status === 'false' || status === 'indisponivel' || status === 'indisponível') {
      return false;
    }

    return true;
  }

  function formatPrice(value) {
    return 'R$ ' + (Number(value) || 0).toFixed(2).replace('.', ',');
  }

  function formatCategory(category) {
    var categoryMap = {
      pizza: 'Pizza',
      doce: 'Doce',
      bebida: 'Bebida',
      combo: 'Combo'
    };

    return categoryMap[category] || 'Sem categoria';
  }

  function formatAvailability(product) {
    return product.disponivel === false ? 'Indisponível' : 'Disponível';
  }

  function getFormData() {
    return {
      ehKit: productKitInput.checked,
      componentes: productKitInput.checked ? Array.from(kitList.children).map(function(row){return {idProduto:Number(row.querySelector("select").value),quantidade:Number(row.querySelector("input").value)};}) : [],
      id: productIdInput.value,
      nome: productNameInput.value.trim(),
      categoria: productCategoryInput.value,
      preco: Number(String(productPriceInput.value).replace(',', '.')),
      imagem: productImageInput.value.trim(),
      descricao: productDescriptionInput.value.trim(),
      estoque: Number(productStockInput.value),
      disponivel: productAvailableInput.value === 'true'
    };
  }

  function showFormError(message) {
    productFormError.textContent = message;
  }

  function clearFormError() {
    productFormError.textContent = '';
  }

  function validateProduct(productData) {
    if(productData.ehKit && (!productData.componentes.length || productData.componentes.some(function(c){return !c.idProduto || !Number.isInteger(c.quantidade) || c.quantidade<=0;}) || new Set(productData.componentes.map(function(c){return c.idProduto;})).size!==productData.componentes.length)) return 'Selecione produtos diferentes e quantidades inteiras maiores que zero para o kit.';
    if (productData.nome.length < 3) {
      return 'Informe um nome válido.';
    }

    if (allowedCategories.indexOf(productData.categoria) === -1) {
      return 'Selecione uma categoria válida.';
    }

    if (!productData.preco || productData.preco <= 0) {
      return 'Informe um preço válido.';
    }

    if (productData.descricao.length < 5) {
      return 'Informe uma descrição válida.';
    }

    if (!productData.imagem) {
      return 'Informe a imagem do produto.';
    }

    if (!Number.isInteger(productData.estoque) || productData.estoque < 0) {
      return 'Informe um estoque válido.';
    }

    if (productAvailableInput.value !== 'true' && productAvailableInput.value !== 'false') {
      return 'Selecione uma disponibilidade válida.';
    }

    return '';
  }

  function resetForm() {
    productsForm.reset();
    kitList.replaceChildren();
    atualizarTipoKit();
    productIdInput.value = '';
    productAvailableInput.value = 'true';
    productFormTitle.textContent = 'Novo produto';
    productSubmitButton.textContent = 'Salvar produto';
    productSubmitButton.disabled = false;
    productCancelEditButton.hidden = false;
    clearFormError();
  }

  async function reloadProducts() {
    produtos = await fetchAdminProducts();
    renderPage();
  }

  async function handleCreateProduct(productData) {
    try {
      productSubmitButton.disabled = true;
      await createAdminProduct(productData);
      productModal.close();
      resetForm();
      await reloadProducts();
    } catch (error) {
      showFormError(error.message || 'Não foi possível cadastrar o produto.');
    } finally {
      productSubmitButton.disabled = false;
    }
  }

  async function handleEditProduct(productData) {
    var productId = Number(productData.id);
    var productExists = produtos.some(function (product) {
      return Number(product.id) === productId;
    });

    if (!productExists) {
      showFormError('Produto não encontrado.');
      return;
    }

    try {
      productSubmitButton.disabled = true;
      await updateAdminProduct(productId, productData);
      await reloadProducts();
      resetForm();
    } catch (error) {
      showFormError(error.message || 'Não foi possível salvar as alterações.');
    } finally {
      productSubmitButton.disabled = false;
    }
  }

  function editProduct(productId) {
    var product = produtos.find(function (item) {
      return Number(item.id) === Number(productId);
    });

    if (!product) {
      return;
    }

    productIdInput.value = product.id;
    productKitInput.checked = product.ehKit;
    kitList.replaceChildren();
    (product.componentes || []).forEach(adicionarComponente);
    productNameInput.value = product.nome;
    productCategoryInput.value = product.categoria;
    productPriceInput.value = product.preco;
    productDescriptionInput.value = product.descricao;
    productImageInput.value = product.imagem;
    productStockInput.value = product.estoque;
    productAvailableInput.value = product.disponivel === false ? 'false' : 'true';
    atualizarTipoKit();
    productFormTitle.textContent = 'Editar produto';
    productSubmitButton.textContent = 'Salvar alterações';
    productCancelEditButton.hidden = false;
    clearFormError();
    productModal.showModal();
    productNameInput.focus();
  }

  async function deleteProduct(productId) {
    var product = produtos.find(function (item) {
      return Number(item.id) === Number(productId);
    });

    if (!product) {
      return;
    }

    if (!window.confirm('Deseja excluir este produto?')) {
      return;
    }

    try {
      await deleteAdminProduct(product.id);
      await reloadProducts();
    } catch (error) {
      showFormError('Não foi possível excluir o produto.');
    }
  }

  function getFilteredProducts() {
    var filteredProducts = produtos.filter(function (product) {
      var matchesCategory = selectedCategory === 'todos' || product.categoria === selectedCategory;
      var matchesStatus = selectedStatus === 'todos' ||
        (selectedStatus === 'disponivel' && product.disponivel !== false) ||
        (selectedStatus === 'indisponivel' && product.disponivel === false);

      return matchesCategory && matchesStatus;
    });

    if (selectedStatus !== 'todos') {
      return filteredProducts;
    }

    return filteredProducts.slice().sort(function (firstProduct, secondProduct) {
      if (firstProduct.disponivel === false && secondProduct.disponivel !== false) {
        return 1;
      }

      if (firstProduct.disponivel !== false && secondProduct.disponivel === false) {
        return -1;
      }

      return 0;
    });
  }

  function updateSummary() {
    var availableProducts = produtos.filter(function (product) {
      return product.disponivel !== false;
    }).length;
    var unavailableProducts = produtos.filter(function (product) {
      return product.disponivel === false;
    }).length;
    var stockTotal = produtos.reduce(function (total, product) {
      return total + (product.ehKit ? 0 : Number(product.estoque) || 0);
    }, 0);

    productsTotalElement.textContent = produtos.length;
    productsAvailableElement.textContent = availableProducts;
    productsUnavailableElement.textContent = unavailableProducts;
    productsStockTotalElement.textContent = stockTotal;
  }

  function updateActiveFilters() {
    categoryFilterButtons.forEach(function (button) {
      button.classList.toggle('is-active', button.dataset.category === selectedCategory);
    });

    statusFilterButtons.forEach(function (button) {
      button.classList.toggle('is-active', button.dataset.status === selectedStatus);
    });
  }

  function createProductInfo(label, value) {
    var row = document.createElement('p');
    var strong = document.createElement('strong');
    var span = document.createElement('span');

    row.className = 'admin-product-info-row';
    strong.textContent = label + ': ';
    span.textContent = value;

    row.appendChild(strong);
    row.appendChild(span);

    return row;
  }

  function createProductCard(product) {
    var card = document.createElement('article');
    var image = document.createElement('img');
    var content = document.createElement('div');
    var top = document.createElement('div');
    var titleGroup = document.createElement('div');
    var title = document.createElement('h2');
    var status = document.createElement('span');
    var details = document.createElement('div');
    var description = document.createElement('p');
    var actions = document.createElement('div');
    var editButton = document.createElement('button');
    var deleteButton = document.createElement('button');

    card.className = product.disponivel === false ? 'admin-product-card is-unavailable' : 'admin-product-card is-available';
    image.className = 'admin-product-image';
    content.className = 'admin-product-content';
    top.className = 'admin-product-card-top';
    titleGroup.className = 'admin-product-title-group';
    title.className = 'admin-product-title';
    status.className = product.disponivel === false ? 'admin-product-status admin-product-status-unavailable is-unavailable' : 'admin-product-status admin-product-status-available is-available';
    details.className = 'admin-product-details';
    description.className = 'admin-product-description';
    actions.className = 'admin-product-actions';
    editButton.className = 'admin-product-action-button admin-product-action-secondary';
    deleteButton.className = 'admin-product-action-button admin-product-action-secondary';

    image.src = product.imagem;
    image.alt = product.nome;
    title.textContent = product.nome;
    status.textContent = formatAvailability(product);
    description.textContent = product.descricao;
    editButton.type = 'button';
    editButton.textContent = 'Editar';
    deleteButton.type = 'button';
    deleteButton.textContent = 'Excluir';

    editButton.addEventListener('click', function () {
      editProduct(product.id);
    });

    deleteButton.addEventListener('click', function () {
      deleteProduct(product.id);
    });

    titleGroup.appendChild(title);
    titleGroup.appendChild(status);
    top.appendChild(titleGroup);
    details.appendChild(createProductInfo('Categoria', formatCategory(product.categoria)));
    details.appendChild(createProductInfo('Preço', formatPrice(product.preco)));
    details.appendChild(createProductInfo(product.ehKit ? 'Kits possíveis' : 'Estoque', String(product.estoque)));
    details.appendChild(createProductInfo('Status', formatAvailability(product)));
    actions.appendChild(editButton);
    actions.appendChild(deleteButton);
    content.appendChild(top);
    content.appendChild(details);
    content.appendChild(description);
    content.appendChild(actions);
    card.appendChild(image);
    card.appendChild(content);

    return card;
  }

  function updateEmptyState(filteredProducts) {
    if (filteredProducts.length > 0) {
      productsListElement.hidden = false;
      productsEmptyElement.hidden = true;
      return;
    }

    productsListElement.hidden = true;
    productsEmptyElement.hidden = false;

    if (produtos.length === 0) {
      productsEmptyElement.querySelector('.admin-products-empty-title').textContent = 'Nenhum produto cadastrado.';
      productsEmptyElement.querySelector('.admin-products-empty-text').textContent = 'Clique em Criar produto para adicionar um produto ao cardápio.';
      return;
    }

    productsEmptyElement.querySelector('.admin-products-empty-title').textContent = 'Nenhum produto encontrado para este filtro.';
    productsEmptyElement.querySelector('.admin-products-empty-text').textContent = '';
  }

  function renderProducts() {
    var filteredProducts = getFilteredProducts();

    productsListElement.innerHTML = '';
    updateEmptyState(filteredProducts);

    filteredProducts.forEach(function (product) {
      productsListElement.appendChild(createProductCard(product));
    });
  }

  function renderPage() {
    updateSummary();
    updateActiveFilters();
    renderProducts();
  }

  function showLoadError() {
    if (produtos.length > 0) {
      document.getElementById('produtos-lista-aviso').textContent = 'Não foi possível carregar os produtos da API. Exibindo fallback local.';
      return;
    }

    productsEmptyElement.hidden = false;
    productsEmptyElement.querySelector('.admin-products-empty-title').textContent = 'Não foi possível carregar os produtos.';
    productsEmptyElement.querySelector('.admin-products-empty-text').textContent = 'Verifique se o backend está rodando e tente novamente.';
  }

  async function loadProductsFromApi() {
    try {
      produtos = await fetchAdminProducts();
      renderPage();
    } catch (error) {
      produtos = loadLocalProducts();
      renderPage();
      showLoadError();
    }
  }

  productsForm.addEventListener('submit', async function (event) {
    var productData;
    var validationMessage;

    event.preventDefault();
    productData = getFormData();
    validationMessage = validateProduct(productData);

    if (validationMessage) {
      showFormError(validationMessage);
      return;
    }

    if (productData.id) {
      await handleEditProduct(productData);
      return;
    }

    await handleCreateProduct(productData);
  });

  createProductButton.addEventListener('click', function () {
    resetForm();
    productModal.showModal();
    productNameInput.focus();
  });
  productCancelEditButton.addEventListener('click', function () { productModal.close(); });
  productModal.addEventListener('close', resetForm);

  categoryFilterButtons.forEach(function (button) {
    button.addEventListener('click', function () {
      selectedCategory = button.dataset.category;
      renderPage();
    });
  });

  statusFilterButtons.forEach(function (button) {
    button.addEventListener('click', function () {
      selectedStatus = button.dataset.status;
      renderPage();
    });
  });

  productsBackDashboardButton.addEventListener('click', function () {
    window.location.href = './admin-dashboard.html';
  });

  productsLogoutButton.addEventListener('click', function () {
    clearAdminSession();
    window.location.href = './admin-login.html';
  });

  resetForm();
  loadProductsFromApi();
}
