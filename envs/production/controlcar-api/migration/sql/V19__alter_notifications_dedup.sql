-- V19: alter notifications to add the RF09 scheduler dedup key.
-- V12 created notifications without contract_id, so a client with two
-- contracts nearing expiry at the same time cannot be distinguished by
-- (client_id, type) alone. This adds contract_id and a PARTIAL unique dedup
-- index below — mirroring RN01's own partial-unique-index precedent in
-- migrations/V6__create_contracts.sql — as the real dedup guarantee. The
-- scheduler (08-07) relies on `INSERT ... ON CONFLICT ... DO NOTHING
-- RETURNING id` against this index; a milestone is never notified twice,
-- even across overlapping sweeps or a crash-restart mid-sweep (RESEARCH §2).
-- contract_id is nullable so any legacy/non-contract notification is exempt
-- from the dedup index via the partial WHERE clause.
ALTER TABLE notifications ADD COLUMN contract_id UUID REFERENCES contracts (id);

CREATE UNIQUE INDEX idx_notifications_dedup
    ON notifications (contract_id, type)
    WHERE contract_id IS NOT NULL;
