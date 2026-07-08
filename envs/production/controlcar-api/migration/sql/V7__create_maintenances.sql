-- V7: maintenances (MANUTENCAO)
-- Feeds RF07 (register maintenance) and RF08 (accumulated cost per vehicle/period).
CREATE TABLE maintenances (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id  UUID NOT NULL REFERENCES vehicles (id),
    date        DATE NOT NULL,
    type        VARCHAR(50) NOT NULL,
    description TEXT,
    cost        DECIMAL(10, 2) NOT NULL,
    workshop    VARCHAR(255),
    recorded_km INTEGER NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_maintenances_vehicle_id ON maintenances (vehicle_id);
CREATE INDEX idx_maintenances_date ON maintenances (date);
