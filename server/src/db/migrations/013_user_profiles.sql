-- Migration 013 originally introduced a richer user_profiles schema with a
-- `stellar_address` column. Earlier migrations already created `user_profiles`
-- with `address` as the primary key (see 009_user_profiles.sql).
--
-- This migration is written to be idempotent across both schemas so CI
-- migrations never fail on "column does not exist".

-- Create the v2 schema only if the table does not exist at all.
-- If it exists (from 009), we avoid destructive changes.
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stellar_address TEXT NOT NULL UNIQUE REFERENCES linked_wallets(stellar_address) ON DELETE CASCADE,
    display_name TEXT,
    bio TEXT,
    avatar_url TEXT,
    avatar_cid TEXT,
    social_links JSONB DEFAULT '{}'::jsonb,
    reputation_rank INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create whichever lookup index matches the active schema.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'user_profiles' AND column_name = 'stellar_address'
    ) THEN
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_user_profiles_stellar_address ON user_profiles (stellar_address)';
    ELSIF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'user_profiles' AND column_name = 'address'
    ) THEN
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_user_profiles_address ON user_profiles (address)';
    END IF;
END $$;

-- Display name search index is valid in both schemas (if the column exists).
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'user_profiles' AND column_name = 'display_name'
    ) THEN
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_user_profiles_display_name ON user_profiles (display_name) WHERE display_name IS NOT NULL';
    END IF;
END $$;

-- Trigger to update updated_at on modification (only when the column exists).
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'user_profiles' AND column_name = 'updated_at'
    ) THEN
        EXECUTE $fn$
            CREATE OR REPLACE FUNCTION update_user_profiles_updated_at()
            RETURNS TRIGGER AS $$
            BEGIN
                NEW.updated_at = CURRENT_TIMESTAMP;
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        $fn$;

        EXECUTE 'DROP TRIGGER IF EXISTS trigger_user_profiles_updated_at ON user_profiles';
        EXECUTE 'CREATE TRIGGER trigger_user_profiles_updated_at
            BEFORE UPDATE ON user_profiles
            FOR EACH ROW
            EXECUTE FUNCTION update_user_profiles_updated_at()';
    END IF;
END $$;
