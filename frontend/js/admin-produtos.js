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
    document.querySelector('label[for="product-stock"] .admin-products-label').textContent =
      productKitInput.checked ? 'Kits possíveis' : 'Estoque';
    if (productKitInput.checked) calcularKitsPossiveis();
  }
  function calcularKitsPossiveis() {
    if (!productKitInput.checked) return;
    var quantidades = new Map();
    var valido = kitList.children.length > 0;
    Array.from(kitList.children).forEach(function (row) {
      var id = Number(row.querySelector('select').value);
      var quantidade = Number(row.querySelector('input').value);
      if (!id || !Number.isInteger(quantidade) || quantidade <= 0) {
        valido = false;
        return;
      }
      quantidades.set(id, (quantidades.get(id) || 0) + quantidade);
    });
    var possiveis = Infinity;
    quantidades.forEach(function (quantidade, id) {
      var produto = produtos.find(function (p) {
        return Number(p.id) === id;
      });
      if (!produto || produto.ehKit || produto.disponivel === false) {
        possiveis = 0;
        return;
      }
      possiveis = Math.min(possiveis, Math.floor(produto.estoque / quantidade));
    });
    productStockInput.value = valido && Number.isFinite(possiveis) ? possiveis : 0;
  }
  kitList.addEventListener('input', calcularKitsPossiveis);
  kitList.addEventListener('change', calcularKitsPossiveis);
  function adicionarComponente(comp) {
    var row = document.createElement('div');
    row.className = 'kit-componente';
    var label = document.createElement('label');
    label.textContent = 'Produto';
    var select = document.createElement('select');
    select.className = 'admin-products-input';
    var placeholder = document.createElement('option');
    placeholder.value = '';
    placeholder.textContent = 'Selecione um produto';
    select.appendChild(placeholder);
    produtos
      .filter(function (p) {
        return !p.ehKit && Number(p.id) !== Number(productIdInput.value);
      })
      .forEach(function (p) {
        var option = document.createElement('option');
        option.value = p.id;
        option.textContent = p.nome;
        select.appendChild(option);
      });
    select.value = comp ? comp.idProduto : '';
    var qtyLabel = document.createElement('label');
    qtyLabel.textContent = 'Quantidade';
    var qty = document.createElement('input');
    qty.type = 'number';
    qty.min = '1';
    qty.step = '1';
    qty.value = comp ? comp.quantidade : 1;
    qty.className = 'admin-products-input';
    var remove = document.createElement('button');
    remove.type = 'button';
    remove.textContent = '×';
    remove.title = 'Remover componente';
    remove.setAttribute('aria-label', 'Remover componente');
    remove.addEventListener('click', function () {
      row.remove();
      calcularKitsPossiveis();
    });
    label.appendChild(select);
    qtyLabel.appendChild(qty);
    row.append(label, qtyLabel, remove);
    kitList.appendChild(row);
    calcularKitsPossiveis();
  }
  productKitInput.addEventListener('change', function () {
    atualizarTipoKit();
    if (productKitInput.checked && !kitList.children.length) adicionarComponente();
  });
  document.getElementById('kit-add-component').addEventListener('click', function () {
    adicionarComponente();
  });
  var productAvailableInput = document.getElementById('product-available');
  var productSubmitButton = document.getElementById('product-submit-button');
  var productCancelEditButton = document.getElementById('product-cancel-edit-button');
  var productFormError = document.getElementById('product-form-error');
  var productsListElement = document.getElementById('admin-products-list');
  var productsEmptyElement = document.getElementById('admin-products-empty');
  var categoryFilterButtons = document.querySelectorAll('[data-category]');
  var statusFilterButtons = document.querySelectorAll('[data-status]');
  var searchInput = document.getElementById('produtos-busca');
  var typeFilter = document.getElementById('produtos-tipo');
  var stockFilter = document.getElementById('produtos-estoque');
  var saving = false;
  function notificarSucesso(texto) {
    document.getElementById('produto-sucesso-texto').textContent = texto;
    var modal = document.getElementById('produto-sucesso-modal');
    if (!modal.open) modal.showModal();
  }
  [searchInput, typeFilter, stockFilter].forEach(function (input) {
    input.addEventListener(input === searchInput ? 'input' : 'change', renderPage);
  });
  document.getElementById('produtos-limpar-filtros').addEventListener('click', function () {
    searchInput.value = '';
    typeFilter.value = 'todos';
    stockFilter.value = 'todos';
    selectedCategory = 'todos';
    selectedStatus = 'todos';
    renderPage();
  });
  function atualizarPrevia() {
    var figure = document.getElementById('produto-imagem-previa');
    var image = figure.querySelector('img');
    figure.hidden = !productImageInput.value.trim();
    image.src = productImageInput.value.trim();
    figure.querySelector('figcaption').textContent = 'Prévia da imagem';
    image.hidden = false;
    image.onerror = function () {
      image.hidden = true;
      figure.querySelector('figcaption').textContent =
        'Imagem não encontrada. Confira o caminho ou URL.';
    };
  }
  productImageInput.addEventListener('input', atualizarPrevia);
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
        estoque:
          Number.isInteger(Number(product.estoque)) && Number(product.estoque) >= 0
            ? Number(product.estoque)
            : 0,
        disponivel: normalizeAvailability(product)
      };
    });
  }

  function normalizeAvailability(product) {
    var status = String(product.status || product.status_disponibilidade || '').toLowerCase();

    if (
      product.disponivel === false ||
      status === 'false' ||
      status === 'indisponivel' ||
      status === 'indisponível'
    ) {
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
    return product.disponivel === false
      ? 'Desativado'
      : product.estoque <= 0
        ? 'Sem estoque'
        : 'Disponível';
  }

  function getFormData() {
    return {
      ehKit: productKitInput.checked,
      componentes: productKitInput.checked
        ? Array.from(kitList.children).map(function (row) {
            return {
              idProduto: Number(row.querySelector('select').value),
              quantidade: Number(row.querySelector('input').value)
            };
          })
        : [],
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
    var target = message.includes('nome')
      ? productNameInput
      : message.includes('categoria')
        ? productCategoryInput
        : message.includes('preço')
          ? productPriceInput
          : message.includes('descrição')
            ? productDescriptionInput
            : message.includes('imagem')
              ? productImageInput
              : message.includes('estoque')
                ? productStockInput
                : message.includes('liberado para venda')
                  ? productAvailableInput
                  : null;
    if (target) {
      target.setAttribute('aria-invalid', 'true');
      target.setAttribute('aria-describedby', 'product-form-error');
      target.focus();
    }
  }

  function clearFormError() {
    productFormError.textContent = '';
    productsForm.querySelectorAll('[aria-invalid]').forEach(function (input) {
      input.removeAttribute('aria-invalid');
      input.removeAttribute('aria-describedby');
    });
  }

  function validateProduct(productData) {
    if (
      productData.ehKit &&
      (!productData.componentes.length ||
        productData.componentes.some(function (c) {
          return !c.idProduto || !Number.isInteger(c.quantidade) || c.quantidade <= 0;
        }) ||
        new Set(
          productData.componentes.map(function (c) {
            return c.idProduto;
          })
        ).size !== productData.componentes.length)
    )
      return 'Selecione produtos diferentes e quantidades inteiras maiores que zero para o kit.';
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
      return 'Informe se o produto está liberado para venda.';
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
    atualizarPrevia();
  }

  async function reloadProducts() {
    produtos = await fetchAdminProducts();
    document.getElementById('produtos-lista-aviso').textContent = '';
    renderPage();
  }

  async function salvarProduto(productData, editando) {
    if (saving) return;
    saving = true;
    productSubmitButton.disabled = true;
    productCancelEditButton.disabled = true;
    productSubmitButton.textContent = 'Salvando...';
    clearFormError();
    try {
      await ProdutosUI.salvar({
        persistir: function () {
          return editando
            ? updateAdminProduct(Number(productData.id), productData)
            : createAdminProduct(productData);
        },
        fechar: function () {
          productModal.close();
        },
        notificar: function () {
          notificarSucesso(
            editando ? 'Produto editado com sucesso!' : 'Produto criado com sucesso!'
          );
        },
        recarregar: reloadProducts,
        avisar: function (texto) {
          document.getElementById('produtos-lista-aviso').textContent = texto;
        }
      });
    } catch (error) {
      showFormError(error.message || 'Não foi possível salvar o produto.');
    } finally {
      saving = false;
      productSubmitButton.disabled = false;
      productCancelEditButton.disabled = false;
      productSubmitButton.textContent = productIdInput.value
        ? 'Salvar alterações'
        : 'Salvar produto';
    }
  }
  async function handleCreateProduct(data) {
    return salvarProduto(data, false);
  }
  async function handleEditProduct(data) {
    return salvarProduto(data, true);
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
    atualizarPrevia();
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

    var confirmation = document.getElementById('produto-excluir-modal');
    document.getElementById('produto-excluir-descricao').textContent =
      'Você está prestes a excluir “' + product.nome + '”.';
    confirmation.returnValue = '';
    confirmation.showModal();
    var confirmed = await new Promise(function (resolve) {
      confirmation.addEventListener(
        'close',
        function () {
          resolve(confirmation.returnValue === 'excluir');
        },
        { once: true }
      );
    });
    if (!confirmed) return;

    try {
      await ProdutosUI.salvar({
        persistir: function () {
          return deleteAdminProduct(product.id);
        },
        fechar: function () {},
        notificar: function () {
          notificarSucesso('Produto excluído com sucesso!');
        },
        recarregar: reloadProducts,
        avisar: function (texto) {
          document.getElementById('produtos-lista-aviso').textContent = texto;
        }
      });
    } catch (error) {
      document.getElementById('produtos-lista-aviso').textContent =
        error.message || 'Não foi possível excluir o produto.';
    }
  }

  function getFilteredProducts() {
    return ProdutosUI.filtrar(produtos, {
      busca: searchInput.value,
      categoria: selectedCategory,
      status: selectedStatus,
      tipo: typeFilter.value,
      estoque: stockFilter.value
    });
  }

  function updateSummary() {
    var availableProducts = produtos.filter(function (product) {
      return product.disponivel !== false && product.estoque > 0;
    }).length;
    var unavailableProducts = produtos.filter(function (product) {
      return product.disponivel === false || product.estoque <= 0;
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
    function element(tag, cls, text) {
      var node = document.createElement(tag);
      node.className = cls;
      if (text !== undefined) node.textContent = text;
      return node;
    }
    var row = element('article', 'produto-linha');
    var image = element('img', 'produto-miniatura');
    image.src = product.imagem;
    image.alt = '';
    image.loading = 'lazy';
    image.onerror = function () {
      image.hidden = true;
    };
    var info = element('div', 'produto-identidade');
    info.appendChild(element('h3', '', product.nome));
    info.appendChild(
      element(
        'p',
        'produto-categoria',
        formatCategory(product.categoria) + ' · ' + (product.ehKit ? 'Kit' : 'Produto individual')
      )
    );
    var facts = element('div', 'produto-fatos');
    facts.appendChild(element('strong', 'produto-preco', formatPrice(product.preco)));
    var saldoStatus = element('div', 'produto-saldo-status');
    saldoStatus.appendChild(
      element(
        'span',
        'produto-saldo ' +
          (product.estoque <= 0 ? 'is-zerado' : product.estoque <= 5 ? 'is-baixo' : ''),
        product.estoque + ' ' + (product.ehKit ? 'kits possíveis' : 'unidades')
      )
    );
    saldoStatus.appendChild(
      element('span', 'produto-disponibilidade', formatAvailability(product))
    );
    facts.appendChild(saldoStatus);
    if (product.ehKit) {
      var details = element('details', 'produto-componentes');
      details.appendChild(element('summary', '', 'Ver componentes'));
      var list = element('ul', '');
      (product.componentes || []).forEach(function (c) {
        var p = produtos.find(function (p) {
          return Number(p.id) === Number(c.idProduto);
        });
        list.appendChild(
          element('li', '', c.quantidade + ' × ' + (p ? p.nome : 'Produto #' + c.idProduto))
        );
      });
      details.appendChild(list);
      info.appendChild(details);
    }
    var actions = element('div', 'produto-acoes');
    var edit = element('button', 'produtos-botao-neutro', 'Editar');
    edit.type = 'button';
    edit.setAttribute('aria-label', 'Editar ' + product.nome);
    edit.addEventListener('click', function () {
      editProduct(product.id);
    });
    var remove = element('button', 'produtos-botao-neutro produto-excluir', 'Excluir');
    remove.type = 'button';
    remove.setAttribute('aria-label', 'Excluir ' + product.nome);
    remove.addEventListener('click', function () {
      deleteProduct(product.id);
    });
    actions.append(edit, remove);
    row.append(image, info, facts, actions);
    return row;
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
      productsEmptyElement.querySelector('.admin-products-empty-title').textContent =
        'Nenhum produto cadastrado.';
      productsEmptyElement.querySelector('.admin-products-empty-text').textContent =
        'Clique em Criar produto para adicionar um produto ao cardápio.';
      return;
    }

    productsEmptyElement.querySelector('.admin-products-empty-title').textContent =
      'Nenhum produto encontrado para este filtro.';
    productsEmptyElement.querySelector('.admin-products-empty-text').textContent = '';
  }

  function renderProducts() {
    var filteredProducts = getFilteredProducts();

    document.getElementById('produtos-resultados').textContent =
      filteredProducts.length + ' de ' + produtos.length + ' produtos';
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
      document.getElementById('produtos-lista-aviso').textContent =
        'Não foi possível carregar os produtos da API. Exibindo fallback local.';
      return;
    }

    productsEmptyElement.hidden = false;
    productsEmptyElement.querySelector('.admin-products-empty-title').textContent =
      'Não foi possível carregar os produtos.';
    productsEmptyElement.querySelector('.admin-products-empty-text').textContent =
      'Verifique se o backend está rodando e tente novamente.';
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
  productCancelEditButton.addEventListener('click', function () {
    productModal.close();
  });
  productModal.addEventListener('close', resetForm);
  productModal.addEventListener('cancel', function (event) {
    if (saving) event.preventDefault();
  });

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
