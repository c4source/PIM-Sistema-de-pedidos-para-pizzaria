BEGIN;
ALTER TABLE produto ADD COLUMN IF NOT EXISTS eh_kit BOOLEAN NOT NULL DEFAULT FALSE;
CREATE TABLE IF NOT EXISTS kit_componente (
 id_kit INT NOT NULL REFERENCES produto(codprod) ON DELETE CASCADE,
 id_produto INT NOT NULL REFERENCES produto(codprod) ON DELETE RESTRICT,
 quantidade INT NOT NULL CHECK(quantidade>0),
 PRIMARY KEY(id_kit,id_produto), CHECK(id_kit<>id_produto)
);
CREATE TABLE IF NOT EXISTS pedido_baixa_estoque (
 id_pedido INT NOT NULL REFERENCES pedido(id_pedido) ON DELETE RESTRICT,
 id_produto INT NOT NULL REFERENCES produto(codprod) ON DELETE RESTRICT,
 quantidade INT NOT NULL CHECK(quantidade>0), PRIMARY KEY(id_pedido,id_produto)
);
CREATE OR REPLACE VIEW produto_com_estoque AS
 SELECT p.codprod,p.nome_produto,p.preco,p.descricao,p.categoria,p.status_disponibilidade,p.imagem_url,p.eh_kit,
 CASE WHEN p.eh_kit THEN COALESCE((SELECT min(CASE WHEN c.eh_kit OR c.status_disponibilidade<>'disponivel' THEN 0 ELSE c.estoque/k.quantidade END) FROM kit_componente k JOIN produto c ON c.codprod=k.id_produto WHERE k.id_kit=p.codprod),0)::int ELSE p.estoque END AS estoque
 FROM produto p;

INSERT INTO pedido_baixa_estoque(id_pedido,id_produto,quantidade) SELECT id_pedido,codprod,sum(quantidade)::int FROM itempedido i WHERE NOT EXISTS (SELECT 1 FROM pedido_baixa_estoque b WHERE b.id_pedido=i.id_pedido) GROUP BY id_pedido,codprod ON CONFLICT DO NOTHING;
COMMIT;
