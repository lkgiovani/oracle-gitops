-- V17: supporting index for the "current/expiring document per type" reads (RF11).
-- The DISTINCT ON (vehicle_id, type) ... ORDER BY vehicle_id, type, due_date DESC, id DESC
-- pattern (vehiclespersistence.GORMVehicleDocumentRepository) is far cheaper when a
-- composite index already orders rows the way the DISTINCT ON needs (RNF07 < 3s).
CREATE INDEX idx_vehicle_documents_current
    ON vehicle_documents (vehicle_id, type, due_date DESC, id DESC);
