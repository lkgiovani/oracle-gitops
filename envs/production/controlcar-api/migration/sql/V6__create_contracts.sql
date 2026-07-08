-- V6: contracts (CONTRATO)
-- W1 fix: employee_id FK (the salesperson responsible, RN08) was missing from the
-- stale DER v1.0 and is added here as NOT NULL.
-- RN01: at most one ACTIVE contract per vehicle at a time, enforced by a partial
-- unique index scoped to status='active' (not a plain UNIQUE, since a vehicle can
-- accumulate many closed/overdue contracts over its lifetime).
-- RN05: return_km must be >= pickup_km once the contract records a return, enforced
-- by a CHECK (NULL return_km means "not yet returned" and is allowed).
CREATE TABLE contracts (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id   UUID NOT NULL REFERENCES clients (id),
    vehicle_id  UUID NOT NULL REFERENCES vehicles (id),
    employee_id UUID NOT NULL REFERENCES employees (id),
    type        VARCHAR(20) NOT NULL CHECK (type IN ('daily', 'weekly', 'monthly')),
    start_date  DATE NOT NULL,
    end_date    DATE NOT NULL,
    amount      DECIMAL(10, 2) NOT NULL,
    status      VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'closed', 'overdue')),
    pickup_km   INTEGER NOT NULL,
    return_km   INTEGER,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_return_km CHECK (return_km IS NULL OR return_km >= pickup_km)
);

-- RN01: partial unique index — only one row per vehicle_id can have status='active'.
CREATE UNIQUE INDEX idx_contracts_one_active_per_vehicle
    ON contracts (vehicle_id)
    WHERE status = 'active';

CREATE INDEX idx_contracts_client_id ON contracts (client_id);
CREATE INDEX idx_contracts_vehicle_id ON contracts (vehicle_id);
CREATE INDEX idx_contracts_employee_id ON contracts (employee_id);
