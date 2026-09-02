-- V20: multi-tenant foundation (TEN-01, TEN-02, TEN-04, MIG-01, MIG-02)
-- v3.0 pivots controlCar from single-tenant (one locadora) to multi-tenant SaaS:
-- N locadoras (tenants), each isolated by a new `companies` root entity + a
-- `company_id` column carried on every business table. This migration is the
-- *physical schema* foundation only — forced query/session scoping (TEN-03) is
-- Fase 21, `platform_admin`/console (PADM-*) is Fase 22.
--
-- Five steps, in this exact order, all inside Flyway's single implicit
-- transaction (Postgres DDL is transactional — no partial state possible):
--   1. CREATE TABLE companies + insert Empresa #1 (the current single locadora).
--   2. ADD COLUMN company_id (NULLABLE) on the 12 business tables.
--   3. Backfill every existing row -> Empresa #1.
--   4. SET NOT NULL (all except users) + FK RESTRICT-on-delete (all 12) +
--      swap the 3 global uniques (vehicles.plate, clients.cpf, employees.cpf)
--      for per-company composite unique indexes (TEN-04).
--   5. companies.owner_id = the current admin (MIG-02).
--
-- Why this order: adding `company_id UUID NOT NULL` directly would fail on any
-- populated table (mirrors the same not-null-after-backfill discipline this
-- project already applies -- see V5 `vehicles.plate ... NOT NULL UNIQUE` being
-- safe only because the table was empty at creation time; here the tables are
-- NOT empty, so NOT NULL must come *after* the backfill, not in the same ALTER).
--
-- A transitional `default_company_id()` function is installed as the column
-- DEFAULT on all 12 tables (step 4b). During this phase there is exactly one
-- company, so any INSERT that omits `company_id` (GORM omits the zero-value;
-- hand-written SQL simply omits the column) lands on Empresa #1 -- the same
-- omit-and-reload pattern `id DEFAULT gen_random_uuid()` already relies on
-- throughout this schema. Zero regression for the existing integration suite,
-- without touching a single application write path (that is Fase 21's job,
-- which also removes/neutralizes this default once every write carries
-- `company_id` from the session).
--
-- users.company_id is the one exception left NULLABLE (not SET NOT NULL in
-- step 4a) -- reserved for the future platform_admin master row (Fase 22),
-- which by definition belongs to no single company.
--
-- refresh_tokens and password_reset_tokens do NOT get a company_id column --
-- they scope via user_id (the user already carries a company).

-- ============================================================
-- Step 1: companies (the tenant root entity) + Empresa #1
-- ============================================================
CREATE TABLE companies (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(255) NOT NULL,
    document   VARCHAR(14),  -- CNPJ/CPF, raw digits (same convention as clients.cpf/employees.cpf) -- optional
    status     VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended')),
    owner_id   UUID REFERENCES users (id),  -- nullable here, set in Step 5 once the owner (admin) exists
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- document is optional (Empresa #1 has none at seed time) but unique when informed.
CREATE UNIQUE INDEX idx_companies_document ON companies (document) WHERE document IS NOT NULL;

-- Empresa #1 = today's single locadora. Literal value, not a Flyway placeholder
-- (locked in 20-CONTEXT.md): the current production data has exactly one tenant
-- and it is seeded here under this fixed name.
INSERT INTO companies (name, document, status) VALUES ('Locadora Principal', NULL, 'active');

-- ============================================================
-- Step 1b: transitional default -- zero-regression bridge for existing writes
-- ============================================================
-- STABLE (not IMMUTABLE): reads from `companies`, which is finite/fixed content
-- for the lifetime of this transitional phase but is still a table read, so it
-- cannot be marked IMMUTABLE. Returns the oldest company, which during this
-- single-tenant transition is always Empresa #1.
--
-- Fase 21 removes/neutralizes this default once every write is required to
-- carry `company_id` from the session -- turning an unscoped write from a
-- silent fallback into Empresa #1 into a loud NOT NULL failure.
CREATE FUNCTION default_company_id() RETURNS uuid
    LANGUAGE sql STABLE AS
$$
SELECT id FROM companies ORDER BY created_at LIMIT 1
$$;

-- ============================================================
-- Step 2: ADD COLUMN company_id (NULLABLE) on the 12 business tables
-- ============================================================
-- NULLABLE for now -- Pitfall 1: NOT NULL here would fail immediately on every
-- table with existing rows, since there is no constant default possible for a
-- brand-new FK column. NOT NULL is applied only in Step 4, after the backfill.
ALTER TABLE users ADD COLUMN company_id UUID;
ALTER TABLE employees ADD COLUMN company_id UUID;
ALTER TABLE clients ADD COLUMN company_id UUID;
ALTER TABLE contracts ADD COLUMN company_id UUID;
ALTER TABLE vehicles ADD COLUMN company_id UUID;
ALTER TABLE vehicle_documents ADD COLUMN company_id UUID;
ALTER TABLE vehicle_tasks ADD COLUMN company_id UUID;
ALTER TABLE maintenances ADD COLUMN company_id UUID;
ALTER TABLE files ADD COLUMN company_id UUID;
ALTER TABLE client_requests ADD COLUMN company_id UUID;
ALTER TABLE notifications ADD COLUMN company_id UUID;
ALTER TABLE audit_logs ADD COLUMN company_id UUID;

-- ============================================================
-- Step 3: backfill -- every existing row (including the current admin in
-- `users`) points at Empresa #1. After this step, zero rows have a NULL
-- company_id in any of the 12 tables (MIG-01 zero-loss).
-- ============================================================
UPDATE users SET company_id = default_company_id();
UPDATE employees SET company_id = default_company_id();
UPDATE clients SET company_id = default_company_id();
UPDATE contracts SET company_id = default_company_id();
UPDATE vehicles SET company_id = default_company_id();
UPDATE vehicle_documents SET company_id = default_company_id();
UPDATE vehicle_tasks SET company_id = default_company_id();
UPDATE maintenances SET company_id = default_company_id();
UPDATE files SET company_id = default_company_id();
UPDATE client_requests SET company_id = default_company_id();
UPDATE notifications SET company_id = default_company_id();
UPDATE audit_logs SET company_id = default_company_id();

-- ============================================================
-- Step 4a: SET NOT NULL on company_id -- all 11 business tables EXCEPT users.
-- users.company_id stays NULLABLE: reserved for the future platform_admin
-- master row (Fase 22), which belongs to no single company.
-- ============================================================
ALTER TABLE employees ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE clients ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE contracts ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE vehicles ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE vehicle_documents ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE vehicle_tasks ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE maintenances ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE files ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE client_requests ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE notifications ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE audit_logs ALTER COLUMN company_id SET NOT NULL;

-- ============================================================
-- Step 4b: install the transitional default on ALL 12 tables (users included).
-- This is what makes GORM's zero-value omission (and hand-written SQL that
-- omits the column) resolve to Empresa #1 -- zero regression for every
-- existing application write path, which only gains session scoping in Fase 21.
-- ============================================================
ALTER TABLE users ALTER COLUMN company_id SET DEFAULT default_company_id();
ALTER TABLE employees ALTER COLUMN company_id SET DEFAULT default_company_id();
ALTER TABLE clients ALTER COLUMN company_id SET DEFAULT default_company_id();
ALTER TABLE contracts ALTER COLUMN company_id SET DEFAULT default_company_id();
ALTER TABLE vehicles ALTER COLUMN company_id SET DEFAULT default_company_id();
ALTER TABLE vehicle_documents ALTER COLUMN company_id SET DEFAULT default_company_id();
ALTER TABLE vehicle_tasks ALTER COLUMN company_id SET DEFAULT default_company_id();
ALTER TABLE maintenances ALTER COLUMN company_id SET DEFAULT default_company_id();
ALTER TABLE files ALTER COLUMN company_id SET DEFAULT default_company_id();
ALTER TABLE client_requests ALTER COLUMN company_id SET DEFAULT default_company_id();
ALTER TABLE notifications ALTER COLUMN company_id SET DEFAULT default_company_id();
ALTER TABLE audit_logs ALTER COLUMN company_id SET DEFAULT default_company_id();

-- ============================================================
-- Step 4c: FK company_id -> companies.id, RESTRICT-on-delete, on all 12 tables
-- (users included, even though nullable). RESTRICT is the locked mitigation
-- for T-20-RESTRICT: a company with data can never be physically deleted --
-- it is suspended via `status='suspended'` instead (matches PADM-03, Fase 22).
-- ============================================================
ALTER TABLE users ADD CONSTRAINT fk_users_company FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE RESTRICT;
ALTER TABLE employees ADD CONSTRAINT fk_employees_company FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE RESTRICT;
ALTER TABLE clients ADD CONSTRAINT fk_clients_company FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE RESTRICT;
ALTER TABLE contracts ADD CONSTRAINT fk_contracts_company FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE RESTRICT;
ALTER TABLE vehicles ADD CONSTRAINT fk_vehicles_company FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE RESTRICT;
ALTER TABLE vehicle_documents ADD CONSTRAINT fk_vehicle_documents_company FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE RESTRICT;
ALTER TABLE vehicle_tasks ADD CONSTRAINT fk_vehicle_tasks_company FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE RESTRICT;
ALTER TABLE maintenances ADD CONSTRAINT fk_maintenances_company FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE RESTRICT;
ALTER TABLE files ADD CONSTRAINT fk_files_company FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE RESTRICT;
ALTER TABLE client_requests ADD CONSTRAINT fk_client_requests_company FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE RESTRICT;
ALTER TABLE notifications ADD CONSTRAINT fk_notifications_company FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE RESTRICT;
ALTER TABLE audit_logs ADD CONSTRAINT fk_audit_logs_company FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE RESTRICT;

-- ============================================================
-- Step 4d: swap the 3 global uniques for per-company composite uniques (TEN-04).
-- Constraint names below were confirmed live against a Postgres 17-alpine
-- container with V1..V19 applied (`SELECT conname FROM pg_constraint`) before
-- writing this migration -- they follow the standard Postgres auto-naming
-- convention `<table>_<column>_key` for an inline `UNIQUE` (V3 employees.cpf,
-- V4 clients.cpf, V5 vehicles.plate), with no divergence found (Pitfall 3).
-- ============================================================
ALTER TABLE vehicles DROP CONSTRAINT vehicles_plate_key;
CREATE UNIQUE INDEX idx_vehicles_company_plate ON vehicles (company_id, plate);

ALTER TABLE clients DROP CONSTRAINT clients_cpf_key;
CREATE UNIQUE INDEX idx_clients_company_cpf ON clients (company_id, cpf);

ALTER TABLE employees DROP CONSTRAINT employees_cpf_key;
CREATE UNIQUE INDEX idx_employees_company_cpf ON employees (company_id, cpf);

-- ------------------------------------------------------------
-- Step 4e: deliberately NOT touched (documented, not omitted):
-- - users_email_key: email uniqueness stays global in this phase -- composing
--   it with company_id is AUTHT-02, deferred to Fase 25.
-- - files_r2_key_key: r2_key is a physical object-storage key, globally unique
--   by design (ADR-009) -- not a tenant-scoped business identifier.
-- - refresh_tokens / password_reset_tokens uniques: these tables never gain a
--   company_id column (they scope via user_id).
-- - idx_contracts_one_active_per_vehicle (RN01): vehicle_id already pins a
--   contract to exactly one company (a vehicle is never shared across
--   companies in this phase), so this partial unique index stays correct
--   as-is -- adding company_id here would be redundant, not incorrect
--   (confirmed, Pitfall 4).
-- - idx_notifications_dedup (V19): already scoped via contract_id, which in
--   turn is scoped via vehicle_id -> company_id, same reasoning as RN01.
-- ------------------------------------------------------------

-- ============================================================
-- Step 5: close the loop -- the current admin becomes the owner of Empresa #1
-- (MIG-02). Looked up by role='admin' (not by email, which is a Flyway
-- placeholder substituted per-environment) -- the only stable invariant across
-- dev/test/prod until this phase, since there is no public signup yet (D-02).
-- ============================================================
UPDATE companies
SET owner_id = (SELECT id FROM users WHERE role = 'admin' LIMIT 1)
WHERE owner_id IS NULL;
