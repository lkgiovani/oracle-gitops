-- V8: vehicle_documents (DOCUMENTO_VEICULO)
-- Feeds RF11 (IPVA/licensing/insurance tracking with due dates).
CREATE TABLE vehicle_documents (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL REFERENCES vehicles (id),
    type       VARCHAR(50) NOT NULL,
    due_date   DATE NOT NULL,
    notes      TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_vehicle_documents_vehicle_id ON vehicle_documents (vehicle_id);
CREATE INDEX idx_vehicle_documents_due_date ON vehicle_documents (due_date);
