-- V14: refresh_tokens (RF12/RNF10 — refresh rotation com theft detection, D-05/D-07)
-- Estilo de V13: UUID PK gen_random_uuid(), FK para users(id). user_id e sempre UUID,
-- nunca um inteiro (usersdomain.User.ID e uuid.UUID — ver 02-RESEARCH.md Pitfall 2).
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users (id),
    user_email VARCHAR(255) NOT NULL,
    device_id VARCHAR(255) NOT NULL,
    jti VARCHAR(255) NOT NULL UNIQUE,
    family_id UUID NOT NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    used BOOLEAN NOT NULL DEFAULT FALSE,
    used_at TIMESTAMPTZ,
    rotated_from UUID,
    revoked_at TIMESTAMPTZ,
    user_agent VARCHAR(500),
    ip_address VARCHAR(45)
);

CREATE INDEX idx_refresh_tokens_family_id ON refresh_tokens (family_id);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens (user_id);
