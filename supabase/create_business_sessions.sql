-- Run this in your Supabase SQL Editor → New Query

-- Active sessions table for concurrent login control
CREATE TABLE IF NOT EXISTS business_sessions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id   UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  user_id       UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  device_id     TEXT NOT NULL,
  device_name   TEXT,
  last_active   TIMESTAMPTZ DEFAULT NOW(),
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(business_id, device_id)
);

ALTER TABLE business_sessions ENABLE ROW LEVEL SECURITY;

-- Users can manage their own session rows
CREATE POLICY "users_manage_own_sessions" ON business_sessions
  USING  (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Business members can view all sessions for their business
CREATE POLICY "members_view_business_sessions" ON business_sessions
  FOR SELECT USING (
    business_id IN (
      SELECT business_id FROM business_members WHERE user_id = auth.uid()
    )
  );
