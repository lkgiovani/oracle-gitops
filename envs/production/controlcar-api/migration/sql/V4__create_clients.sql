-- V4: clients (CLIENTE)
-- `user_id` is optional: a client may exist before portal access is granted.
-- `lgpd_consent` is a column-only concern this phase (RNF02 policy wiring is later).
-- RN07 soft-delete via `active`.
CREATE TABLE clients (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID REFERENCES users (id),
    name                  VARCHAR(255) NOT NULL,
    cpf                   VARCHAR(14) NOT NULL UNIQUE,
    driver_license        VARCHAR(20),
    driver_license_expiry DATE,
    phone                 VARCHAR(20),
    email                 VARCHAR(255),
    address               VARCHAR(255),
    lgpd_consent          BOOLEAN NOT NULL DEFAULT FALSE,
    active                BOOLEAN NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ
);

CREATE INDEX idx_clients_active ON clients (active);
CREATE INDEX idx_clients_user_id ON clients (user_id);
