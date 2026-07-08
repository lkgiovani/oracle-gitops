-- V1: extensions required by the physical data model.
-- pgcrypto provides gen_random_uuid(), used as the DEFAULT for every table's UUID
-- primary key (D-02). This MUST be the first-numbered migration so the function
-- exists before any CREATE TABLE that references it (Pitfall 1).
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
