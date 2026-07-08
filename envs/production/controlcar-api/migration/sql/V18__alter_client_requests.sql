-- V18: alter client_requests to enforce D-05/D-06/D-07 (RF16 requests data layer)
-- D-06: contract_id becomes mandatory (safe — table is empty, no existing rows).
-- D-07: response TEXT is the staff -> client reply, nullable until answered.
-- D-05: status is a linear enum (open -> in_review -> resolved, no reopen/skip),
-- enforced here as a schema-level backstop mirroring the existing type CHECK
-- on this same table (V11).
ALTER TABLE client_requests ALTER COLUMN contract_id SET NOT NULL;

ALTER TABLE client_requests ADD COLUMN response TEXT;

ALTER TABLE client_requests ADD CONSTRAINT chk_client_requests_status CHECK (status IN ('open', 'in_review', 'resolved'));
