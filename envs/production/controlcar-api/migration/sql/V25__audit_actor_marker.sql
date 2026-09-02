-- V25: marcador de ator em audit_logs (QUAL-03/PADM-04 -- D-05/D-09/D-10)
-- Reserva o encaixe de uma futura impersonação do master SEM migração nova
-- (D-05): adiciona 3 colunas NULL-por-padrão a audit_logs, nenhuma linha
-- existente quebra.
--   - actor_type            TEXT NULL -- 'user' (ator comum, hoje implícito
--     via user_id) ou 'platform_admin' (ação do master). CHECK restringe aos
--     dois valores quando informado; NULL preserva as linhas gravadas antes
--     desta migração (D-09 não retroage sobre auditoria já existente).
--   - actor_platform_admin_id UUID NULL REFERENCES users(id) -- id do
--     platform_admin que executou a ação, quando actor_type='platform_admin'
--     (mesmo padrão de FK opcional que audit_logs.user_id já usa, V13).
--   - acted_as_company      UUID NULL REFERENCES companies(id) -- reserva o
--     encaixe de uma futura impersonação (D-05): quando o master agir COMO
--     uma empresa específica, esta coluna guarda qual. Nenhum usecase desta
--     fase a preenche -- fica reservada, sempre NULL até a impersonação (fora
--     do v3.0, D-04) ser construída.
--
-- IMPORTANTE (D-09/D-10): nas ações do platform_admin, quem carrega a
-- empresa-ALVO da ação é a coluna JÁ EXISTENTE audit_logs.company_id (não
-- NULL -- a empresa acionada), não acted_as_company. Mesma tabela audit_logs,
-- um só stream (D-10) -- nenhum stream/tabela de auditoria separado para o
-- master.
--
-- Não mexe na estrutura de roles/policies RLS da V21 -- controlcar_app já tem
-- SELECT/INSERT/UPDATE/DELETE em audit_logs (V21 GRANT), nenhum GRANT novo
-- necessário para as 3 colunas.
ALTER TABLE audit_logs ADD COLUMN actor_type TEXT;
ALTER TABLE audit_logs ADD COLUMN actor_platform_admin_id UUID REFERENCES users (id);
ALTER TABLE audit_logs ADD COLUMN acted_as_company UUID REFERENCES companies (id);

ALTER TABLE audit_logs ADD CONSTRAINT audit_logs_actor_type_check
    CHECK (actor_type IS NULL OR actor_type IN ('user', 'platform_admin'));
