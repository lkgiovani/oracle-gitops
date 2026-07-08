-- V10: files (ARQUIVO — W1 addition, missing from the stale DER v1.0; required by
-- ADR-009/RNF11: only metadata lives in Postgres, the actual object sits in Cloudflare R2)
-- `owner_type`/`owner_id` is a polymorphic reference (client/vehicle/contract/vehicle_task)
-- with no FK constraint possible across polymorphic targets — validated in the app
-- layer in Phase 5.
CREATE TABLE files (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    r2_key        VARCHAR(500) NOT NULL UNIQUE,
    original_name VARCHAR(255) NOT NULL,
    content_type  VARCHAR(100) NOT NULL,
    size_bytes    BIGINT NOT NULL,
    uploaded_by   UUID REFERENCES users (id),
    owner_type    VARCHAR(30) NOT NULL,
    owner_id      UUID NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_files_owner ON files (owner_type, owner_id);
