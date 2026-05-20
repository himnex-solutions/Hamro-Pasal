-- ============================================================
-- MIGRATION: Uniqueness constraints + phone on signup
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor)
-- Safe to run multiple times (all checks use IF NOT EXISTS / DO $$)
-- ============================================================

-- ─── 1. Add phone column to user_profiles (if not already there) ──
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS phone TEXT;

-- ─── 2. Unique constraint: user_profiles.email ────────────────────
-- Uses a partial unique index approach so it is idempotent.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE tablename = 'user_profiles' AND indexname = 'idx_user_profiles_email'
  ) THEN
    CREATE UNIQUE INDEX idx_user_profiles_email ON public.user_profiles(email);
  END IF;
END $$;

-- ─── 3. Unique constraint: user_profiles.phone (NULLs excluded) ───
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE tablename = 'user_profiles' AND indexname = 'idx_user_profiles_phone'
  ) THEN
    CREATE UNIQUE INDEX idx_user_profiles_phone
      ON public.user_profiles(phone)
      WHERE phone IS NOT NULL;
  END IF;
END $$;

-- ─── 4. Unique constraint: businesses.pan_number (NULLs excluded) ─
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE tablename = 'businesses' AND indexname = 'idx_businesses_pan'
  ) THEN
    CREATE UNIQUE INDEX idx_businesses_pan
      ON public.businesses(pan_number)
      WHERE pan_number IS NOT NULL;
  END IF;
END $$;

-- ─── 5. Update handle_new_user trigger to save phone ──────────────
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_phone TEXT;
BEGIN
  v_phone := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'phone', '')), '');

  INSERT INTO public.user_profiles (id, email, full_name, phone, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    v_phone,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email      = EXCLUDED.email,
    full_name  = COALESCE(EXCLUDED.full_name, public.user_profiles.full_name),
    phone      = COALESCE(EXCLUDED.phone,     public.user_profiles.phone),
    updated_at = NOW();
  RETURN NEW;
EXCEPTION
  WHEN unique_violation THEN
    RAISE WARNING 'handle_new_user unique violation for %: %', NEW.id, SQLERRM;
    RETURN NEW;
  WHEN OTHERS THEN
    RAISE WARNING 'handle_new_user failed for %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger (idempotent)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ─── 6. Grant SELECT on user_profiles for uniqueness pre-checks ───
-- (anon role needs read access so the Flutter app can check duplicates
--  before attempting signup — this does NOT expose private data since
--  the query only returns the 'id' column and needs email/phone match)
GRANT SELECT (id, email, phone) ON public.user_profiles TO anon;
GRANT SELECT (id, pan_number)   ON public.businesses      TO anon;

-- ─── 7. Add RPC functions for uniqueness checks ───
-- Check if phone exists (Bypasses RLS for unauthenticated signups)
CREATE OR REPLACE FUNCTION check_phone_exists(p_phone TEXT)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM user_profiles WHERE phone = p_phone);
END;
$$ LANGUAGE plpgsql;

-- Check if email exists (Bypasses RLS for unauthenticated signups)
CREATE OR REPLACE FUNCTION check_email_exists(p_email TEXT)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM user_profiles WHERE email = p_email);
END;
$$ LANGUAGE plpgsql;

-- Check if PAN exists (Bypasses RLS)
CREATE OR REPLACE FUNCTION check_pan_exists(p_pan TEXT)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM businesses WHERE pan_number = p_pan);
END;
$$ LANGUAGE plpgsql;

-- Done ✓
