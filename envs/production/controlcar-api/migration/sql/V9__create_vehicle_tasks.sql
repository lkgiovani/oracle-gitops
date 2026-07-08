-- V9: vehicle_tasks (TAREFA_VEICULO — W1 addition, missing from the stale DER v1.0)
-- Required by RF19 (operational tasks: preparation/cleaning/inspection/pickup/delivery)
-- and RN08 (task records the responsible employee + completion timestamp).
-- contract_id is optional (a task may or may not be tied to a specific contract).
-- Row-level authorization (RN09: operational staff sees only assigned tasks) is
-- enforced in the application layer in a later phase, not in the schema.
CREATE TABLE vehicle_tasks (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id   UUID NOT NULL REFERENCES vehicles (id),
    employee_id  UUID NOT NULL REFERENCES employees (id),
    contract_id  UUID REFERENCES contracts (id),
    type         VARCHAR(20) NOT NULL CHECK (type IN ('preparation', 'cleaning', 'inspection', 'pickup', 'delivery')),
    status       VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
    completed_at TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_vehicle_tasks_vehicle_id ON vehicle_tasks (vehicle_id);
CREATE INDEX idx_vehicle_tasks_employee_id ON vehicle_tasks (employee_id);
CREATE INDEX idx_vehicle_tasks_status ON vehicle_tasks (status);
