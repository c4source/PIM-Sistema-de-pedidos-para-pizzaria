-- ARQUIVO HISTÓRICO (MySQL): não executar na versão PostgreSQL atual.
-- Para instalar, use database/schema.sql e database/seed.sql; consulte docs/10_instalacao_banco.md.

CREATE TABLE carrinho (
    id_carrinho INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_carrinho_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);

CREATE TABLE itemcarrinho (
    id_item_carrinho INT AUTO_INCREMENT PRIMARY KEY,
    id_carrinho INT NOT NULL,
    codprod INT NOT NULL,
    quantidade INT NOT NULL,
    observacoes VARCHAR(500) NULL,
    CONSTRAINT fk_itemcarrinho_carrinho
        FOREIGN KEY (id_carrinho) REFERENCES carrinho(id_carrinho)
        ON DELETE CASCADE,
    CONSTRAINT fk_itemcarrinho_produto
        FOREIGN KEY (codprod) REFERENCES produto(codprod)
);

ALTER TABLE pedido
    ADD COLUMN tipo_entrega VARCHAR(30) NOT NULL DEFAULT 'Retirada',
    ADD COLUMN endereco_entrega VARCHAR(500) NULL,
    ADD COLUMN taxa_entrega DECIMAL(10,2) NOT NULL DEFAULT 0,
    ADD COLUMN tempo_estimado_minutos INT NULL,
    ADD COLUMN aprovado_em DATETIME NULL,
    ADD COLUMN cancelado_em DATETIME NULL,
    ADD COLUMN cancelado_por VARCHAR(30) NULL,
    ADD COLUMN motivo_cancelamento VARCHAR(500) NULL;

ALTER TABLE itempedido
    ADD COLUMN observacoes VARCHAR(500) NULL;

ALTER TABLE produto
    ADD COLUMN categoria VARCHAR(100) NULL;
