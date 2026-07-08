-- V16: seed do admin inicial (D-02 — nao ha cadastro publico, precisa existir um
-- admin no primeiro deploy). Os placeholders ${admin_email}/${admin_password} sao
-- substituidos pelo Flyway em dev/deploy (docker-compose.yaml passa
-- -placeholders.admin_email/-placeholders.admin_password) e, nos testes de
-- integracao, pelo harness em setup_test.go (strings.ReplaceAll antes de aplicar
-- o SQL). A senha nunca e gravada em texto puro: pgcrypto's crypt()/gen_salt('bf',12)
-- gera um hash bcrypt padrao ($2a$), byte-a-byte compativel com
-- bcrypt.CompareHashAndPassword do Go (Assumption A1, resolvida/testada em
-- seed_admin_test.go). ON CONFLICT evita sobrescrever o hash em reaplicacoes.
INSERT INTO users (email, password_hash, role, active)
VALUES (
    '${admin_email}',
    crypt('${admin_password}', gen_salt('bf', 12)),
    'admin',
    TRUE
)
ON CONFLICT (email) DO NOTHING;
