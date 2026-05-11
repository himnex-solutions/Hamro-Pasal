-- ============================================================
-- HAMRO PASAL — Complete Supabase PostgreSQL Schema
-- Run this SQL in your Supabase SQL Editor
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── 1. USER PROFILES ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       TEXT NOT NULL,
  full_name   TEXT,
  phone       TEXT,
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 2. BUSINESSES ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS businesses (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  type        TEXT,
  address     TEXT,
  phone       TEXT,
  email       TEXT,
  pan_number  TEXT,
  logo_url    TEXT,
  currency    TEXT NOT NULL DEFAULT 'NPR',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 3. BUSINESS MEMBERS ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS business_members (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role        TEXT NOT NULL DEFAULT 'cashier',
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(business_id, user_id)
);

-- ─── 4. SUBSCRIPTION PLANS ───────────────────────────────────
CREATE TABLE IF NOT EXISTS subscription_plans (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT NOT NULL,
  interval    TEXT NOT NULL, -- monthly, yearly
  price       NUMERIC(10,2) NOT NULL,
  description TEXT,
  features    JSONB DEFAULT '[]'::jsonb,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed plans
INSERT INTO subscription_plans (id, name, interval, price, features) VALUES
  (uuid_generate_v4(), 'Monthly Plan', 'monthly', 499, '["Unlimited transactions","Inventory management","Party ledger","Invoice generation","Reports & export","Staff up to 3","Offline mode"]'),
  (uuid_generate_v4(), 'Yearly Plan',  'yearly',  4499,'["Everything in Monthly","Unlimited staff","Priority support","Custom invoice branding","Data backup"]')
ON CONFLICT DO NOTHING;

-- ─── 5. SUBSCRIPTIONS ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS subscriptions (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id             UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  plan_id                 UUID REFERENCES subscription_plans(id),
  status                  TEXT NOT NULL DEFAULT 'trial_active',
  trial_start_date        TIMESTAMPTZ,
  trial_end_date          TIMESTAMPTZ,
  subscription_start_date TIMESTAMPTZ,
  subscription_end_date   TIMESTAMPTZ,
  is_trial_used           BOOLEAN NOT NULL DEFAULT FALSE,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(business_id)
);

-- ─── 6. PAYMENTS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id     UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES subscriptions(id),
  plan_id         UUID REFERENCES subscription_plans(id),
  amount          NUMERIC(10,2) NOT NULL,
  currency        TEXT NOT NULL DEFAULT 'NPR',
  payment_method  TEXT NOT NULL, -- khalti, esewa, bank
  payment_ref     TEXT,
  status          TEXT NOT NULL DEFAULT 'pending', -- pending, completed, failed
  paid_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 7. PARTIES ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS parties (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id     UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  phone           TEXT,
  email           TEXT,
  address         TEXT,
  type            TEXT NOT NULL DEFAULT 'customer', -- customer, supplier, both
  opening_balance NUMERIC(12,2) NOT NULL DEFAULT 0,
  current_balance NUMERIC(12,2) NOT NULL DEFAULT 0,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 8. PRODUCT CATEGORIES ───────────────────────────────────
CREATE TABLE IF NOT EXISTS product_categories (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  color       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 9. PRODUCTS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id     UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  category_id     UUID REFERENCES product_categories(id),
  name            TEXT NOT NULL,
  sku             TEXT,
  barcode         TEXT,
  unit            TEXT,
  cost_price      NUMERIC(12,2) NOT NULL DEFAULT 0,
  selling_price   NUMERIC(12,2) NOT NULL DEFAULT 0,
  stock_quantity  NUMERIC(12,3) NOT NULL DEFAULT 0,
  min_stock_alert NUMERIC(12,3) NOT NULL DEFAULT 5,
  image_url       TEXT,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 10. BANK ACCOUNTS ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS bank_accounts (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  type        TEXT NOT NULL DEFAULT 'cash', -- cash, bank, mobile_banking
  balance     NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 11. TRANSACTIONS ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id      UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  type             TEXT NOT NULL, -- sale, purchase, expense, income
  payment_method   TEXT NOT NULL DEFAULT 'cash', -- cash, bank, credit, partial
  amount           NUMERIC(12,2) NOT NULL,
  paid_amount      NUMERIC(12,2) NOT NULL DEFAULT 0,
  due_amount       NUMERIC(12,2) NOT NULL DEFAULT 0,
  party_id         UUID REFERENCES parties(id),
  party_name       TEXT,
  account_id       UUID REFERENCES bank_accounts(id),
  note             TEXT,
  receipt_image_url TEXT,
  transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by       UUID REFERENCES auth.users(id)
);

-- ─── 12. TRANSACTION ITEMS ───────────────────────────────────
CREATE TABLE IF NOT EXISTS transaction_items (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  product_id     UUID NOT NULL REFERENCES products(id),
  product_name   TEXT NOT NULL,
  quantity       NUMERIC(12,3) NOT NULL,
  unit_price     NUMERIC(12,2) NOT NULL,
  discount       NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_price    NUMERIC(12,2) NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 12. INVOICES ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS invoices (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id     UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  invoice_number  TEXT NOT NULL,
  party_id        UUID REFERENCES parties(id),
  party_name      TEXT,
  status          TEXT NOT NULL DEFAULT 'unpaid', -- unpaid, partial, paid
  subtotal        NUMERIC(12,2) NOT NULL DEFAULT 0,
  tax_amount      NUMERIC(12,2) NOT NULL DEFAULT 0,
  discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_amount    NUMERIC(12,2) NOT NULL DEFAULT 0,
  paid_amount     NUMERIC(12,2) NOT NULL DEFAULT 0,
  invoice_date    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  due_date        TIMESTAMPTZ,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 13. INVOICE ITEMS ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS invoice_items (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  invoice_id  UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  product_id  UUID REFERENCES products(id),
  product_name TEXT NOT NULL,
  quantity    NUMERIC(12,3) NOT NULL,
  unit_price  NUMERIC(12,2) NOT NULL,
  discount    NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_price NUMERIC(12,2) NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 14. EXPENSES ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS expenses (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id   UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  category_id   UUID,
  category_name TEXT NOT NULL,
  amount        NUMERIC(12,2) NOT NULL,
  note          TEXT,
  receipt_image_url TEXT,
  expense_date  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by    UUID REFERENCES auth.users(id)
);

-- ─── 15. LEDGER ENTRIES ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS ledger_entries (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id    UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  party_id       UUID NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
  transaction_id UUID REFERENCES transactions(id),
  entry_type     TEXT NOT NULL, -- debit, credit
  amount         NUMERIC(12,2) NOT NULL,
  balance_after  NUMERIC(12,2) NOT NULL,
  description    TEXT,
  entry_date     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 17. STOCK MOVEMENTS ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS stock_movements (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id    UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  product_id     UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  movement_type  TEXT NOT NULL, -- sale, purchase, adjustment, return
  quantity       NUMERIC(12,3) NOT NULL,
  balance_before NUMERIC(12,3) NOT NULL,
  balance_after  NUMERIC(12,3) NOT NULL,
  reference_id   UUID,
  note           TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by     UUID REFERENCES auth.users(id)
);

-- ─── 18. ACTIVITY LOGS ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS activity_logs (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES auth.users(id),
  action      TEXT NOT NULL,
  entity_type TEXT,
  entity_id   UUID,
  details     JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 19. SYNC QUEUE ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sync_queue (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL,
  operation   TEXT NOT NULL, -- create, update, delete
  local_id    TEXT NOT NULL,
  payload     JSONB NOT NULL,
  status      TEXT NOT NULL DEFAULT 'pending', -- pending, synced, failed
  retry_count INT NOT NULL DEFAULT 0,
  error_msg   TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  synced_at   TIMESTAMPTZ
);

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_businesses_updated_at BEFORE UPDATE ON businesses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_parties_updated_at BEFORE UPDATE ON parties
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_subscriptions_updated_at BEFORE UPDATE ON subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_user_profiles_updated_at BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Update product stock via RPC
CREATE OR REPLACE FUNCTION update_product_stock(p_product_id UUID, p_delta NUMERIC)
RETURNS VOID AS $$
BEGIN
  UPDATE products SET stock_quantity = stock_quantity + p_delta, updated_at = NOW()
  WHERE id = p_product_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Auto-create user profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email      = EXCLUDED.email,
    full_name  = COALESCE(EXCLUDED.full_name, public.user_profiles.full_name),
    updated_at = NOW();
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'handle_new_user failed for %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger cleanly
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Update subscription status (run periodically)
CREATE OR REPLACE FUNCTION check_trial_expiry()
RETURNS VOID AS $$
BEGIN
  UPDATE subscriptions
  SET status = 'trial_expired', updated_at = NOW()
  WHERE status = 'trial_active' AND trial_end_date < NOW();

  UPDATE subscriptions
  SET status = 'expired', updated_at = NOW()
  WHERE status = 'active' AND subscription_end_date < NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE parties ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_queue ENABLE ROW LEVEL SECURITY;

-- Helper: check if user belongs to a business
CREATE OR REPLACE FUNCTION user_has_business_access(p_business_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM business_members
    WHERE business_id = p_business_id
      AND user_id = auth.uid()
      AND is_active = TRUE
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- user_profiles: own data only
CREATE POLICY "own_profile" ON user_profiles
  USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- businesses: owner or member
CREATE POLICY "business_access" ON businesses
  USING (owner_id = auth.uid() OR user_has_business_access(id));
CREATE POLICY "business_insert" ON businesses
  WITH CHECK (owner_id = auth.uid());

-- business_members
CREATE POLICY "member_access" ON business_members
  USING (user_id = auth.uid() OR user_has_business_access(business_id));
CREATE POLICY "member_insert" ON business_members
  WITH CHECK (user_has_business_access(business_id) OR
              EXISTS(SELECT 1 FROM businesses WHERE id = business_id AND owner_id = auth.uid()));

-- subscription_plans: everyone can read
CREATE POLICY "plans_read" ON subscription_plans FOR SELECT USING (TRUE);

-- subscriptions
CREATE POLICY "subscription_access" ON subscriptions
  USING (user_has_business_access(business_id));
CREATE POLICY "subscription_insert" ON subscriptions
  WITH CHECK (user_has_business_access(business_id));

-- Generic business data policies (parties, products, transactions, etc.)
DO $$
DECLARE
  tbl TEXT;
  tbls TEXT[] := ARRAY[
    'parties','products','product_categories','transactions','transaction_items',
    'invoices','invoice_items','expenses','ledger_entries','bank_accounts',
    'stock_movements','activity_logs','sync_queue','payments'
  ];
BEGIN
  FOREACH tbl IN ARRAY tbls LOOP
    EXECUTE format(
      'CREATE POLICY %I ON %I USING (user_has_business_access(business_id))',
      tbl || '_access', tbl
    );
    EXECUTE format(
      'CREATE POLICY %I ON %I WITH CHECK (user_has_business_access(business_id))',
      tbl || '_write', tbl
    );
  END LOOP;
END $$;

-- ============================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================

CREATE INDEX idx_parties_business ON parties(business_id);
CREATE INDEX idx_products_business ON products(business_id);
CREATE INDEX idx_transactions_business ON transactions(business_id);
CREATE INDEX idx_transactions_date ON transactions(business_id, transaction_date DESC);
CREATE INDEX idx_transactions_type ON transactions(business_id, type);
CREATE INDEX idx_transaction_items_tx ON transaction_items(transaction_id);
CREATE INDEX idx_invoices_business ON invoices(business_id, invoice_date DESC);
CREATE INDEX idx_expenses_business ON expenses(business_id, expense_date DESC);
CREATE INDEX idx_ledger_party ON ledger_entries(party_id, entry_date DESC);
CREATE INDEX idx_stock_movements_product ON stock_movements(product_id, created_at DESC);
CREATE INDEX idx_subscriptions_business ON subscriptions(business_id);
CREATE INDEX idx_sync_queue_status ON sync_queue(business_id, status);

-- ============================================================
-- STORAGE BUCKETS (Run in Supabase Dashboard > Storage)
-- ============================================================
-- INSERT INTO storage.buckets (id, name, public) VALUES
--   ('business-logos', 'business-logos', true),
--   ('product-images', 'product-images', true),
--   ('receipt-images', 'receipt-images', false);
