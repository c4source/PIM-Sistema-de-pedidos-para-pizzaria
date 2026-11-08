-- Referência documental SQLite v3; criada automaticamente pelo aplicativo.
-- Não aplicar ao PostgreSQL. Sem registros nem credenciais.

CREATE TABLE produtos (id INTEGER PRIMARY KEY, eh_kit INTEGER NOT NULL, nome TEXT NOT NULL, preco REAL NOT NULL, descricao TEXT, categoria TEXT, status TEXT, estoque INTEGER, imagem_url TEXT, estoque_minimo INTEGER NOT NULL DEFAULT 5);

CREATE TABLE sincronizacao (id INTEGER PRIMARY KEY CHECK (id = 1), data TEXT NOT NULL);

CREATE TABLE IF NOT EXISTS fila_estoque (id TEXT PRIMARY KEY, usuario INTEGER NOT NULL, produto INTEGER NOT NULL, nome TEXT NOT NULL, tipo TEXT NOT NULL, quantidade INTEGER NOT NULL CHECK(quantidade > 0), criada TEXT NOT NULL, estado TEXT NOT NULL DEFAULT "pendente", erro TEXT, tentada INTEGER NOT NULL DEFAULT 0, motivo TEXT NOT NULL DEFAULT "outro", observacao TEXT, estoque_esperado INTEGER, quantidade_contada INTEGER);

CREATE INDEX IF NOT EXISTS fila_usuario ON fila_estoque(usuario, criada);
