-- V13: audit_logs (LOG_AUDITORIA)
-- Feeds RF17/RNF05. Insert-only: rows are never updated or deleted, so there is no
-- `active`/soft-delete column here (unlike users/clients/vehicles/employees, RN07
-- does not apply to an audit trail).
CREATE TABLE audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES users (id),
    entity      VARCHAR(50) NOT NULL,
    action      VARCHAR(20) NOT NULL,
    details     JSONB,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_entity ON audit_logs (entity);
CREATE INDEX idx_audit_logs_occurred_at ON audit_logs (occurred_at);
