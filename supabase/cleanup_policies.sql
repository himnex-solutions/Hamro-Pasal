-- ============================================================
-- HAMRO PASAL — Policy Cleanup Script
-- Run this ONCE in Supabase SQL Editor before re-running schema.sql
-- This drops all existing RLS policies so the schema runs cleanly.
-- ============================================================

-- User / Profile tables
DROP POLICY IF EXISTS "Users can view own user_profile"     ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own user_profile"   ON user_profiles;
DROP POLICY IF EXISTS "Users can update own user_profile"   ON user_profiles;

DROP POLICY IF EXISTS "Users can view own business_profile"   ON business_profiles;
DROP POLICY IF EXISTS "Users can insert own business_profile" ON business_profiles;
DROP POLICY IF EXISTS "Users can update own business_profile" ON business_profiles;

DROP POLICY IF EXISTS "Users can view own personal_profile"   ON personal_profiles;
DROP POLICY IF EXISTS "Users can insert own personal_profile" ON personal_profiles;
DROP POLICY IF EXISTS "Users can update own personal_profile" ON personal_profiles;

DROP POLICY IF EXISTS "Users can view own active_profile"   ON active_profiles;
DROP POLICY IF EXISTS "Users can insert own active_profile" ON active_profiles;
DROP POLICY IF EXISTS "Users can update own active_profile" ON active_profiles;

-- Old single-profile table (may exist from earlier schema version)
DROP POLICY IF EXISTS "Users can view own profile"   ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- Subscriptions
DROP POLICY IF EXISTS "Users can view own subscription"   ON subscriptions;
DROP POLICY IF EXISTS "Users can insert own subscription" ON subscriptions;
DROP POLICY IF EXISTS "Users can update own subscription" ON subscriptions;

-- Business data
DROP POLICY IF EXISTS "Users can manage own products"   ON products;
DROP POLICY IF EXISTS "Users can manage own customers"  ON customers;
DROP POLICY IF EXISTS "Users can manage own sales"      ON sales;
DROP POLICY IF EXISTS "Users can view own sale items"   ON sale_items;
DROP POLICY IF EXISTS "Users can insert own sale items" ON sale_items;
DROP POLICY IF EXISTS "Users can manage own ledger"     ON ledger_transactions;
DROP POLICY IF EXISTS "Users can manage own expenses"   ON expenses;
DROP POLICY IF EXISTS "Users can manage own suppliers"  ON suppliers;
DROP POLICY IF EXISTS "Users can manage own purchases"  ON purchase_entries;

-- Staff / Branches
DROP POLICY IF EXISTS "Owners can manage their staff"   ON staff_users;
DROP POLICY IF EXISTS "Staff can view their record"     ON staff_users;
DROP POLICY IF EXISTS "Owners can manage their branches" ON branches;

-- Storage policies (these are the ones causing your error)
DROP POLICY IF EXISTS "Authenticated users can upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Public can view product images"                ON storage.objects;
DROP POLICY IF EXISTS "Users can upload shop logo"                    ON storage.objects;
DROP POLICY IF EXISTS "Public can view shop logos"                    ON storage.objects;
