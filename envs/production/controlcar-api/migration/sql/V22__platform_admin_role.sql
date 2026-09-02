-- V22: platform_admin role (ROLE-01, AUTHT-03) -- 5o valor do CHECK de users.role
-- + seed idempotente do primeiro master (company_id NULL, conta separada do
-- admin da Empresa #1). Nenhuma mudanca de schema para companies.document:
-- idx_companies_document (unique parcial) ja existe desde a V20.
--
-- Nome real da constraint confirmado ao vivo (SELECT conname FROM pg_constraint
-- WHERE conrelid='users'::regclass AND contype='c';) antes de escrever esta
-- migration: users_role_check (convencao padrao do Postgres para CHECK de
-- coluna sem nome explicito, mesma disciplina de verificacao da V20).
ALTER TABLE users DROP CONSTRAINT users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check
    CHECK (role IN ('admin', 'salesperson', 'operational', 'client', 'platform_admin'));

-- Seed idempotente do master -- mesmo padrao exato da V16 (pgcrypto
-- crypt()/gen_salt('bf',12), ON CONFLICT (email) DO NOTHING). Os placeholders
-- ${platform_admin_email}/${platform_admin_password} sao substituidos pelo
-- Flyway em dev/deploy (docker-compose.yaml passa
-- -placeholders.platform_admin_email/-placeholders.platform_admin_password) e,
-- nos testes de integracao, pelo harness em setup_test.go. company_id
-- EXPLICITAMENTE NULL (coluna nullable desde a V20, sem DEFAULT desde a V21) --
-- documenta a intencao "master sem empresa" em vez de depender de omissao.
INSERT INTO users (email, password_hash, role, active, company_id)
VALUES (
    '${platform_admin_email}',
    crypt('${platform_admin_password}', gen_salt('bf', 12)),
    'platform_admin',
    TRUE,
    NULL
)
ON CONFLICT (email) DO NOTHING;
