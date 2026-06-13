-- Fix user_has_business_access RLS recursion issues by converting it from LANGUAGE sql to LANGUAGE plpgsql.
-- This prevents the PostgreSQL query planner from inlining the function and stripping its SECURITY DEFINER context.

CREATE OR REPLACE FUNCTION public.user_has_business_access(p_business_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
  v_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM public.business_members
    WHERE business_id = p_business_id
      AND user_id = auth.uid()
      AND is_active = TRUE
  ) INTO v_exists;
  
  RETURN COALESCE(v_exists, FALSE);
END;
$$;
