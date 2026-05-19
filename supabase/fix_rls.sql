-- Fix for infinite recursion in RLS policies

-- 1. Create a SECURITY DEFINER function to check admin status
CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  admin_flag BOOLEAN;
BEGIN
  -- Check if the current user has is_admin = true
  SELECT is_admin INTO admin_flag 
  FROM user_profiles 
  WHERE id = auth.uid();
  
  RETURN COALESCE(admin_flag, FALSE);
END;
$$;

-- 2. Drop the recursive policies
DROP POLICY IF EXISTS "admin_user_profiles_all" ON user_profiles;
DROP POLICY IF EXISTS "admin_businesses_all" ON businesses;
DROP POLICY IF EXISTS "admin_subscriptions_all" ON subscriptions;
DROP POLICY IF EXISTS "admin_payments_all" ON payments;
DROP POLICY IF EXISTS "admin_sessions_all" ON business_sessions;

-- 3. Recreate them using the new non-recursive function
CREATE POLICY "admin_user_profiles_all" ON user_profiles
  USING (is_admin_user())
  WITH CHECK (is_admin_user());

CREATE POLICY "admin_businesses_all" ON businesses
  USING (is_admin_user())
  WITH CHECK (is_admin_user());

CREATE POLICY "admin_subscriptions_all" ON subscriptions
  USING (is_admin_user())
  WITH CHECK (is_admin_user());

CREATE POLICY "admin_payments_all" ON payments
  USING (is_admin_user());

CREATE POLICY "admin_sessions_all" ON business_sessions
  USING (is_admin_user());
