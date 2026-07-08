-- V11: client_requests (SOLICITACAO_CLIENTE)
-- Feeds RF16 (portal: request renewal / report an issue). contract_id is optional
-- (an "issue" request may not reference a specific contract).
CREATE TABLE client_requests (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id   UUID NOT NULL REFERENCES clients (id),
    contract_id UUID REFERENCES contracts (id),
    type        VARCHAR(20) NOT NULL CHECK (type IN ('renewal', 'issue')),
    description TEXT,
    status      VARCHAR(20) NOT NULL DEFAULT 'open',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_client_requests_client_id ON client_requests (client_id);
