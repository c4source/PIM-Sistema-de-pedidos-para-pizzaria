const API_BASE_URL = 'http://localhost:5162/api';

function adaptarProdutoApi(produto) {
  return {
    id: produto.id,
    nome: produto.nome,
    preco: Number(produto.preco) || 0,
    descricao: produto.descricao || '',
    categoria: produto.categoria || '',
    imagem: produto.imagemUrl || produto.imagem || '',
    disponivel: Number(produto.estoque) > 0 && (!produto.status || produto.status.toLowerCase() === 'disponivel' || produto.status.toLowerCase() === 'disponível')
  };
}

async function buscarProdutos() {
  var response = await fetch(API_BASE_URL + '/Produto');

  if (!response.ok) {
    throw new Error('Nao foi possivel carregar os produtos da API.');
  }

  var produtos = await response.json();
  return produtos.map(adaptarProdutoApi);
}

async function buscarProdutoPorId(id) {
  var response = await fetch(API_BASE_URL + '/Produto/' + id);

  if (!response.ok) {
    throw new Error('Nao foi possivel carregar o produto da API.');
  }

  return adaptarProdutoApi(await response.json());
}

async function finalizarPedido(pedido) {
  var response = await fetch(API_BASE_URL + '/Pedido/checkout-mvp', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(pedido)
  });

  if (!response.ok) {
    var errorMessage = await response.text();
    throw new Error(errorMessage || 'Nao foi possivel finalizar o pedido.');
  }

  return response.json();
}
