-- V21: escopo forçado & RLS (TEN-05, TEN-03 -- camada de banco)
-- Fase 21 assenta a camada de banco do isolamento multi-tenant sobre a
-- fundação física da V20 (company_id nas 12 tabelas de negócio, Empresa #1
-- seedada). Três passos, nesta ordem, todos dentro da transação implícita do
-- Flyway (Postgres DDL é transacional -- nenhum estado parcial possível):
--   1. D-10 (fail-loud): dropar o DEFAULT transicional default_company_id()
--      instalado pela V20 em todas as 12 tabelas + a própria função. A partir
--      daqui, qualquer INSERT que omita company_id falha com 23502 (NOT NULL)
--      em vez de cair silenciosamente na Empresa #1 -- a obrigação futura
--      registrada em V20's header ("Fase 21 removes/neutralizes this default").
--   2. D-08: criar o role de aplicação controlcar_app -- LOGIN, NÃO-superusuário,
--      sem BYPASSRLS (basta não conceder -- não é o default), NÃO-owner de
--      tabela nenhuma (o Flyway roda como postgres, que segue owner). Senha via
--      placeholder Flyway ${app_db_password}, mesma convenção de ${admin_password}
--      desde a V16 -- nunca senha literal.
--   3. D-07: para cada uma das 11 tabelas tenant NOT NULL, habilitar row level
--      security no modo forçado (o par ENABLE+FORCE é obrigatório -- o modo
--      forçado fecha o bypass de owner que o modo simples não fecha) + criar
--      uma policy de isolamento por empresa filtrando por company_id =
--      app.current_company. current_setting(..., true) retorna NULL (não erro)
--      quando a GUC não foi setada -- a policy é fail-closed por padrão:
--      company_id = NULL nunca é true em SQL, então uma sessão sem SET LOCAL
--      não vê nenhuma linha.
--
-- Decisão de arquitetura RLS - Opção B (backstop provado, ver 21-01-PLAN.md):
-- a app continua conectando como postgres (superusuário -- bypassa RLS) para o
-- tráfego normal; a RLS é defesa em profundidade provada por testes que
-- conectam como controlcar_app (Plano 21-06). A defesa PRIMÁRIA do isolamento
-- é o callback GORM D-01 (Plano 21-03) + os filtros manuais (Plano 21-04).
-- A DATABASE_URL da app NÃO muda nesta fase.
--
-- users fica FORA da RLS por company_id (nullable, D-03 -- reservado para o
-- futuro platform_admin master row, Fase 22) -- recebe apenas os GRANTs.

-- ============================================================
-- Passo 1 (D-10, fail-loud): drop do DEFAULT transicional + da função
-- ============================================================
ALTER TABLE users ALTER COLUMN company_id DROP DEFAULT;
ALTER TABLE employees ALTER COLUMN company_id DROP DEFAULT;
ALTER TABLE clients ALTER COLUMN company_id DROP DEFAULT;
ALTER TABLE contracts ALTER COLUMN company_id DROP DEFAULT;
ALTER TABLE vehicles ALTER COLUMN company_id DROP DEFAULT;
ALTER TABLE vehicle_documents ALTER COLUMN company_id DROP DEFAULT;
ALTER TABLE vehicle_tasks ALTER COLUMN company_id DROP DEFAULT;
ALTER TABLE maintenances ALTER COLUMN company_id DROP DEFAULT;
ALTER TABLE files ALTER COLUMN company_id DROP DEFAULT;
ALTER TABLE client_requests ALTER COLUMN company_id DROP DEFAULT;
ALTER TABLE notifications ALTER COLUMN company_id DROP DEFAULT;
ALTER TABLE audit_logs ALTER COLUMN company_id DROP DEFAULT;

DROP FUNCTION default_company_id();

-- ============================================================
-- Passo 2 (D-08): role de aplicação não-superusuário, sem BYPASSRLS, não-owner
-- ============================================================
-- Senha via placeholder Flyway -- mesma convenção de ${admin_password} (V16).
-- NUNCA conceder BYPASSRLS: o role não tem esse atributo simplesmente por
-- não ser concedido explicitamente (não é o default de CREATE ROLE).
CREATE ROLE controlcar_app LOGIN PASSWORD '${app_db_password}';

-- GRANT CONNECT ON DATABASE via current_database() (not a literal "controlcar")
-- so this migration applies unchanged across every environment that runs it:
-- prod/dev (db "controlcar"), the TestMain integration harness (also
-- "controlcar", via the Postgres testcontainer), AND the separate
-- migrate_helper_test.go harness used by schema/softdelete/tenant schema
-- tests, which provisions its own testcontainer under a different db name
-- ("controlcar_schema_test") -- a hardcoded literal here would break that
-- harness with "database ... does not exist".
DO $$
BEGIN
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO controlcar_app', current_database());
END
$$;
GRANT USAGE ON SCHEMA public TO controlcar_app;

-- 11 tabelas tenant + users (o 12º modelo de negócio, fora do filtro RLS por
-- company_id mas ainda precisa de acesso de dados).
GRANT SELECT, INSERT, UPDATE, DELETE ON
    users, employees, clients, contracts, vehicles, vehicle_documents,
    vehicle_tasks, maintenances, files, client_requests, notifications, audit_logs
    TO controlcar_app;

-- companies não é tenant-scoped por company_id -- só leitura.
GRANT SELECT ON companies TO controlcar_app;

-- ============================================================
-- Passo 3 (D-07): RLS nas 11 tabelas tenant NOT NULL -- ENABLE + FORCE + POLICY
-- (users fica fora -- nullable, D-03)
-- ============================================================
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_employees ON employees
    USING (company_id = current_setting('app.current_company', true)::uuid);

ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_clients ON clients
    USING (company_id = current_setting('app.current_company', true)::uuid);

ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE contracts FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_contracts ON contracts
    USING (company_id = current_setting('app.current_company', true)::uuid);

ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_vehicles ON vehicles
    USING (company_id = current_setting('app.current_company', true)::uuid);

ALTER TABLE vehicle_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_documents FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_vehicle_documents ON vehicle_documents
    USING (company_id = current_setting('app.current_company', true)::uuid);

ALTER TABLE vehicle_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_tasks FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_vehicle_tasks ON vehicle_tasks
    USING (company_id = current_setting('app.current_company', true)::uuid);

ALTER TABLE maintenances ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenances FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_maintenances ON maintenances
    USING (company_id = current_setting('app.current_company', true)::uuid);

ALTER TABLE files ENABLE ROW LEVEL SECURITY;
ALTER TABLE files FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_files ON files
    USING (company_id = current_setting('app.current_company', true)::uuid);

ALTER TABLE client_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_requests FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_client_requests ON client_requests
    USING (company_id = current_setting('app.current_company', true)::uuid);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_notifications ON notifications
    USING (company_id = current_setting('app.current_company', true)::uuid);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_audit_logs ON audit_logs
    USING (company_id = current_setting('app.current_company', true)::uuid);
