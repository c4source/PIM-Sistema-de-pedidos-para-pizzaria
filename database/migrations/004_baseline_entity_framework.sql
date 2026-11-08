-- Apenas para banco existente que já recebeu as migrações 002 e 003.
-- Não cria nem recria as tabelas de negócio; registra a estrutura já existente.
BEGIN;
DO $$ BEGIN
IF EXISTS(SELECT 1 FROM (VALUES ('produto','eh_kit'),('colaborador','perfil'),('colaborador','trocar_senha'),('colaborador','versao_sessao'),('kit_componente','id_kit'),('pedido_baixa_estoque','id_pedido')) AS esperado(tabela,coluna) WHERE NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name=esperado.tabela AND column_name=esperado.coluna)) THEN RAISE EXCEPTION 'Aplique as migrações SQL anteriores antes da baseline EF.'; END IF;
END $$;
CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" ("MigrationId" varchar(150) NOT NULL PRIMARY KEY, "ProductVersion" varchar(32) NOT NULL);
INSERT INTO "__EFMigrationsHistory"("MigrationId","ProductVersion") VALUES('20261016222636_InicialEntityFramework','10.0.13') ON CONFLICT DO NOTHING;
COMMIT;
