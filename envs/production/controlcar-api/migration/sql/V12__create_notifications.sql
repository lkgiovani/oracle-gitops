-- V12: notifications (NOTIFICACAO)
-- Feeds RF15 (contract expiry / return confirmation emails). `channel` is scoped to
-- email in v1 (ADR-005 / SMS-push out of scope), default 'email'.
CREATE TABLE notifications (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id  UUID NOT NULL REFERENCES clients (id),
    type       VARCHAR(50) NOT NULL,
    channel    VARCHAR(20) NOT NULL DEFAULT 'email',
    content    TEXT NOT NULL,
    sent_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_client_id ON notifications (client_id);
