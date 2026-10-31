-- Dados acadêmicos opcionais. Execute APÓS schema.sql ou Atualizar-Banco.ps1.
-- Primeira execução: exige catálogo e pedidos vazios. Não altera usuários existentes.
-- Repetições desta versão são ignoradas, preservando senhas, preços e saldos.
-- Admin demonstrativo: admin@pim.com / 123456, com troca obrigatória no primeiro acesso.
BEGIN;
SELECT pg_advisory_xact_lock(746005, 1);
CREATE TABLE IF NOT EXISTS pim_seed_historico (
    versao VARCHAR(80) PRIMARY KEY,
    aplicado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $seed$
DECLARE
    versao_seed CONSTANT TEXT := '20261031_catalogo_kits_v1';
    pedido_um INTEGER;
    pedido_dois INTEGER;
BEGIN
    IF EXISTS (SELECT 1 FROM pim_seed_historico WHERE versao = versao_seed) THEN
        RAISE NOTICE 'Seed já aplicado. Nenhum dado ou senha foi alterado.';
        RETURN;
    END IF;
    IF to_regclass('public.sessao_acesso') IS NULL OR NOT EXISTS (
        SELECT 1 FROM information_schema.columns WHERE table_schema = 'public'
        AND table_name = 'movimentacao_estoque' AND column_name = 'operacao_id'
    ) THEN
        RAISE EXCEPTION 'Estrutura desatualizada. Execute schema.sql ou Atualizar-Banco.ps1 antes do seed.';
    END IF;
    IF EXISTS (SELECT 1 FROM produto) OR EXISTS (SELECT 1 FROM pedido) THEN
        RAISE EXCEPTION 'Seed demonstrativo exige catálogo e pedidos vazios. Nenhum dado foi alterado. Para banco de uso, cadastre os produtos pela aplicação.';
    END IF;

    -- Se já existe administrador, mantém seus dados e não cria outro acesso público.
    IF NOT EXISTS (SELECT 1 FROM colaborador WHERE perfil = 'Administrador') THEN
        IF EXISTS (SELECT 1 FROM colaborador WHERE lower(trim(email_usuario)) = 'admin@pim.com') THEN
            RAISE EXCEPTION 'O e-mail demonstrativo já pertence a outro perfil. Defina o administrador antes de popular o banco.';
        END IF;
        INSERT INTO colaborador (nome_usuario, email_usuario, senha_usuario, perfil, trocar_senha)
        VALUES ('Admin', 'admin@pim.com', crypt('123456', gen_salt('bf')), 'Administrador', TRUE);
    END IF;

    INSERT INTO produto (nome_produto, categoria, preco, descricao,
                         status_disponibilidade, estoque, imagem_url, eh_kit)
    SELECT nome, categoria, preco, descricao, status,
           CASE WHEN categoria = 'combo' THEN 0 ELSE estoque END,
           imagem, categoria = 'combo'
    FROM (VALUES
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
    ('Combo Familia', 'combo', 89.90, '- Pizza grande de frango' || CHR(10) || '- Pizza broto doce' || CHR(10) || '- Refrigerante 2L', 'disponivel', 10, '/img/combo-familia-800.jpg'),
    ('Pizza Broto Salgada', 'pizza', 24.90, 'Pizza broto de mussarela para o combo individual', 'disponivel', 20, '/img/mussarela800.jpg'),
    ('Pizza Broto Doce', 'doce', 19.90, 'Pizza broto de chocolate para o combo familia', 'disponivel', 15, '/img/chocolate800.jpg')
    ) AS dados(nome, categoria, preco, descricao, status, estoque, imagem);

    INSERT INTO kit_componente (id_kit, id_produto, quantidade)
    SELECT kit.codprod, componente.codprod, dados.quantidade
    FROM (VALUES
        ('Combo Individual', 'Pizza Broto Salgada', 1),
        ('Combo Individual', 'Coca-Cola 600ml', 1),
        ('Combo Casal', 'Pizza Frango', 1),
        ('Combo Casal', 'Coca-Cola 2L', 1),
        ('Combo Familia', 'Pizza Frango', 1),
        ('Combo Familia', 'Pizza Broto Doce', 1),
        ('Combo Familia', 'Coca-Cola 2L', 1)
    ) AS dados(kit, componente, quantidade)
    JOIN produto kit ON kit.nome_produto = dados.kit
    JOIN produto componente ON componente.nome_produto = dados.componente;

    -- IDs vêm do INSERT: funciona mesmo se as sequências já foram incrementadas.
    INSERT INTO pedido (codigo, nome_cliente, telefone_cliente, tipo_entrega,
        rua_entrega, numero_entrega, bairro_entrega, complemento_entrega,
        observacoes, status_pedido, valor_total)
    VALUES ('PED001', 'Gabriel', '14999999999', 'entrega', 'Rua A', '123',
        'Centro', '', 'Sem cebola', 'recebido', 39.90)
    RETURNING id_pedido INTO pedido_um;
    INSERT INTO pedido (codigo, nome_cliente, telefone_cliente, tipo_entrega,
        observacoes, status_pedido, valor_total)
    VALUES ('PED002', 'Maria', '14988888888', 'retirada', 'Retirar no balcao', 'em_preparo', 48.80)
    RETURNING id_pedido INTO pedido_dois;

    INSERT INTO itempedido (id_pedido, codprod, quantidade, preco_unitario, subtotal)
    SELECT pedido_um, codprod, 1, preco, preco FROM produto WHERE nome_produto = 'Pizza Calabresa';
    INSERT INTO itempedido (id_pedido, codprod, quantidade, preco_unitario, subtotal)
    SELECT pedido_dois, codprod, 1, preco, preco FROM produto WHERE nome_produto IN ('Pizza Frango', 'Coca-Cola 600ml');
    INSERT INTO pagamento (id_pedido, forma_pagamento, status_pagamento, valor_pago)
    VALUES (pedido_um, 'pix', 'pendente', 39.90), (pedido_dois, 'cartao', 'pendente', 48.80);

    -- Os pedidos demonstrativos também têm baixa e composição histórica coerentes.
    INSERT INTO pedido_baixa_estoque (id_pedido, id_produto, quantidade)
    SELECT id_pedido, codprod, sum(quantidade)::int FROM itempedido
    WHERE id_pedido IN (pedido_um, pedido_dois) GROUP BY id_pedido, codprod;
    UPDATE produto p SET estoque = p.estoque - baixas.quantidade
    FROM (SELECT id_produto, sum(quantidade)::int AS quantidade FROM pedido_baixa_estoque
          WHERE id_pedido IN (pedido_um, pedido_dois) GROUP BY id_produto) baixas
    WHERE p.codprod = baixas.id_produto;

    INSERT INTO pim_seed_historico (versao) VALUES (versao_seed);
END $seed$;
COMMIT;
