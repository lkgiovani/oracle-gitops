-- V24: purpose column on password_reset_tokens (defense-in-depth, CR-01 gap
-- closure, Plano 23-08). Confirmed via `ls migrations/ | sort -V | tail` that
-- V24 is the next free migration number (V23 was the last applied).
--
-- password_reset_tokens is shared by THREE flows -- SendPasswordReset
-- ('reset'), SendInvite ('invite') and SendEmailConfirmation
-- ('email_confirm', Phase 23) -- and, until this migration, had no column
-- distinguishing which flow issued a given row. ConfirmEmailUseCase
-- (onboarding module) consumed ANY unexpired/unused row via a purpose-blind
-- lookup, so a 'reset' or 'invite' token could be replayed against the
-- public /onboarding/confirm-email endpoint to flip companies.status/
-- users.active (CR-01 -- bypasses PADM-03 company suspension).
--
-- DEFAULT 'reset' backfills every pre-existing row implicitly (no data
-- migration statement needed -- Postgres applies a constant DEFAULT to
-- existing rows on ADD COLUMN without a table rewrite, PG11+): every row
-- that existed before this migration was issued by either the reset or the
-- invite flow (email_confirm did not exist before Phase 23). Labeling
-- pre-existing invite-purpose rows as 'reset' is harmless -- their consumer
-- (authusecases.ResetPasswordUseCase, via GetPasswordResetByToken, NOT the
-- new purpose-filtered lookup) never reads this column and continues
-- accepting both purposes unchanged (zero regression, Fase 02 flows
-- untouched).
ALTER TABLE password_reset_tokens ADD COLUMN purpose text NOT NULL DEFAULT 'reset';
ALTER TABLE password_reset_tokens ADD CONSTRAINT password_reset_tokens_purpose_check
    CHECK (purpose IN ('reset', 'invite', 'email_confirm'));
