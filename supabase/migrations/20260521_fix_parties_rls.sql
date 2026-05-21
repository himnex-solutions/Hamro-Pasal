-- ============================================================
-- MIGRATION: Fix parties table RLS (simplified - no user_id needed)
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

-- ─── 1. Drop ALL existing parties policies ────────────────────
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies 
    WHERE tablename = 'parties' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.parties', pol.policyname);
  END LOOP;
END $$;

-- ─── 2. Ensure RLS is enabled ────────────────────────────────
ALTER TABLE public.parties ENABLE ROW LEVEL SECURITY;

-- ─── 3. Simple policy: user owns the business → full access ──
-- INSERT: the business must belong to the authenticated user
CREATE POLICY "parties_insert_owner"
  ON public.parties FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.businesses
      WHERE businesses.id = parties.business_id
        AND businesses.owner_id = auth.uid()
    )
  );

-- SELECT: user can see parties from their own businesses
CREATE POLICY "parties_select_owner"
  ON public.parties FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.businesses
      WHERE businesses.id = parties.business_id
        AND businesses.owner_id = auth.uid()
    )
  );

-- UPDATE: user can update parties in their own businesses
CREATE POLICY "parties_update_owner"
  ON public.parties FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.businesses
      WHERE businesses.id = parties.business_id
        AND businesses.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.businesses
      WHERE businesses.id = parties.business_id
        AND businesses.owner_id = auth.uid()
    )
  );

-- DELETE: user can delete parties in their own businesses
CREATE POLICY "parties_delete_owner"
  ON public.parties FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.businesses
      WHERE businesses.id = parties.business_id
        AND businesses.owner_id = auth.uid()
    )
  );

-- Service role bypass
CREATE POLICY "parties_service_role"
  ON public.parties
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Done ✓
