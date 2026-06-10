-- ============================================================
-- SMART SAOJI — Admin Panel SQL Migration
-- Run this in Supabase SQL Editor AFTER the main schema.sql
-- ============================================================

-- ─── 1. Add is_admin column to user_profiles ─────────────────
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT FALSE;

-- ─── 2. Create your first admin user ─────────────────────────
-- Replace 'admin@smartsaoji.com' with the actual admin email
-- Make sure this user already exists in Supabase Auth first!
UPDATE user_profiles
  SET is_admin = TRUE
  WHERE email = 'yadavakash2290@gmail.com';

-- ─── 3. Admin Stats RPC function ─────────────────────────────
-- Called by admin dashboard. Uses SECURITY DEFINER so it can
-- read across all businesses regardless of RLS policies.
CREATE OR REPLACE FUNCTION admin_get_stats()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result JSON;
BEGIN
  -- Only admins can call this
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() AND is_admin = TRUE
  ) THEN
    RAISE EXCEPTION 'Access denied: not an admin';
  END IF;

  SELECT json_build_object(
    'total_users',            (SELECT COUNT(*) FROM user_profiles),
    'total_businesses',       (SELECT COUNT(*) FROM businesses),
    'active_trials',          (SELECT COUNT(*) FROM subscriptions WHERE status = 'trial_active'),
    'active_subscriptions',   (SELECT COUNT(*) FROM subscriptions WHERE status = 'active'),
    'expired_subscriptions',  (SELECT COUNT(*) FROM subscriptions WHERE status IN ('trial_expired', 'expired')),
    'total_revenue',          COALESCE((SELECT SUM(amount) FROM payments WHERE status = 'completed'), 0)
  ) INTO result;

  RETURN result;
END;
$$;

-- ─── 4. Grant admin full access via RLS bypass policies ───────
-- To avoid infinite recursion in RLS, we use a SECURITY DEFINER function
CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  admin_flag BOOLEAN;
BEGIN
  SELECT is_admin INTO admin_flag 
  FROM user_profiles 
  WHERE id = auth.uid();
  RETURN COALESCE(admin_flag, FALSE);
END;
$$;

-- Allow admins to read/write ALL user_profiles
DROP POLICY IF EXISTS "admin_user_profiles_all" ON user_profiles;
CREATE POLICY "admin_user_profiles_all" ON user_profiles
  USING (is_admin_user())
  WITH CHECK (is_admin_user());

-- Allow admins to read/write ALL businesses
DROP POLICY IF EXISTS "admin_businesses_all" ON businesses;
CREATE POLICY "admin_businesses_all" ON businesses
  USING (is_admin_user())
  WITH CHECK (is_admin_user());

-- Allow admins to read/write ALL subscriptions
DROP POLICY IF EXISTS "admin_subscriptions_all" ON subscriptions;
CREATE POLICY "admin_subscriptions_all" ON subscriptions
  USING (is_admin_user())
  WITH CHECK (is_admin_user());

-- Allow admins to read ALL payments
DROP POLICY IF EXISTS "admin_payments_all" ON payments;
CREATE POLICY "admin_payments_all" ON payments
  USING (is_admin_user());

-- ─── 5. Business sessions table (for admin to view) ──────────
CREATE TABLE IF NOT EXISTS business_sessions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id   TEXT NOT NULL,
  last_active TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(business_id, device_id)
);

ALTER TABLE business_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "own_sessions" ON business_sessions;
CREATE POLICY "own_sessions" ON business_sessions
  USING (user_has_business_access(business_id));

DROP POLICY IF EXISTS "admin_sessions_all" ON business_sessions;
CREATE POLICY "admin_sessions_all" ON business_sessions
  USING (is_admin_user());

-- ============================================================
-- DONE — Now:
-- 1. Go to Supabase Auth → find the admin user
-- 2. Set is_admin = TRUE on their user_profiles row (done above)
-- 3. Use their credentials to login at /admin/login in the app
-- ============================================================
