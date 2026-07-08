-- V3: employees (FUNCIONARIO — W1 addition, missing from the stale DER v1.0)
-- Required by RF18 and referenced by contracts.employee_id (RN08 salesperson) and
-- vehicle_tasks.employee_id. RN07 soft-delete via `active`.
CREATE TABLE employees (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID REFERENCES users (id),
    name       VARCHAR(255) NOT NULL,
    cpf        VARCHAR(14) NOT NULL UNIQUE,
    role       VARCHAR(20) NOT NULL CHECK (role IN ('manager', 'salesperson', 'operational')),
    active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

CREATE INDEX idx_employees_active ON employees (active);
CREATE INDEX idx_employees_user_id ON employees (user_id);
