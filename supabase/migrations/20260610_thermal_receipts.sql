-- ============================================================
-- MIGRATION: Thermal Print Receipt History Table
-- ============================================================

CREATE TABLE IF NOT EXISTS public.thermal_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL,
    receipt_number VARCHAR(100) NOT NULL,
    title VARCHAR(100) NOT NULL DEFAULT 'TAX INVOICE',
    subtotal NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    discount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    tax NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    total NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    payment_method VARCHAR(50) NOT NULL DEFAULT 'Cash',
    footer TEXT,
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Enable RLS
ALTER TABLE public.thermal_receipts ENABLE ROW LEVEL SECURITY;

-- Select policy: User must be a member of the business
CREATE POLICY "thermal_receipts_select_members"
  ON public.thermal_receipts FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.business_members
      WHERE business_members.business_id = thermal_receipts.business_id
        AND business_members.user_id = auth.uid()
    )
  );

-- Insert policy: User must be a member of the business
CREATE POLICY "thermal_receipts_insert_members"
  ON public.thermal_receipts FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.business_members
      WHERE business_members.business_id = thermal_receipts.business_id
        AND business_members.user_id = auth.uid()
    )
  );

-- Update policy: User must be a member of the business
CREATE POLICY "thermal_receipts_update_members"
  ON public.thermal_receipts FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.business_members
      WHERE business_members.business_id = thermal_receipts.business_id
        AND business_members.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.business_members
      WHERE business_members.business_id = thermal_receipts.business_id
        AND business_members.user_id = auth.uid()
    )
  );

-- Delete policy: User must be a member of the business
CREATE POLICY "thermal_receipts_delete_members"
  ON public.thermal_receipts FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.business_members
      WHERE business_members.business_id = thermal_receipts.business_id
        AND business_members.user_id = auth.uid()
    )
  );

-- Service role bypass policy
CREATE POLICY "thermal_receipts_service_role"
  ON public.thermal_receipts
  TO service_role
  USING (true)
  WITH CHECK (true);
