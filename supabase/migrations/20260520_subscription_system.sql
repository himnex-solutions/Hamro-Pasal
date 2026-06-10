-- ============================================================
-- SMART SAOJI — Subscription & Membership System Migration
-- ============================================================

-- Enable UUID extension if not already
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing tables to ensure clean rebuild (avoids column mismatch conflicts)
DROP TABLE IF EXISTS public.admin_payment_reviews CASCADE;
DROP TABLE IF EXISTS public.business_limits CASCADE;
DROP TABLE IF EXISTS public.staff_limits CASCADE;
DROP TABLE IF EXISTS public.feature_permissions CASCADE;
DROP TABLE IF EXISTS public.payment_requests CASCADE;
DROP TABLE IF EXISTS public.user_subscriptions CASCADE;
DROP TABLE IF EXISTS public.subscription_plans CASCADE;

-- ─── 1. SUBSCRIPTION PLANS ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plan_code   TEXT UNIQUE NOT NULL, -- 'basic', 'gold', 'diamond'
  name        TEXT NOT NULL,
  price       NUMERIC(10,2) NOT NULL DEFAULT 0,
  interval    TEXT NOT NULL DEFAULT 'yearly', -- 'forever', 'yearly'
  features    JSONB DEFAULT '[]'::jsonb,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed plans
INSERT INTO public.subscription_plans (plan_code, name, price, interval, features) VALUES
  ('basic', 'Basic Free Plan', 0.00, 'forever', '["1 Business Profile only", "1 Personal Finance Profile only", "Record Unlimited Business Transactions", "Add & Manage Unlimited Inventory Items", "Offline + Online Support", "Basic Reports", "Mobile app access only"]'),
  ('gold', 'Gold Plan', 1200.00, 'yearly', '["Up to 3 Business Profiles", "Add up to 3 Staff Accounts", "Upload Bill Images", "Barcode Scanner", "View & Download Unlimited Reports", "Thermal Printer Support", "Enable App Lock", "Offline + Online Support", "Customize Invoices", "A5 Paper Printing Support", "Organize Parties into Categories", "Hide Smart Saoji Branding", "Low Stock Alerts", "Enable Transaction Prefixes", "Premium Mobile Features"]'),
  ('diamond', 'Diamond Plan', 2400.00, 'yearly', '["Up to 5 Business Profiles", "Add up to 5 Staff Accounts", "Upload Bill Images", "Excel Report Download", "Barcode Scanner", "View & Download Unlimited Reports", "Enable App Lock", "Thermal Printing", "Offline + Online Support", "Customize Invoices", "A5 Paper Printing Support", "Organize Parties into Categories", "Hide Smart Saoji Branding", "Low Stock Alerts", "Enable Transaction Prefixes", "Desktop + Web Access", "Full Multi-platform Synchronization"]')
ON CONFLICT (plan_code) DO UPDATE SET
  name = EXCLUDED.name,
  price = EXCLUDED.price,
  interval = EXCLUDED.interval,
  features = EXCLUDED.features;

-- ─── 2. USER SUBSCRIPTIONS ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id                 UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE UNIQUE,
  plan_code               TEXT NOT NULL REFERENCES public.subscription_plans(plan_code) ON UPDATE CASCADE,
  start_date              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expiry_date             TIMESTAMPTZ, -- NULL for basic
  status                  TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'suspended')),
  payment_status          TEXT NOT NULL DEFAULT 'completed' CHECK (payment_status IN ('pending', 'completed', 'failed')),
  screenshot_url          TEXT,
  approved_by             UUID REFERENCES public.user_profiles(id),
  approved_at             TIMESTAMPTZ,
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 3. PAYMENT REQUESTS ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.payment_requests (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id                 UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  plan_code               TEXT NOT NULL REFERENCES public.subscription_plans(plan_code) ON UPDATE CASCADE,
  amount                  NUMERIC(10,2) NOT NULL,
  screenshot_url          TEXT NOT NULL,
  status                  TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  rejection_reason        TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 4. FEATURE PERMISSIONS ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.feature_permissions (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plan_code               TEXT NOT NULL REFERENCES public.subscription_plans(plan_code) ON UPDATE CASCADE,
  feature_name            TEXT NOT NULL,
  is_allowed              BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE(plan_code, feature_name)
);

-- Seed permissions
INSERT INTO public.feature_permissions (plan_code, feature_name, is_allowed) VALUES
  -- Basic permissions
  ('basic', 'multi_business', false),
  ('basic', 'staff_accounts', false),
  ('basic', 'barcode_scanner', false),
  ('basic', 'bill_image_upload', false),
  ('basic', 'app_lock', false),
  ('basic', 'invoice_customization', false),
  ('basic', 'thermal_printing', false),
  ('basic', 'excel_export', false),
  ('basic', 'a5_printing', false),
  ('basic', 'desktop_web_access', false),
  ('basic', 'low_stock_alerts', false),
  ('basic', 'transaction_prefixes', false),
  ('basic', 'remove_branding', false),
  
  -- Gold permissions
  ('gold', 'multi_business', true),
  ('gold', 'staff_accounts', true),
  ('gold', 'barcode_scanner', true),
  ('gold', 'bill_image_upload', true),
  ('gold', 'app_lock', true),
  ('gold', 'invoice_customization', true),
  ('gold', 'thermal_printing', true),
  ('gold', 'excel_export', false),
  ('gold', 'a5_printing', true),
  ('gold', 'desktop_web_access', false),
  ('gold', 'low_stock_alerts', true),
  ('gold', 'transaction_prefixes', true),
  ('gold', 'remove_branding', true),

  -- Diamond permissions
  ('diamond', 'multi_business', true),
  ('diamond', 'staff_accounts', true),
  ('diamond', 'barcode_scanner', true),
  ('diamond', 'bill_image_upload', true),
  ('diamond', 'app_lock', true),
  ('diamond', 'invoice_customization', true),
  ('diamond', 'thermal_printing', true),
  ('diamond', 'excel_export', true),
  ('diamond', 'a5_printing', true),
  ('diamond', 'desktop_web_access', true),
  ('diamond', 'low_stock_alerts', true),
  ('diamond', 'transaction_prefixes', true),
  ('diamond', 'remove_branding', true)
ON CONFLICT (plan_code, feature_name) DO UPDATE SET is_allowed = EXCLUDED.is_allowed;

-- ─── 5. STAFF LIMITS ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.staff_limits (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plan_code               TEXT UNIQUE NOT NULL REFERENCES public.subscription_plans(plan_code) ON UPDATE CASCADE,
  max_staff               INT NOT NULL DEFAULT 0
);

INSERT INTO public.staff_limits (plan_code, max_staff) VALUES
  ('basic', 0),
  ('gold', 3),
  ('diamond', 5)
ON CONFLICT (plan_code) DO UPDATE SET max_staff = EXCLUDED.max_staff;

-- ─── 6. BUSINESS LIMITS ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.business_limits (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plan_code               TEXT UNIQUE NOT NULL REFERENCES public.subscription_plans(plan_code) ON UPDATE CASCADE,
  max_businesses          INT NOT NULL DEFAULT 1
);

INSERT INTO public.business_limits (plan_code, max_businesses) VALUES
  ('basic', 1),
  ('gold', 3),
  ('diamond', 5)
ON CONFLICT (plan_code) DO UPDATE SET max_businesses = EXCLUDED.max_businesses;

-- ─── 7. ADMIN PAYMENT REVIEWS ────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_payment_reviews (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  payment_request_id      UUID NOT NULL REFERENCES public.payment_requests(id) ON DELETE CASCADE,
  admin_id                UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  action                  TEXT NOT NULL CHECK (action IN ('approved', 'rejected')),
  rejection_reason        TEXT,
  reviewed_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 8. TRIGGERS & FUNCTIONS ─────────────────────────────────

-- Auto-update updated_at for payment_requests
CREATE TRIGGER trg_payment_requests_updated_at BEFORE UPDATE ON public.payment_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-create/downgrade subscription row for new user profile
CREATE OR REPLACE FUNCTION handle_new_user_subscription()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_subscriptions (user_id, plan_code, status, payment_status, start_date, expiry_date)
  VALUES (NEW.id, 'basic', 'active', 'completed', NOW(), NULL)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_user_profile_created ON public.user_profiles;
CREATE TRIGGER on_user_profile_created
  AFTER INSERT ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION handle_new_user_subscription();

-- Backfill subscriptions for existing users
INSERT INTO public.user_subscriptions (user_id, plan_code, status, payment_status, start_date, expiry_date)
SELECT id, 'basic', 'active', 'completed', NOW(), NULL FROM public.user_profiles
ON CONFLICT (user_id) DO NOTHING;

-- RPC to check / refresh expired subscriptions
CREATE OR REPLACE FUNCTION check_and_downgrade_expired_subscriptions()
RETURNS VOID AS $$
BEGIN
  -- Downgrade expired users to Basic plan
  UPDATE public.user_subscriptions
  SET plan_code = 'basic',
      expiry_date = NULL,
      status = 'active',
      payment_status = 'completed',
      updated_at = NOW()
  WHERE plan_code != 'basic'
    AND expiry_date < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── 9. ROW LEVEL SECURITY (RLS) ─────────────────────────────
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_payment_reviews ENABLE ROW LEVEL SECURITY;

-- ── Subscription Plans Policies
CREATE POLICY "Everyone can read plans" ON public.subscription_plans
  FOR SELECT USING (true);

-- ── User Subscriptions Policies
CREATE POLICY "Users can read own subscription" ON public.user_subscriptions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all user subscriptions" ON public.user_subscriptions
  USING (is_admin_user()) WITH CHECK (is_admin_user());

-- ── Payment Requests Policies
CREATE POLICY "Users can view own payment requests" ON public.payment_requests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own payment requests" ON public.payment_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can manage all payment requests" ON public.payment_requests
  USING (is_admin_user()) WITH CHECK (is_admin_user());

-- ── Feature Permissions Policies
CREATE POLICY "Everyone can read permissions" ON public.feature_permissions
  FOR SELECT USING (true);

-- ── Staff Limits Policies
CREATE POLICY "Everyone can read staff limits" ON public.staff_limits
  FOR SELECT USING (true);

-- ── Business Limits Policies
CREATE POLICY "Everyone can read business limits" ON public.business_limits
  FOR SELECT USING (true);

-- ── Admin Payment Reviews Policies
CREATE POLICY "Users can view reviews on own payments" ON public.admin_payment_reviews
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.payment_requests
      WHERE payment_requests.id = admin_payment_reviews.payment_request_id
        AND payment_requests.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage all reviews" ON public.admin_payment_reviews
  USING (is_admin_user()) WITH CHECK (is_admin_user());

-- Add to Realtime
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'user_subscriptions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_subscriptions;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'payment_requests'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.payment_requests;
  END IF;
END $$;
