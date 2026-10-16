CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO colaborador (
    nome_usuario,
    email_usuario,
    senha_usuario,
    perfil
)
VALUES (
    'Admin',
    'admin@pim.com',
    crypt('123456', gen_salt('bf')),
    'Administrador'
)
ON CONFLICT (email_usuario) DO UPDATE
SET
    nome_usuario = EXCLUDED.nome_usuario,
    senha_usuario = EXCLUDED.senha_usuario,
    perfil = EXCLUDED.perfil,
    versao_sessao = colaborador.versao_sessao + 1;

INSERT INTO produto (
    nome_produto,
    categoria,
    preco,
    descricao,
    status_disponibilidade,
    estoque,
    imagem_url
) VALUES

    ('Pizza Portuguesa', 'pizza', 44.90, 'Pizza com presunto, ovos, cebola, ervilha, queijo e molho especial', 'disponivel', 20, '/img/portuguesa800.jpg'),
    ('Pizza Marguerita', 'pizza', 41.90, 'Pizza com mussarela, tomate, manjericao e molho especial', 'disponivel', 20, '/img/marguerita800.jpg'),
    ('Pizza Mussarela', 'pizza', 37.90, 'Pizza classica com mussarela derretida e molho de tomate', 'disponivel', 20, '/img/mussarela800.jpg'),
    ('Pizza Pepperoni', 'pizza', 46.90, 'Pizza com pepperoni, queijo e molho especial', 'disponivel', 20, '/img/pepperoni800.jpg'),
    ('Pizza Atum', 'pizza', 43.90, 'Pizza com atum, cebola, queijo e molho especial', 'disponivel', 20, '/img/atum800.jpg'),
    ('Pizza Bacon', 'pizza', 45.90, 'Pizza com bacon crocante, queijo e molho especial', 'disponivel', 20, '/img/bacon800.jpg'),
    ('Pizza Brocolis com Bacon', 'pizza', 45.90, 'Pizza com brocolis, bacon, queijo e molho especial', 'disponivel', 20, '/img/brocolis-bacon800.jpg'),
    ('Pizza Frango com Catupiry', 'pizza', 44.90, 'Pizza com frango desfiado, catupiry, queijo e molho especial', 'disponivel', 20, '/img/frango-catupiry800.jpg'),
    ('Pizza Calabresa', 'pizza', 39.90, 'Pizza de calabresa com cebola e queijo', 'disponivel', 20, '/img/calabresa800.jpg'),
    ('Pizza Frango', 'pizza', 39.90, 'Pizza com frango, queijo e molho especial', 'disponivel', 20, '/img/frango800.jpg'),
    ('Pizza 4 Queijos', 'pizza', 42.90, 'Pizza com mistura de quatro queijos', 'disponivel', 20, '/img/4queijos800.jpg'),

    ('Pizza Chocolate', 'doce', 44.90, 'Pizza doce com chocolate cremoso e granulado', 'disponivel', 15, '/img/chocolate800.jpg'),
    ('Pizza Banana com Canela', 'doce', 41.90, 'Pizza doce com banana, canela e toque de acucar', 'disponivel', 15, '/img/banana-com-canela.jpg'),
    ('Pizza Romeu e Julieta', 'doce', 43.90, 'Pizza doce com queijo cremoso e goiabada', 'disponivel', 15, '/img/romeu-e-julieta800.jpg'),

    ('Coca-Cola Lata', 'bebida', 6.50, 'Refrigerante gelado em lata', 'disponivel', 50, '/img/cocalata800.jpg'),
    ('Coca-Cola 600ml', 'bebida', 8.90, 'Refrigerante gelado 600ml', 'disponivel', 50, '/img/coca600-800.jpg'),
    ('Coca-Cola 2L', 'bebida', 12.90, 'Refrigerante gelado 2 litros', 'disponivel', 40, '/img/coca2l800.jpg'),
    ('Guarana 2L', 'bebida', 10.90, 'Refrigerante guarana 2 litros', 'disponivel', 40, '/img/guarana2l800.jpg'),
    ('Agua sem gas', 'bebida', 4.50, 'Agua mineral sem gas', 'disponivel', 60, '/img/aguasemgass800.jpg'),
    ('Agua com gas', 'bebida', 4.90, 'Agua mineral com gas', 'disponivel', 60, '/img/aguacmgas800.jpg'),

    ('Combo Individual', 'combo', 29.90, '- Pizza broto salgada' || CHR(10) || '- Refrigerante 600ml', 'disponivel', 10, '/img/combo-individual-800.jpg'),
    ('Combo Casal', 'combo', 59.90, '- Pizza grande de frango' || CHR(10) || '- Refrigerante 2L', 'disponivel', 10, '/img/combo-casal-800.jpg'),
    ('Combo Familia', 'combo', 89.90, '- Pizza grande de frango' || CHR(10) || '- Pizza broto doce' || CHR(10) || '- Refrigerante 2L', 'disponivel', 10, '/img/combo-familia-800.jpg');

INSERT INTO pedido (
    codigo,
    nome_cliente,
    telefone_cliente,
    tipo_entrega,
    rua_entrega,
    numero_entrega,
    bairro_entrega,
    complemento_entrega,
    observacoes,
    status_pedido,
    valor_total
) VALUES
    ('PED001', 'Gabriel', '14999999999', 'entrega', 'Rua A', '123', 'Centro', '', 'Sem cebola', 'recebido', 39.90),
    ('PED002', 'Maria', '14988888888', 'retirada', NULL, NULL, NULL, NULL, 'Retirar no balcao', 'em_preparo', 48.80);

INSERT INTO itempedido (
    id_pedido,
    codprod,
    quantidade,
    preco_unitario,
    subtotal
)
VALUES
    (1, 9, 1, 39.90, 39.90),
    (2, 10, 1, 39.90, 39.90),
    (2, 16, 1, 8.90, 8.90);

INSERT INTO pagamento (
    id_pedido,
    forma_pagamento,
    status_pagamento,
    valor_pago
) VALUES
    (1, 'pix', 'pendente', 39.90),
    (2, 'cartao', 'pendente', 48.80);