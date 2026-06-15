-- ============================================================
-- Run this SQL in your Supabase Dashboard → SQL Editor
-- Settings → API → copy the values below
-- ============================================================

-- Replace these two values with YOUR actual project values:
--   supabase_url   → Settings > API > Project URL
--   service_role_key → Settings > API > service_role (secret)

INSERT INTO public.system_settings (key, value) VALUES
  ('supabase_url',      'https://dgevkedwjmyggclnjbal.supabase.co'),
  ('service_role_key',  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRnZXZrZWR3am15Z2djbG5qYmFsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NzgxNzEwNSwiZXhwIjoyMDkzMzkzMTA1fQ.lG1A_00j5UBmY2mUgA8eTh1NVX0If8WK717w_bmF5kE')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- Verify:
SELECT key, LEFT(value, 40) || '...' AS value_preview FROM public.system_settings;
