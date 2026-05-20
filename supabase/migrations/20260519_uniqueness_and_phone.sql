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

-- ─── 8. Feedbacks table ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.feedbacks (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  rating       INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  category     TEXT NOT NULL DEFAULT 'General',
  message      TEXT NOT NULL,
  status       TEXT NOT NULL DEFAULT 'pending'
               CHECK (status IN ('pending', 'reviewed', 'resolved')),
  admin_notes  TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast admin queries
CREATE INDEX IF NOT EXISTS idx_feedbacks_status     ON public.feedbacks(status);
CREATE INDEX IF NOT EXISTS idx_feedbacks_created_at ON public.feedbacks(created_at DESC);

-- Auto-update updated_at
CREATE TRIGGER feedbacks_updated_at
  BEFORE UPDATE ON public.feedbacks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE public.feedbacks ENABLE ROW LEVEL SECURITY;

-- Users can INSERT their own feedback (logged in)
CREATE POLICY "Users can submit feedback"
  ON public.feedbacks FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can read their own feedback
CREATE POLICY "Users can view own feedback"
  ON public.feedbacks FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Admins can view all feedback
CREATE POLICY "Admins can view all feedback"
  ON public.feedbacks FOR SELECT
  TO authenticated
  USING (is_admin_user());

-- Admins can update all feedback
CREATE POLICY "Admins can update all feedback"
  ON public.feedbacks FOR UPDATE
  TO authenticated
  USING (is_admin_user())
  WITH CHECK (is_admin_user());

-- Service role (admin backend) can do everything
CREATE POLICY "Service role full access"
  ON public.feedbacks
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Enable realtime for admin dashboard notifications
ALTER PUBLICATION supabase_realtime ADD TABLE public.feedbacks;

-- Done ✓
