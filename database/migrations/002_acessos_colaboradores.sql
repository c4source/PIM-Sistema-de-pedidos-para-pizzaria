BEGIN;
ALTER TABLE colaborador ADD COLUMN IF NOT EXISTS perfil VARCHAR(20) NOT NULL DEFAULT 'Colaborador' CHECK (perfil IN ('Administrador','Colaborador'));
ALTER TABLE colaborador ADD COLUMN IF NOT EXISTS trocar_senha BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE colaborador ADD COLUMN IF NOT EXISTS versao_sessao INT NOT NULL DEFAULT 1;
CREATE UNIQUE INDEX IF NOT EXISTS uq_colaborador_email_normalizado ON colaborador(lower(trim(email_usuario)));
UPDATE colaborador SET perfil='Administrador' WHERE lower(trim(email_usuario))='admin@pim.com' AND NOT EXISTS (SELECT 1 FROM colaborador WHERE perfil='Administrador');
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM colaborador WHERE perfil='Administrador') THEN RAISE EXCEPTION 'Nenhum administrador definido; selecione a conta inicial antes de aplicar a migração.'; END IF; END $$;
COMMIT;
