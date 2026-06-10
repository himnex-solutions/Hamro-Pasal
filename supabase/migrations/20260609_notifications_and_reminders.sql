-- ============================================================
-- SMART SAOJI — Notifications & Reminders System Migration
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pg_cron";
CREATE EXTENSION IF NOT EXISTS "pg_net";

-- Ensure the public.is_admin_user() helper exists
CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  admin_flag BOOLEAN;
BEGIN
  SELECT is_admin INTO admin_flag 
  FROM user_profiles 
  WHERE id = auth.uid();
  RETURN COALESCE(admin_flag, FALSE);
END;
$$;

-- ─── 1. NOTIFICATIONS TABLE ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  message     TEXT NOT NULL,
  type        TEXT NOT NULL CHECK (type IN ('success', 'warning', 'info', 'error')),
  is_read     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 2. USER DEVICES TABLE ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_devices (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  fcm_token   TEXT NOT NULL UNIQUE,
  device_type TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 3. EMAIL LOGS TABLE ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.email_logs (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  email         TEXT NOT NULL,
  subject       TEXT NOT NULL,
  body          TEXT,
  status        TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  error_message TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 4. SUBSCRIPTION REQUESTS TABLE ───────────────────────────
CREATE TABLE IF NOT EXISTS public.subscription_requests (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id                 UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  plan_name               TEXT NOT NULL,
  payment_screenshot_url  TEXT NOT NULL,
  status                  TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  rejection_reason        TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 5. FREE PLAN REMINDERS TABLE ─────────────────────────────
CREATE TABLE IF NOT EXISTS public.free_plan_reminders (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE UNIQUE,
  last_sent_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reminder_count  INT NOT NULL DEFAULT 0
);

-- ─── 6. SUBSCRIPTION REMINDER LOGS TABLE ──────────────────────
CREATE TABLE IF NOT EXISTS public.subscription_reminder_logs (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  reminder_type TEXT NOT NULL,
  sent_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 7. ROW LEVEL SECURITY (RLS) ─────────────────────────────
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.free_plan_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_reminder_logs ENABLE ROW LEVEL SECURITY;

-- Notifications Policies
CREATE POLICY "Users can manage own notifications" ON public.notifications
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all notifications" ON public.notifications
  USING (public.is_admin_user());

-- User Devices Policies
CREATE POLICY "Users can manage own devices" ON public.user_devices
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Email Logs Policies
CREATE POLICY "Users can read own email logs" ON public.email_logs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all email logs" ON public.email_logs
  USING (public.is_admin_user());

-- Subscription Requests Policies
CREATE POLICY "Users can view own subscription requests" ON public.subscription_requests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscription requests" ON public.subscription_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can manage all subscription requests" ON public.subscription_requests
  USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());

-- Free Plan Reminders Policies
CREATE POLICY "Admins can read/write free plan reminders" ON public.free_plan_reminders
  USING (public.is_admin_user());

-- Subscription Reminder Logs Policies
CREATE POLICY "Admins can read/write subscription reminder logs" ON public.subscription_reminder_logs
  USING (public.is_admin_user());

-- ─── 8. SUPABASE REALTIME CONFIGURATION ────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'subscription_requests'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.subscription_requests;
  END IF;
END $$;

-- ─── 9. TRIGGERS & SYNC FUNCTIONS ─────────────────────────────

-- Sync subscription_requests to payment_requests
CREATE OR REPLACE FUNCTION public.sync_sub_req_to_pay_req()
RETURNS TRIGGER AS $$
BEGIN
  IF pg_trigger_depth() > 1 THEN
    RETURN NEW;
  END IF;
  
  INSERT INTO public.payment_requests (id, user_id, plan_code, amount, screenshot_url, status, rejection_reason, created_at)
  VALUES (
    NEW.id,
    NEW.user_id,
    NEW.plan_name,
    CASE WHEN NEW.plan_name = 'diamond' THEN 2400.00 ELSE 1200.00 END,
    NEW.payment_screenshot_url,
    NEW.status,
    NEW.rejection_reason,
    NEW.created_at
  ) ON CONFLICT (id) DO UPDATE SET
    plan_code = EXCLUDED.plan_code,
    screenshot_url = EXCLUDED.screenshot_url,
    status = EXCLUDED.status,
    rejection_reason = EXCLUDED.rejection_reason,
    updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_sub_req_to_pay_req ON public.subscription_requests;
CREATE TRIGGER trg_sync_sub_req_to_pay_req
  AFTER INSERT OR UPDATE ON public.subscription_requests
  FOR EACH ROW EXECUTE FUNCTION public.sync_sub_req_to_pay_req();

-- Sync payment_requests to subscription_requests
CREATE OR REPLACE FUNCTION public.sync_pay_req_to_sub_req()
RETURNS TRIGGER AS $$
BEGIN
  IF pg_trigger_depth() > 1 THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.subscription_requests (id, user_id, plan_name, payment_screenshot_url, status, rejection_reason, created_at)
  VALUES (
    NEW.id,
    NEW.user_id,
    NEW.plan_code,
    NEW.screenshot_url,
    NEW.status,
    NEW.rejection_reason,
    NEW.created_at
  ) ON CONFLICT (id) DO UPDATE SET
    plan_name = EXCLUDED.plan_name,
    payment_screenshot_url = EXCLUDED.payment_screenshot_url,
    status = EXCLUDED.status,
    rejection_reason = EXCLUDED.rejection_reason;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_pay_req_to_sub_req ON public.payment_requests;
CREATE TRIGGER trg_sync_pay_req_to_sub_req
  AFTER INSERT OR UPDATE ON public.payment_requests
  FOR EACH ROW EXECUTE FUNCTION public.sync_pay_req_to_sub_req();

-- Backfill subscription_requests from payment_requests
INSERT INTO public.subscription_requests (id, user_id, plan_name, payment_screenshot_url, status, rejection_reason, created_at)
SELECT id, user_id, plan_code, screenshot_url, status, rejection_reason, created_at FROM public.payment_requests
ON CONFLICT (id) DO NOTHING;

-- ─── 10. WELCOME EMAIL QUEUEING TRIGGER ────────────────────────
CREATE OR REPLACE FUNCTION public.queue_welcome_email()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.email_logs 
    WHERE user_id = NEW.id AND subject = 'Welcome to Smart Saoji'
  ) THEN
    -- Insert welcome notification
    INSERT INTO public.notifications (user_id, title, message, type)
    VALUES (
      NEW.id,
      'Welcome to Smart Saoji! 🎉',
      'Thank you for registering. Build your business efficiently with our suite.',
      'success'
    );

    -- Insert email queue item
    INSERT INTO public.email_logs (user_id, email, subject, body, status)
    VALUES (
      NEW.id,
      NEW.email,
      'Welcome to Smart Saoji',
      json_build_object(
        'template', 'welcome',
        'name', COALESCE(NEW.full_name, 'Valued User')
      )::text,
      'pending'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_queue_welcome_email ON public.user_profiles;
CREATE TRIGGER trg_queue_welcome_email
  AFTER INSERT ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.queue_welcome_email();

-- ─── 11. PAYMENT REQUEST NOTIFICATION TRIGGER (SUBMITTED) ──────────────
-- NOTE: Flutter app inserts into payment_requests directly (not subscription_requests).
-- The sync trigger then copies to subscription_requests at depth=1.
-- So we attach notifications HERE on payment_requests (fires at depth=0, exactly once).

CREATE OR REPLACE FUNCTION public.handle_payment_request_inserted()
RETURNS TRIGGER AS $$
DECLARE
  v_user_email TEXT;
  v_user_name TEXT;
  v_admin_email TEXT;
  v_plan_name TEXT;
BEGIN
  -- Get user info
  SELECT email, full_name INTO v_user_email, v_user_name
  FROM public.user_profiles WHERE id = NEW.user_id;

  -- plan_code is already stored in payment_requests (e.g. 'gold', 'diamond')
  v_plan_name := INITCAP(NEW.plan_code);

  -- 1. User dashboard notification
  INSERT INTO public.notifications (user_id, title, message, type) VALUES (
    NEW.user_id,
    'Subscription Request Received ⏳',
    'Your subscription request has been received and is pending verification.',
    'info'
  );

  -- 2. User confirmation email
  IF v_user_email IS NOT NULL AND v_user_email <> '' THEN
    INSERT INTO public.email_logs (user_id, email, subject, body, status) VALUES (
      NEW.user_id, v_user_email,
      'Subscription Request Received',
      json_build_object(
        'template', 'subscription_submitted',
        'name', COALESCE(v_user_name, 'Valued User'),
        'plan_name', v_plan_name
      )::text,
      'pending'
    );
  END IF;

  -- 3. Email to every admin (one per admin account)
  FOR v_admin_email IN
    SELECT email FROM public.user_profiles
    WHERE is_admin = TRUE AND email IS NOT NULL AND email <> ''
  LOOP
    INSERT INTO public.email_logs (user_id, email, subject, body, status) VALUES (
      NEW.user_id, v_admin_email,
      'New Subscription Request - ' || COALESCE(v_user_name, 'User'),
      json_build_object(
        'template', 'admin_subscription_submitted',
        'user_name', COALESCE(v_user_name, 'User'),
        'user_email', COALESCE(v_user_email, 'N/A'),
        'plan_name', v_plan_name,
        'screenshot_url', NEW.screenshot_url,
        'created_at', NEW.created_at
      )::text,
      'pending'
    );
  END LOOP;

  -- 4. Dashboard notification for every admin
  INSERT INTO public.notifications (user_id, title, message, type)
  SELECT id,
    'New Subscription Request ⏳',
    COALESCE(v_user_name, 'A user') || ' requested upgrade to ' || v_plan_name || '.',
    'info'
  FROM public.user_profiles WHERE is_admin = TRUE;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Remove old trigger on subscription_requests (no longer needed for notifications)
DROP TRIGGER IF EXISTS trg_subscription_request_inserted ON public.subscription_requests;

-- Attach to payment_requests — fires exactly ONCE when Flutter submits a payment
DROP TRIGGER IF EXISTS trg_payment_request_inserted ON public.payment_requests;
CREATE TRIGGER trg_payment_request_inserted
  AFTER INSERT ON public.payment_requests
  FOR EACH ROW EXECUTE FUNCTION public.handle_payment_request_inserted();

-- ─── 12. SUBSCRIPTION APPROVAL / REJECTION TRIGGER ──────────────
CREATE OR REPLACE FUNCTION public.handle_subscription_request_updated()
RETURNS TRIGGER AS $$
DECLARE
  v_user_email TEXT;
  v_user_name TEXT;
  v_plan_name TEXT;
BEGIN
  -- Check if status changed
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    SELECT email, full_name INTO v_user_email, v_user_name
    FROM public.user_profiles
    WHERE id = NEW.user_id;

    v_plan_name := UPPER(SUBSTRING(NEW.plan_name FROM 1 FOR 1)) || SUBSTRING(NEW.plan_name FROM 2);

    IF NEW.status = 'approved' THEN
      -- 1. Create dashboard notification
      INSERT INTO public.notifications (user_id, title, message, type)
      VALUES (
        NEW.user_id,
        '🎉 Subscription Approved!',
        'Your ' || v_plan_name || ' subscription is now active. Welcome aboard!',
        'success'
      );

      -- 2. Queue Approval Email
      IF v_user_email IS NOT NULL AND v_user_email <> '' THEN
        INSERT INTO public.email_logs (user_id, email, subject, body, status)
        VALUES (
          NEW.user_id,
          v_user_email,
          'Subscription Request Approved 🎉',
          json_build_object(
            'template', 'subscription_approved',
            'name', COALESCE(v_user_name, 'Valued User'),
            'plan_name', v_plan_name
          )::text,
          'pending'
        );
      END IF;

      -- 3. Automatically activate subscription inside user_subscriptions!
      INSERT INTO public.user_subscriptions (user_id, plan_code, status, payment_status, start_date, expiry_date, approved_at, approved_by, updated_at)
      VALUES (
        NEW.user_id,
        NEW.plan_name,
        'active',
        'completed',
        NOW(),
        NOW() + INTERVAL '1 year',
        NOW(),
        auth.uid(),
        NOW()
      ) ON CONFLICT (user_id) DO UPDATE SET
        plan_code = EXCLUDED.plan_code,
        status = 'active',
        payment_status = 'completed',
        start_date = NOW(),
        expiry_date = NOW() + INTERVAL '1 year',
        approved_at = NOW(),
        approved_by = COALESCE(EXCLUDED.approved_by, public.user_subscriptions.approved_by),
        updated_at = NOW();

    ELSIF NEW.status = 'rejected' THEN
      -- 1. Create dashboard notification
      INSERT INTO public.notifications (user_id, title, message, type)
      VALUES (
        NEW.user_id,
        '❌ Subscription Upgrade Rejected',
        COALESCE(NEW.rejection_reason, 'Your subscription request was rejected. Please contact support for assistance.'),
        'error'
      );

      -- 2. Queue Rejection Email
      IF v_user_email IS NOT NULL AND v_user_email <> '' THEN
        INSERT INTO public.email_logs (user_id, email, subject, body, status)
        VALUES (
          NEW.user_id,
          v_user_email,
          'Subscription Request Update',
          json_build_object(
            'template', 'subscription_rejected',
            'name', COALESCE(v_user_name, 'Valued User'),
            'plan_name', v_plan_name,
            'reason', COALESCE(NEW.rejection_reason, 'Payment verification failed.')
          )::text,
          'pending'
        );
      END IF;

    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_subscription_request_updated ON public.subscription_requests;
CREATE TRIGGER trg_subscription_request_updated
  AFTER UPDATE ON public.subscription_requests
  FOR EACH ROW EXECUTE FUNCTION public.handle_subscription_request_updated();

-- ─── 13. AUTOMATED REMINDER PROCESSORS ──────────────────────────

-- Free Plan Upgrade Reminder (Runs every 10 days per user)
CREATE OR REPLACE FUNCTION public.process_free_plan_reminders()
RETURNS VOID AS $$
DECLARE
  v_user RECORD;
BEGIN
  FOR v_user IN
    SELECT us.user_id, up.email, up.full_name
    FROM public.user_subscriptions us
    JOIN public.user_profiles up ON us.user_id = up.id
    LEFT JOIN public.free_plan_reminders fpr ON us.user_id = fpr.user_id
    WHERE us.plan_code = 'basic'
      AND us.status = 'active'
      AND (fpr.last_sent_at IS NULL OR fpr.last_sent_at < NOW() - INTERVAL '10 days')
  LOOP
    -- 1. Insert/Update free_plan_reminders tracking
    INSERT INTO public.free_plan_reminders (user_id, last_sent_at, reminder_count)
    VALUES (v_user.user_id, NOW(), 1)
    ON CONFLICT (user_id) DO UPDATE SET
      last_sent_at = NOW(),
      reminder_count = public.free_plan_reminders.reminder_count + 1;

    -- 2. Create dashboard notification
    INSERT INTO public.notifications (user_id, title, message, type)
    VALUES (
      v_user.user_id,
      '🚀 Grow Your Business',
      'Upgrade to a premium plan to unlock advanced business features and benefits.',
      'info'
    );

    -- 3. Queue upgrade reminder email
    INSERT INTO public.email_logs (user_id, email, subject, body, status)
    VALUES (
      v_user.user_id,
      v_user.email,
      'Upgrade to Smart Saoji Premium 🚀',
      json_build_object(
        'template', 'upgrade_reminder',
        'name', COALESCE(v_user.full_name, 'Valued User')
      )::text,
      'pending'
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Clear reminders immediately on upgrade
CREATE OR REPLACE FUNCTION public.handle_subscription_plan_upgraded()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.plan_code = 'basic' AND NEW.plan_code != 'basic' THEN
    DELETE FROM public.free_plan_reminders WHERE user_id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_subscription_plan_upgraded ON public.user_subscriptions;
CREATE TRIGGER trg_subscription_plan_upgraded
  AFTER UPDATE ON public.user_subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.handle_subscription_plan_upgraded();

-- Subscription Expiry Reminders
CREATE OR REPLACE FUNCTION public.process_subscription_expiry_reminders()
RETURNS VOID AS $$
DECLARE
  v_user RECORD;
  v_reminder_type TEXT;
  v_days_left INT;
  v_months_passed INT;
BEGIN
  FOR v_user IN
    SELECT us.user_id, us.start_date, us.expiry_date, up.email, up.full_name
    FROM public.user_subscriptions us
    JOIN public.user_profiles up ON us.user_id = up.id
    WHERE us.plan_code != 'basic'
      AND us.status = 'active'
      AND us.expiry_date IS NOT NULL
  LOOP
    v_days_left := EXTRACT(DAY FROM (v_user.expiry_date - NOW()))::INT;
    v_months_passed := (EXTRACT(YEAR FROM AGE(NOW(), v_user.start_date)) * 12 + EXTRACT(MONTH FROM AGE(NOW(), v_user.start_date)))::INT;

    v_reminder_type := NULL;

    -- Expiry triggers
    IF v_days_left <= 1 AND v_days_left >= 0 THEN
      v_reminder_type := '1_day_before';
    ELSIF v_days_left <= 5 AND v_days_left > 1 THEN
      v_reminder_type := '5_days_before';
    ELSIF v_days_left <= 10 AND v_days_left > 5 THEN
      v_reminder_type := '10_days_before';
    ELSIF v_months_passed = 11 AND v_days_left > 10 THEN
      v_reminder_type := '11_months_after';
    ELSIF v_months_passed = 10 AND v_days_left > 30 THEN
      v_reminder_type := '10_months_after';
    ELSIF v_months_passed = 6 AND v_months_passed < 7 THEN
      v_reminder_type := '6_months_after';
    END IF;

    IF v_reminder_type IS NOT NULL THEN
      IF NOT EXISTS (
        SELECT 1 FROM public.subscription_reminder_logs
        WHERE user_id = v_user.user_id 
          AND reminder_type = v_reminder_type
      ) THEN
        -- Log reminder
        INSERT INTO public.subscription_reminder_logs (user_id, reminder_type)
        VALUES (v_user.user_id, v_reminder_type);

        -- Create dashboard notification
        INSERT INTO public.notifications (user_id, title, message, type)
        VALUES (
          v_user.user_id,
          '⚠️ Subscription Expiring Soon',
          'Your subscription is approaching expiration. Please renew to continue uninterrupted access.',
          'warning'
        );

        -- Queue email
        INSERT INTO public.email_logs (user_id, email, subject, body, status)
        VALUES (
          v_user.user_id,
          v_user.email,
          'Subscription Expiration Notice ⚠️',
          json_build_object(
            'template', 'expiry_reminder',
            'name', COALESCE(v_user.full_name, 'Valued User'),
            'days_left', v_days_left
          )::text,
          'pending'
        );
      END IF;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── 14. SCHEDULING (pg_cron) ──────────────────────────────────
-- Setup cron jobs. Supabase pre-installs pg_cron under `cron` schema.

-- Free plan reminders daily at midnight
SELECT cron.schedule(
  'free-plan-reminders-job',
  '0 0 * * *',
  $$SELECT public.process_free_plan_reminders();$$
);

-- Expiry reminders daily at midnight
SELECT cron.schedule(
  'subscription-expiry-reminders-job',
  '0 0 * * *',
  $$SELECT public.process_subscription_expiry_reminders();$$
);

-- Delete old read notifications older than 30 days daily at 1 AM
SELECT cron.schedule(
  'notifications-cleanup-job',
  '0 1 * * *',
  $$DELETE FROM public.notifications WHERE is_read = TRUE AND created_at < NOW() - INTERVAL '30 days';$$
);

-- ─── 15. DYNAMIC EDGE FUNCTION INTEGRATION (pg_net) ──────────────

-- System Settings for API credentials
CREATE TABLE IF NOT EXISTS public.system_settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- Allow admins to configure settings
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can manage system_settings" ON public.system_settings;
CREATE POLICY "Admins can manage system_settings" ON public.system_settings
  USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());

-- Helper to get settings
CREATE OR REPLACE FUNCTION public.get_system_setting(p_key TEXT)
RETURNS TEXT AS $$
DECLARE
  v_val TEXT;
BEGIN
  SELECT value INTO v_val FROM public.system_settings WHERE key = p_key;
  RETURN v_val;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the Deno send-email edge function
CREATE OR REPLACE FUNCTION public.trigger_email_queue_processing()
RETURNS VOID AS $$
DECLARE
  v_url TEXT;
  v_key TEXT;
BEGIN
  v_url := public.get_system_setting('supabase_url');
  v_key := public.get_system_setting('service_role_key');
  
  IF v_url IS NOT NULL AND v_key IS NOT NULL THEN
    PERFORM net.http_post(
      url := v_url || '/functions/v1/send-email',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || v_key
      ),
      body := '{"action": "process_queue"}'::jsonb
    );
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to process email queue immediately when a pending email is logged
CREATE OR REPLACE FUNCTION public.trg_process_queue_on_pending()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'pending' THEN
    PERFORM public.trigger_email_queue_processing();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_email_logs_process_queue ON public.email_logs;
CREATE TRIGGER trg_email_logs_process_queue
  AFTER INSERT ON public.email_logs
  FOR EACH ROW EXECUTE FUNCTION public.trg_process_queue_on_pending();

-- Schedule email queue processing every 1 minute as fallback
SELECT cron.schedule(
  'email-queue-processor-job',
  '* * * * *',
  $$SELECT public.trigger_email_queue_processing();$$
);

-- ─── 16. STORAGE BUCKET FOR RECEIPTS ─────────────────────────────
-- Create the receipt-images bucket if it does not exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('receipt-images', 'receipt-images', true)
ON CONFLICT (id) DO NOTHING;

-- RLS policies for receipt-images bucket
DROP POLICY IF EXISTS "Allow authenticated uploads to receipt-images" ON storage.objects;
CREATE POLICY "Allow authenticated uploads to receipt-images" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'receipt-images');

DROP POLICY IF EXISTS "Allow public read from receipt-images" ON storage.objects;
CREATE POLICY "Allow public read from receipt-images" ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'receipt-images');


