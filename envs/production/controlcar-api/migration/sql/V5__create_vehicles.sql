-- V5: vehicles (VEICULO)
-- `status` enum CHECK covers the fleet-status query (RF04). RN07 soft-delete via `active`,
-- distinct from `status` (a rented/available/inactive vehicle can still be `active=true`).
CREATE TABLE vehicles (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plate      VARCHAR(10) NOT NULL UNIQUE,
    type       VARCHAR(30) NOT NULL,
    brand      VARCHAR(60),
    model      VARCHAR(60),
    year       INTEGER,
    color      VARCHAR(30),
    current_km INTEGER NOT NULL DEFAULT 0,
    status     VARCHAR(20) NOT NULL DEFAULT 'available'
               CHECK (status IN ('available', 'rented', 'maintenance', 'inactive')),
    active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

CREATE INDEX idx_vehicles_active ON vehicles (active);
CREATE INDEX idx_vehicles_status ON vehicles (status);
