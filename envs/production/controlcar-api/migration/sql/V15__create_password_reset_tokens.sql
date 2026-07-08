-- V15: password_reset_tokens (RF12 — D-08 reset de senha + D-10 convite "defina sua
-- senha"). Uma unica tabela serve os dois fluxos, diferindo so no TTL aplicado pela
-- application layer (Pitfall 5 do RESEARCH) — nao ha coluna "kind", o app decide o TTL
-- na hora de criar o token (1h para reset, 24h para convite).
CREATE TABLE password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users (id),
    email VARCHAR(255) NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    used BOOLEAN NOT NULL DEFAULT FALSE,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_password_reset_tokens_user_id ON password_reset_tokens (user_id);
CREATE INDEX idx_password_reset_tokens_email ON password_reset_tokens (email);
