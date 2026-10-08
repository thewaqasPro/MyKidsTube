-- Migration 0007: Align Passkey table columns with Better Auth Drizzle adapter
ALTER TABLE passkey ADD COLUMN credential_id TEXT;
ALTER TABLE passkey ADD COLUMN aaguid TEXT;
UPDATE passkey SET credential_id = credential_i_d WHERE credential_id IS NULL AND credential_i_d IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_passkey_credential_id ON passkey (credential_id);
CREATE INDEX IF NOT EXISTS idx_passkey_user_id ON passkey (user_id);
