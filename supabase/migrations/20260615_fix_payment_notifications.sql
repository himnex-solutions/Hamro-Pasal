-- ============================================================
-- FIX: Unified Subscription Notification Triggers on payment_requests
-- Handles BOTH Insert (new request submitted) and Update (approved/rejected)
-- ============================================================

-- ── 1. SUBMISSION TRIGGER (INSERT) ─────────────────────────
CREATE OR REPLACE FUNCTION public.handle_payment_request_inserted()
RETURNS TRIGGER AS $$
DECLARE
  v_user_email  TEXT;
  v_user_name   TEXT;
  v_admin_email TEXT;
  v_plan_name   TEXT;
  v_admin_count INT := 0;
BEGIN
  -- Get user info
  SELECT email, full_name INTO v_user_email, v_user_name
  FROM public.user_profiles WHERE id = NEW.user_id;

  v_plan_name := INITCAP(COALESCE(NEW.plan_code, ''));

  -- A. User dashboard notification
  INSERT INTO public.notifications (user_id, title, message, type) VALUES (
    NEW.user_id,
    'Subscription Request Received ⏳',
    'Your subscription request has been received and is pending verification.',
    'info'
  );

  -- B. User confirmation email
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

  -- C. Email to every admin in the system
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
    v_admin_count := v_admin_count + 1;
  END LOOP;

  -- Fallback: If no admins are set up in user_profiles, email the main contact address
  IF v_admin_count = 0 THEN
    INSERT INTO public.email_logs (user_id, email, subject, body, status) VALUES (
      NEW.user_id, 'smartsaoji@gmail.com',
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
  END IF;

  -- D. Dashboard notification for every admin
  INSERT INTO public.notifications (user_id, title, message, type)
  SELECT id,
    'New Subscription Request ⏳',
    COALESCE(v_user_name, 'A user') || ' requested upgrade to ' || v_plan_name || '.',
    'info'
  FROM public.user_profiles WHERE is_admin = TRUE;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger on INSERT
DROP TRIGGER IF EXISTS trg_payment_request_inserted ON public.payment_requests;
CREATE TRIGGER trg_payment_request_inserted
  AFTER INSERT ON public.payment_requests
  FOR EACH ROW EXECUTE FUNCTION public.handle_payment_request_inserted();


-- ── 2. APPROVAL/REJECTION TRIGGER (UPDATE) ──────────────────
CREATE OR REPLACE FUNCTION public.handle_payment_request_status_updated()
RETURNS TRIGGER AS $$
DECLARE
  v_user_email TEXT;
  v_user_name  TEXT;
  v_plan_name  TEXT;
BEGIN
  -- Only act when status actually changes
  IF OLD.status IS NOT DISTINCT FROM NEW.status THEN
    RETURN NEW;
  END IF;

  -- Fetch user profile
  SELECT email, full_name
  INTO   v_user_email, v_user_name
  FROM   public.user_profiles
  WHERE  id = NEW.user_id;

  v_plan_name := INITCAP(COALESCE(NEW.plan_code, ''));

  -- ── APPROVED ────────────────────────────────────────────────
  IF NEW.status = 'approved' THEN

    -- 1. In-app notification for user
    INSERT INTO public.notifications (user_id, title, message, type)
    VALUES (
      NEW.user_id,
      '🎉 Subscription Approved!',
      'Your ' || v_plan_name || ' subscription is now active. Welcome aboard!',
      'success'
    )
    ON CONFLICT DO NOTHING;

    -- 2. Queue approval email
    IF v_user_email IS NOT NULL AND v_user_email <> '' THEN
      IF NOT EXISTS (
        SELECT 1 FROM public.email_logs
        WHERE  user_id = NEW.user_id
          AND  subject  = 'Subscription Request Approved 🎉'
          AND  created_at > NOW() - INTERVAL '1 hour'
      ) THEN
        INSERT INTO public.email_logs (user_id, email, subject, body, status)
        VALUES (
          NEW.user_id,
          v_user_email,
          'Subscription Request Approved 🎉',
          json_build_object(
            'template',   'subscription_approved',
            'name',       COALESCE(v_user_name, 'Valued User'),
            'plan_name',  v_plan_name
          )::text,
          'pending'
        );
      END IF;
    END IF;

  -- ── REJECTED ────────────────────────────────────────────────
  ELSIF NEW.status = 'rejected' THEN

    -- 1. In-app notification for user
    INSERT INTO public.notifications (user_id, title, message, type)
    VALUES (
      NEW.user_id,
      '❌ Subscription Upgrade Rejected',
      COALESCE(NEW.rejection_reason, 'Your subscription request was rejected. Please contact support.'),
      'error'
    )
    ON CONFLICT DO NOTHING;

    -- 2. Queue rejection email
    IF v_user_email IS NOT NULL AND v_user_email <> '' THEN
      IF NOT EXISTS (
        SELECT 1 FROM public.email_logs
        WHERE  user_id = NEW.user_id
          AND  subject  = 'Subscription Request Update'
          AND  created_at > NOW() - INTERVAL '1 hour'
      ) THEN
        INSERT INTO public.email_logs (user_id, email, subject, body, status)
        VALUES (
          NEW.user_id,
          v_user_email,
          'Subscription Request Update',
          json_build_object(
            'template',  'subscription_rejected',
            'name',      COALESCE(v_user_name, 'Valued User'),
            'plan_name', v_plan_name,
            'reason',    COALESCE(NEW.rejection_reason, 'Payment verification failed.')
          )::text,
          'pending'
        );
      END IF;
    END IF;

  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger on UPDATE
DROP TRIGGER IF EXISTS trg_payment_request_status_updated ON public.payment_requests;
CREATE TRIGGER trg_payment_request_status_updated
  AFTER UPDATE ON public.payment_requests
  FOR EACH ROW EXECUTE FUNCTION public.handle_payment_request_status_updated();


-- ── 3. POPULATE SYSTEM SETTINGS ──────────────────────────────
INSERT INTO public.system_settings (key, value) VALUES
  ('supabase_url',      'https://dgevkedwjmyggclnjbal.supabase.co'),
  ('service_role_key',  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRnZXZrZWR3am15Z2djbG5qYmFsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NzgxNzEwNSwiZXhwIjoyMDkzMzkzMTA1fQ.lG1A_00j5UBmY2mUgA8eTh1NVX0If8WK717w_bmF5kE')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
