-- ============================================================
-- HAMRO PASAL – Supabase PostgreSQL Schema
-- Run this in the Supabase SQL Editor
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── USER PROFILES ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_profiles (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  profile_type    TEXT NOT NULL CHECK (profile_type IN ('business', 'personal', 'both')),
  full_name       TEXT,
  email           TEXT,
  phone           TEXT,
  is_first_login  BOOLEAN DEFAULT true,
  email_verified  BOOLEAN DEFAULT false,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─── BUSINESS PROFILES ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS business_profiles (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id            UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  business_name      TEXT NOT NULL,
  owner_name         TEXT,
  business_category  TEXT,
  pan_vat_number     TEXT,
  business_address   TEXT,
  company_logo_url   TEXT,
  phone              TEXT,
  email              TEXT,
  created_at         TIMESTAMPTZ DEFAULT NOW(),
  updated_at         TIMESTAMPTZ DEFAULT NOW()
);

-- ─── PERSONAL PROFILES ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS personal_profiles (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  full_name   TEXT NOT NULL,
  phone       TEXT,
  email       TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─── ACTIVE PROFILES ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS active_profiles (
  id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id              UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  active_profile_id    UUID NOT NULL,
  active_profile_type  TEXT NOT NULL CHECK (active_profile_type IN ('business', 'personal')),
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ─── SUBSCRIPTIONS ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS subscriptions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  plan_type       TEXT NOT NULL CHECK (plan_type IN ('free','monthly','sixMonth','yearly')),
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  status          TEXT NOT NULL CHECK (status IN ('active','expired','trial','cancelled')),
  payment_method  TEXT,
  transaction_id  TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─── PRODUCTS ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name             TEXT NOT NULL,
  barcode          TEXT,
  category         TEXT,
  cost_price       NUMERIC(12,2) NOT NULL DEFAULT 0,
  selling_price    NUMERIC(12,2) NOT NULL DEFAULT 0,
  stock_quantity   INTEGER NOT NULL DEFAULT 0,
  low_stock_limit  INTEGER NOT NULL DEFAULT 5,
  expiry_date      DATE,
  image_url        TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_products_user ON products(user_id);
CREATE INDEX idx_products_name ON products(name);

-- ─── CUSTOMERS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS customers (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name        TEXT NOT NULL,
  phone       TEXT,
  address     TEXT,
  total_due   NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_customers_user ON customers(user_id);

-- ─── SALES ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sales (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  customer_id     UUID REFERENCES customers(id) ON DELETE SET NULL,
  bill_number     TEXT NOT NULL UNIQUE,
  subtotal        NUMERIC(12,2) NOT NULL DEFAULT 0,
  discount        NUMERIC(12,2) NOT NULL DEFAULT 0,
  tax             NUMERIC(12,2) NOT NULL DEFAULT 0,
  total           NUMERIC(12,2) NOT NULL DEFAULT 0,
  payment_status  TEXT NOT NULL DEFAULT 'paid' CHECK (payment_status IN ('paid','credit','partial')),
  payment_method  TEXT NOT NULL DEFAULT 'cash',
  ad_date         DATE NOT NULL,
  bs_date         TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sales_user ON sales(user_id);
CREATE INDEX idx_sales_date ON sales(ad_date);

-- ─── SALE ITEMS ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sale_items (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sale_id       UUID REFERENCES sales(id) ON DELETE CASCADE NOT NULL,
  product_id    UUID REFERENCES products(id) ON DELETE SET NULL,
  product_name  TEXT NOT NULL,
  quantity      INTEGER NOT NULL,
  price         NUMERIC(12,2) NOT NULL,
  total         NUMERIC(12,2) NOT NULL
);

CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);

-- ─── LEDGER TRANSACTIONS ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS ledger_transactions (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  customer_id  UUID REFERENCES customers(id) ON DELETE CASCADE NOT NULL,
  type         TEXT NOT NULL CHECK (type IN ('credit','payment')),
  amount       NUMERIC(12,2) NOT NULL,
  note         TEXT,
  ad_date      DATE NOT NULL,
  bs_date      TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ledger_customer ON ledger_transactions(customer_id);

-- ─── EXPENSES ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS expenses (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title       TEXT NOT NULL,
  category    TEXT NOT NULL,
  amount      NUMERIC(12,2) NOT NULL,
  ad_date     DATE NOT NULL,
  bs_date     TEXT,
  note        TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_expenses_user ON expenses(user_id);

-- ─── SUPPLIERS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS suppliers (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name        TEXT NOT NULL,
  phone       TEXT,
  address     TEXT,
  total_due   NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─── PURCHASE ENTRIES ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS purchase_entries (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  supplier_id   UUID REFERENCES suppliers(id) ON DELETE SET NULL,
  total_amount  NUMERIC(12,2) NOT NULL DEFAULT 0,
  paid_amount   NUMERIC(12,2) NOT NULL DEFAULT 0,
  due_amount    NUMERIC(12,2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
  ad_date       DATE NOT NULL,
  bs_date       TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ─── PURCHASE ITEMS ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS purchase_items (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  purchase_id  UUID REFERENCES purchase_entries(id) ON DELETE CASCADE NOT NULL,
  product_id   UUID REFERENCES products(id) ON DELETE SET NULL,
  quantity     INTEGER NOT NULL,
  cost_price   NUMERIC(12,2) NOT NULL,
  total        NUMERIC(12,2) NOT NULL
);

-- ─── STAFF USERS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS staff_users (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id      UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  staff_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role          TEXT NOT NULL CHECK (role IN ('manager','cashier')),
  permissions   JSONB NOT NULL DEFAULT '{}',
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(owner_id, staff_user_id)
);

-- ─── BRANCHES ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS branches (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  branch_name  TEXT NOT NULL,
  address      TEXT,
  phone        TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Decrement product stock after sale
CREATE OR REPLACE FUNCTION decrement_stock(product_id UUID, qty INTEGER)
RETURNS VOID AS $$
BEGIN
  UPDATE products
  SET stock_quantity = GREATEST(0, stock_quantity - qty)
  WHERE id = product_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Auto update customer total_due after ledger transaction
CREATE OR REPLACE FUNCTION update_customer_due()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.type = 'credit' THEN
    UPDATE customers SET total_due = total_due + NEW.amount WHERE id = NEW.customer_id;
  ELSIF NEW.type = 'payment' THEN
    UPDATE customers SET total_due = GREATEST(0, total_due - NEW.amount) WHERE id = NEW.customer_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_customer_due
AFTER INSERT ON ledger_transactions
FOR EACH ROW EXECUTE FUNCTION update_customer_due();

-- Auto increase stock on purchase
CREATE OR REPLACE FUNCTION increase_stock_on_purchase()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE products
  SET stock_quantity = stock_quantity + NEW.quantity
  WHERE id = NEW.product_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_purchase_stock
AFTER INSERT ON purchase_items
FOR EACH ROW EXECUTE FUNCTION increase_stock_on_purchase();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE user_profiles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_profiles   ENABLE ROW LEVEL SECURITY;
ALTER TABLE personal_profiles   ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_profiles     ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE products            ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers           ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales               ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items          ENABLE ROW LEVEL SECURITY;
ALTER TABLE ledger_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses            ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers           ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_entries    ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_items      ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_users         ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches            ENABLE ROW LEVEL SECURITY;

-- ─── Helper: check if user owns a sale ───────────────────────
CREATE OR REPLACE FUNCTION own_sale(sale_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (SELECT 1 FROM sales WHERE id = sale_id AND user_id = auth.uid());
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ─── PROFILES policies ───────────────────────────────────────
CREATE POLICY "Users can view own user_profile"
  ON user_profiles FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own user_profile"
  ON user_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own user_profile"
  ON user_profiles FOR UPDATE USING (auth.uid() = user_id);

-- ─── BUSINESS PROFILES policies ──────────────────────────────
CREATE POLICY "Users can view own business_profile"
  ON business_profiles FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own business_profile"
  ON business_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own business_profile"
  ON business_profiles FOR UPDATE USING (auth.uid() = user_id);

-- ─── PERSONAL PROFILES policies ──────────────────────────────
CREATE POLICY "Users can view own personal_profile"
  ON personal_profiles FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own personal_profile"
  ON personal_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own personal_profile"
  ON personal_profiles FOR UPDATE USING (auth.uid() = user_id);

-- ─── ACTIVE PROFILES policies ────────────────────────────────
CREATE POLICY "Users can view own active_profile"
  ON active_profiles FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own active_profile"
  ON active_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own active_profile"
  ON active_profiles FOR UPDATE USING (auth.uid() = user_id);

-- ─── SUBSCRIPTIONS policies ──────────────────────────────────
CREATE POLICY "Users can view own subscription"
  ON subscriptions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscription"
  ON subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscription"
  ON subscriptions FOR UPDATE USING (auth.uid() = user_id);

-- ─── PRODUCTS policies ───────────────────────────────────────
CREATE POLICY "Users can manage own products"
  ON products FOR ALL USING (auth.uid() = user_id);

-- ─── CUSTOMERS policies ──────────────────────────────────────
CREATE POLICY "Users can manage own customers"
  ON customers FOR ALL USING (auth.uid() = user_id);

-- ─── SALES policies ──────────────────────────────────────────
CREATE POLICY "Users can manage own sales"
  ON sales FOR ALL USING (auth.uid() = user_id);

-- ─── SALE ITEMS policies ─────────────────────────────────────
CREATE POLICY "Users can view own sale items"
  ON sale_items FOR SELECT USING (own_sale(sale_id));

CREATE POLICY "Users can insert own sale items"
  ON sale_items FOR INSERT WITH CHECK (own_sale(sale_id));

-- ─── LEDGER TRANSACTIONS policies ───────────────────────────
CREATE POLICY "Users can manage own ledger"
  ON ledger_transactions FOR ALL USING (auth.uid() = user_id);

-- ─── EXPENSES policies ───────────────────────────────────────
CREATE POLICY "Users can manage own expenses"
  ON expenses FOR ALL USING (auth.uid() = user_id);

-- ─── SUPPLIERS policies ──────────────────────────────────────
CREATE POLICY "Users can manage own suppliers"
  ON suppliers FOR ALL USING (auth.uid() = user_id);

-- ─── PURCHASE ENTRIES policies ───────────────────────────────
CREATE POLICY "Users can manage own purchases"
  ON purchase_entries FOR ALL USING (auth.uid() = user_id);

-- ─── STAFF USERS policies ────────────────────────────────────
CREATE POLICY "Owners can manage their staff"
  ON staff_users FOR ALL USING (auth.uid() = owner_id);

CREATE POLICY "Staff can view their record"
  ON staff_users FOR SELECT USING (auth.uid() = staff_user_id);

-- ─── BRANCHES policies ───────────────────────────────────────
CREATE POLICY "Owners can manage their branches"
  ON branches FOR ALL USING (auth.uid() = owner_id);

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('shop-logos', 'shop-logos', true)
ON CONFLICT DO NOTHING;

CREATE POLICY "Authenticated users can upload product images"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'product-images' AND auth.role() = 'authenticated');

CREATE POLICY "Public can view product images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'product-images');

CREATE POLICY "Users can upload shop logo"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'shop-logos' AND auth.role() = 'authenticated');

CREATE POLICY "Public can view shop logos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'shop-logos');
