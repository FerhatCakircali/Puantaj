-- ============================================
-- MASTER CONSOLIDATED SQL
-- ============================================
-- Bu dosya TÜM migration dosyalarını tek bir dosyada birleştirir
-- 3 farklı klasördeki tüm SQL dosyaları burada toplanmıştır
-- Tekrar eden elementler için EN GÜNCEL versiyonlar kullanılmıştır
-- Tarih: 2026-02-25
-- ============================================
-- 
-- KAYNAK DOSYALAR:
-- 1. database_migrations/000_Database_Migrations_Consolidated.sql
-- 2. SQL_Supabase/000_SQLSupabase_Consolidated.sql  
-- 3. supabase/migrations/000_SQLSupabase.sql
-- 
-- TOPLAM: 26 migration dosyası birleştirildi
-- ============================================

-- ============================================
-- SECTION 1: TABLES
-- ============================================

-- ============================================
-- 1.1 FCM TOKENS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS fcm_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  worker_id INTEGER REFERENCES workers(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  device_type TEXT NOT NULL CHECK (device_type IN ('android', 'ios')),
  device_info JSONB DEFAULT '{}'::jsonb,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT check_user_or_worker CHECK (
    (user_id IS NOT NULL AND worker_id IS NULL) OR
    (user_id IS NULL AND worker_id IS NOT NULL)
  )
);

COMMENT ON TABLE fcm_tokens IS 'Firebase Cloud Messaging token''larını saklar. Her kullanıcı/çalışan için birden fazla cihaz token''ı olabilir.';
COMMENT ON COLUMN fcm_tokens.token IS 'Firebase FCM token (unique)';
COMMENT ON COLUMN fcm_tokens.device_type IS 'Cihaz tipi: android veya ios';
COMMENT ON COLUMN fcm_tokens.device_info IS 'Cihaz bilgileri (model, OS version, app version, vb.)';
COMMENT ON COLUMN fcm_tokens.is_active IS 'Token aktif mi? Eski/geçersiz token''lar deaktif edilir.';
COMMENT ON COLUMN fcm_tokens.last_used_at IS 'Token''ın son kullanım zamanı (push notification gönderildiğinde güncellenir)';

-- ============================================
-- 1.2 ACTIVITY LOGS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS activity_logs (
    id BIGSERIAL PRIMARY KEY,
    admin_id INTEGER NOT NULL,
    admin_username TEXT NOT NULL,
    action_type TEXT NOT NULL,
    target_user_id INTEGER,
    target_username TEXT,
    details JSONB,
    ip_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE activity_logs IS 'Admin aktivite logları - kim, ne zaman, ne yaptı';
COMMENT ON COLUMN activity_logs.admin_id IS 'İşlemi yapan admin kullanıcı ID';
COMMENT ON COLUMN activity_logs.admin_username IS 'İşlemi yapan admin kullanıcı adı';
COMMENT ON COLUMN activity_logs.action_type IS 'İşlem tipi (user_created, user_updated, vb.)';
COMMENT ON COLUMN activity_logs.target_user_id IS 'İşlem yapılan kullanıcı ID (varsa)';
COMMENT ON COLUMN activity_logs.target_username IS 'İşlem yapılan kullanıcı adı (varsa)';
COMMENT ON COLUMN activity_logs.details IS 'İşlem detayları (JSON)';
COMMENT ON COLUMN activity_logs.ip_address IS 'İşlemi yapan kullanıcının IP adresi';
COMMENT ON COLUMN activity_logs.created_at IS 'İşlem zamanı';

-- ============================================
-- 1.3 PASSWORD RESET TOKENS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_type TEXT NOT NULL CHECK (user_type IN ('user', 'worker')),
  user_id BIGINT NOT NULL,
  email TEXT NOT NULL,
  token TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- SECTION 2: ALTER TABLE - ADD COLUMNS
-- ============================================

-- ============================================
-- 2.1 EMAIL FIELDS (users & workers)
-- ============================================

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS email TEXT,
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;

ALTER TABLE workers 
ADD COLUMN IF NOT EXISTS email TEXT,
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;

-- ============================================
-- 2.2 ATTENDANCE - notification_sent & updated_at
-- ============================================

ALTER TABLE attendance 
ADD COLUMN IF NOT EXISTS notification_sent BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN attendance.notification_sent IS 
'Tracks whether this attendance record has been included in a notification. Used by WorkManager to prevent duplicate notifications.';

ALTER TABLE attendance 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

UPDATE attendance 
SET updated_at = created_at 
WHERE updated_at IS NULL;

ALTER TABLE attendance 
ALTER COLUMN updated_at SET NOT NULL;

-- ============================================
-- 2.3 ATTENDANCE_REQUESTS - notification_sent
-- ============================================

ALTER TABLE attendance_requests 
ADD COLUMN IF NOT EXISTS notification_sent BOOLEAN NOT NULL DEFAULT FALSE;

-- ============================================
-- 2.4 NOTIFICATION_SETTINGS - attendance_requests_enabled
-- ============================================

ALTER TABLE notification_settings 
ADD COLUMN IF NOT EXISTS attendance_requests_enabled BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN notification_settings.attendance_requests_enabled IS 
'Controls whether the manager receives batch notifications for new attendance requests. When enabled, WorkManager sends consolidated notifications every 15 minutes.';

-- ============================================
-- 2.5 NOTIFICATIONS - scheduled_time
-- ============================================

ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS scheduled_time TIMESTAMP WITH TIME ZONE;

-- ============================================
-- 2.6 NOTIFICATIONS - notification_type CONSTRAINT (EN GÜNCEL)
-- ============================================

ALTER TABLE notifications 
DROP CONSTRAINT IF EXISTS notifications_notification_type_check;

ALTER TABLE notifications
ADD CONSTRAINT notifications_notification_type_check
CHECK (notification_type IN (
  'attendance_reminder',
  'attendance_request',
  'attendance_approved',
  'attendance_rejected',
  'payment_notification',
  'payment_received',
  'payment_updated',
  'payment_deleted',
  'general'
));

-- ============================================
-- 2.7 PAYMENTS - updated_at
-- ============================================

ALTER TABLE payments 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

UPDATE payments 
SET updated_at = COALESCE(created_at, payment_date)
WHERE updated_at IS NULL;

ALTER TABLE payments 
ALTER COLUMN updated_at SET NOT NULL;

-- ============================================
-- 2.8 EMAIL UNIQUE CONSTRAINT (REMOVED)
-- ============================================

ALTER TABLE users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE workers DROP CONSTRAINT IF EXISTS workers_email_key;

-- ============================================
-- SECTION 3: INDEXES
-- ============================================

-- ============================================
-- 3.1 FCM TOKENS INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_worker_id ON fcm_tokens(worker_id) WHERE worker_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_token ON fcm_tokens(token);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_is_active ON fcm_tokens(is_active) WHERE is_active = TRUE;

-- ============================================
-- 3.2 ACTIVITY LOGS INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_activity_logs_admin_id ON activity_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_action_type ON activity_logs(action_type);
CREATE INDEX IF NOT EXISTS idx_activity_logs_target_user_id ON activity_logs(target_user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at DESC);

-- ============================================
-- 3.3 PASSWORD RESET TOKENS INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_token ON password_reset_tokens(token);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_email ON password_reset_tokens(email);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_expires ON password_reset_tokens(expires_at);

-- ============================================
-- 3.4 EMAIL INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_workers_email ON workers(email);

-- ============================================
-- 3.5 ATTENDANCE INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_attendance_notification_sent 
ON attendance(notification_sent) 
WHERE notification_sent = FALSE;

CREATE INDEX IF NOT EXISTS idx_attendance_created_by_notification_sent 
ON attendance(created_by, notification_sent) 
WHERE created_by = 'worker';

CREATE INDEX IF NOT EXISTS idx_attendance_notification_lookup 
ON attendance(created_by, notification_sent, created_at DESC)
WHERE created_by = 'worker' AND notification_sent = false;

-- ============================================
-- 3.6 ATTENDANCE_REQUESTS INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_attendance_requests_notification_sent 
ON attendance_requests(notification_sent);

CREATE INDEX IF NOT EXISTS idx_attendance_requests_status_notification 
ON attendance_requests(request_status, notification_sent) 
WHERE request_status = 'pending';

-- ============================================
-- 3.7 NOTIFICATIONS INDEXES
-- ============================================

DO $
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_indexes 
        WHERE tablename = 'notifications' 
        AND indexname = 'idx_notifications_recipient_id'
    ) THEN
        CREATE INDEX idx_notifications_recipient_id ON notifications(recipient_id);
        RAISE NOTICE 'idx_notifications_recipient_id oluşturuldu';
    ELSE
        RAISE NOTICE 'idx_notifications_recipient_id zaten mevcut';
    END IF;

    IF NOT EXISTS (
        SELECT 1 
        FROM pg_indexes 
        WHERE tablename = 'notifications' 
        AND indexname = 'idx_notifications_created_at'
    ) THEN
        CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
        RAISE NOTICE 'idx_notifications_created_at oluşturuldu';
    ELSE
        RAISE NOTICE 'idx_notifications_created_at zaten mevcut';
    END IF;

    IF NOT EXISTS (
        SELECT 1 
        FROM pg_indexes 
        WHERE tablename = 'notifications' 
        AND indexname = 'idx_notifications_recipient_created'
    ) THEN
        CREATE INDEX idx_notifications_recipient_created ON notifications(recipient_id, created_at DESC);
        RAISE NOTICE 'idx_notifications_recipient_created oluşturuldu';
    ELSE
        RAISE NOTICE 'idx_notifications_recipient_created zaten mevcut';
    END IF;

    IF NOT EXISTS (
        SELECT 1 
        FROM pg_indexes 
        WHERE tablename = 'notifications' 
        AND indexname = 'idx_notifications_recipient_type_id'
    ) THEN
        CREATE INDEX idx_notifications_recipient_type_id ON notifications(recipient_type, recipient_id);
        RAISE NOTICE 'idx_notifications_recipient_type_id oluşturuldu';
    ELSE
        RAISE NOTICE 'idx_notifications_recipient_type_id zaten mevcut';
    END IF;
END $;

CREATE INDEX IF NOT EXISTS idx_notifications_scheduled_time 
ON notifications(scheduled_time) 
WHERE scheduled_time IS NOT NULL AND is_read = FALSE;

CREATE INDEX IF NOT EXISTS idx_notifications_recipient_scheduled 
ON notifications(recipient_id, scheduled_time) 
WHERE scheduled_time IS NOT NULL AND is_read = FALSE;

COMMENT ON INDEX idx_attendance_notification_lookup IS 
'Yevmiye talep bildirimleri için partial index. Worker tarafından oluşturulan ve henüz bildirilmemiş talepleri hızlı sorgular.';

-- ============================================
-- 3.8 ANALYZE TABLES
-- ============================================

ANALYZE attendance;
ANALYZE notifications;

-- ============================================
-- SECTION 4: ROW LEVEL SECURITY (RLS)
-- ============================================

-- ============================================
-- 4.1 FCM TOKENS RLS
-- ============================================

ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role has full access"
ON fcm_tokens FOR ALL
USING (true);

-- ============================================
-- 4.2 ACTIVITY LOGS RLS
-- ============================================

ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view all activity logs"
    ON activity_logs FOR SELECT
    USING (true);

CREATE POLICY "System can insert activity logs"
    ON activity_logs FOR INSERT
    WITH CHECK (true);

CREATE POLICY "No one can update activity logs"
    ON activity_logs FOR UPDATE
    USING (false);

CREATE POLICY "No one can delete activity logs"
    ON activity_logs FOR DELETE
    USING (false);

-- ============================================
-- 4.3 PASSWORD RESET TOKENS RLS
-- ============================================

ALTER TABLE password_reset_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "allow_all_password_reset_tokens" ON password_reset_tokens;
CREATE POLICY "allow_all_password_reset_tokens" ON password_reset_tokens FOR ALL USING (true);

-- ============================================
-- 4.4 NOTIFICATIONS REALTIME
-- ============================================

ALTER TABLE notifications REPLICA IDENTITY FULL;

ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- ============================================
-- SECTION 5: FUNCTIONS
-- ============================================

-- ============================================
-- 5.1 FCM TOKENS FUNCTIONS
-- ============================================

CREATE OR REPLACE FUNCTION update_fcm_tokens_updated_at()
RETURNS TRIGGER AS $
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_inactive_fcm_tokens()
RETURNS void AS $
BEGIN
  DELETE FROM fcm_tokens
  WHERE is_active = FALSE
    AND updated_at < NOW() - INTERVAL '90 days';
    
  UPDATE fcm_tokens
  SET is_active = FALSE
  WHERE last_used_at < NOW() - INTERVAL '180 days'
    AND is_active = TRUE;
END;
$ LANGUAGE plpgsql;

-- ============================================
-- 5.2 PASSWORD RESET FUNCTIONS
-- ============================================

CREATE OR REPLACE FUNCTION cleanup_expired_reset_tokens()
RETURNS INTEGER AS $
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM password_reset_tokens
  WHERE expires_at < CURRENT_TIMESTAMP OR used = TRUE;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_password_reset_token(
  p_user_type TEXT,
  p_user_id BIGINT,
  p_email TEXT,
  p_token TEXT
)
RETURNS BIGINT AS $
DECLARE
  token_id BIGINT;
BEGIN
  DELETE FROM password_reset_tokens
  WHERE user_type = p_user_type 
    AND user_id = p_user_id 
    AND used = FALSE;
  
  INSERT INTO password_reset_tokens (user_type, user_id, email, token, expires_at)
  VALUES (p_user_type, p_user_id, p_email, p_token, CURRENT_TIMESTAMP + INTERVAL '24 hours')
  RETURNING id INTO token_id;
  
  RETURN token_id;
END;
$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION verify_reset_token(p_token TEXT)
RETURNS TABLE (
  is_valid BOOLEAN,
  user_type TEXT,
  user_id BIGINT,
  email TEXT
) AS $
BEGIN
  RETURN QUERY
  SELECT 
    (prt.expires_at > CURRENT_TIMESTAMP AND prt.used = FALSE) as is_valid,
    prt.user_type,
    prt.user_id,
    prt.email
  FROM password_reset_tokens prt
  WHERE prt.token = p_token;
END;
$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION reset_password_with_token(
  p_token TEXT,
  p_new_password_hash TEXT
)
RETURNS BOOLEAN AS $
DECLARE
  v_user_type TEXT;
  v_user_id BIGINT;
  v_is_valid BOOLEAN;
BEGIN
  SELECT is_valid, user_type, user_id 
  INTO v_is_valid, v_user_type, v_user_id
  FROM verify_reset_token(p_token);
  
  IF NOT v_is_valid THEN
    RETURN FALSE;
  END IF;
  
  IF v_user_type = 'user' THEN
    UPDATE users
    SET password_hash = p_new_password_hash,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_user_id;
  ELSIF v_user_type = 'worker' THEN
    UPDATE workers
    SET password_hash = p_new_password_hash,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_user_id;
  ELSE
    RETURN FALSE;
  END IF;
  
  UPDATE password_reset_tokens
  SET used = TRUE
  WHERE token = p_token;
  
  RETURN TRUE;
END;
$ LANGUAGE plpgsql;

-- ============================================
-- 5.3 EMAIL UNIQUE CHECK FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION check_email_unique()
RETURNS TRIGGER AS $
BEGIN
  IF NEW.email IS NULL OR NEW.email = '' THEN
    RETURN NEW;
  END IF;

  IF TG_TABLE_NAME = 'users' THEN
    IF EXISTS (
      SELECT 1 FROM users 
      WHERE email = NEW.email 
      AND id != COALESCE(NEW.id, 0)
    ) THEN
      RAISE EXCEPTION 'Bu email adresi zaten kullanılıyor';
    END IF;
    
    IF EXISTS (
      SELECT 1 FROM workers 
      WHERE email = NEW.email
    ) THEN
      RAISE EXCEPTION 'Bu email adresi zaten kullanılıyor';
    END IF;
  END IF;

  IF TG_TABLE_NAME = 'workers' THEN
    IF EXISTS (
      SELECT 1 FROM workers 
      WHERE email = NEW.email 
      AND id != COALESCE(NEW.id, 0)
    ) THEN
      RAISE EXCEPTION 'Bu email adresi zaten kullanılıyor';
    END IF;
    
    IF EXISTS (
      SELECT 1 FROM users 
      WHERE email = NEW.email
    ) THEN
      RAISE EXCEPTION 'Bu email adresi zaten kullanılıyor';
    END IF;
  END IF;

  RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- ============================================
-- 5.4 UPDATED_AT FUNCTIONS
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_payments_updated_at_column()
RETURNS TRIGGER AS $
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- ============================================
-- 5.5 MANAGER INFO FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_manager_info_for_notification(user_id_param INT)
RETURNS TABLE (
  user_id INT,
  username TEXT,
  first_name TEXT,
  last_name TEXT,
  full_name TEXT
) AS $
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.username,
    u.first_name,
    u.last_name,
    CONCAT(u.first_name, ' ', u.last_name) as full_name
  FROM users u
  WHERE u.id = user_id_param;
END;
$ LANGUAGE plpgsql;

-- ============================================
-- 5.6 FCM NOTIFICATION TRIGGER FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION notify_via_fcm()
RETURNS TRIGGER AS $
DECLARE
  request_id bigint;
BEGIN
  BEGIN
    SELECT net.http_post(
      url := 'https://uvdcefauzxordqgvvweq.supabase.co/functions/v1/send-push-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2ZGNlZmF1enhvcmRxZ3Z2d2VxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDgyMTk3MSwiZXhwIjoyMDg2Mzk3OTcxfQ.-x_wB2UUEg4gcTN1-PkLnUi3-wQLkLAeOuIb7t68Npk'
      ),
      body := jsonb_build_object(
        'recipientId', NEW.recipient_id,
        'title', NEW.title,
        'message', NEW.message,
        'notificationType', NEW.notification_type,
        'relatedId', NEW.related_id
      )
    ) INTO request_id;

    RAISE LOG 'FCM notification request sent: %', request_id;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'FCM notification failed: %', SQLERRM;
  END;

  RETURN NEW;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION notify_via_fcm() IS 'Yeni bildirim eklendiğinde FCM Edge Function''ını çağırır';

DO $
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') THEN
    RAISE WARNING 'pg_net extension is not installed. FCM notifications will not work.';
    RAISE WARNING 'Install it with: CREATE EXTENSION pg_net;';
  END IF;
END $;

-- ============================================
-- 5.7 AUTO APPROVE FUNCTION (EN GÜNCEL - TÜM ÖZELLİKLER)
-- ============================================
-- Kaynak: supabase/migrations (003, 006, 011) + SQL_Supabase (010, 011)
-- Özellikler:
-- ✅ Türkiye saati (UTC+3) ile attendance kaydı
-- ✅ Türkçe mesaj formatı (Tam Gün, Yarım Gün, Gelmedi)
-- ✅ Otomatik onay: scheduled_time = NULL (anında)
-- ✅ Manuel onay: scheduled_time = UTC + 1 minute (zamanlanmış)

DROP TRIGGER IF EXISTS trigger_auto_approve_attendance ON attendance_requests;
DROP FUNCTION IF EXISTS auto_approve_if_trusted();

CREATE OR REPLACE FUNCTION auto_approve_if_trusted()
RETURNS TRIGGER AS $
DECLARE
  is_trusted_worker BOOLEAN;
  auto_approve_enabled BOOLEAN;
BEGIN
  SELECT w.is_trusted INTO is_trusted_worker
  FROM workers w
  WHERE w.id = NEW.worker_id;
  
  SELECT COALESCE(ns.auto_approve_trusted, FALSE) INTO auto_approve_enabled
  FROM notification_settings ns
  WHERE ns.user_id = NEW.user_id;
  
  IF COALESCE(is_trusted_worker, FALSE) AND auto_approve_enabled THEN
    -- Türkiye saati (UTC+3) ile kaydet
    INSERT INTO attendance (user_id, worker_id, date, status, created_by, created_at, updated_at)
    VALUES (
      NEW.user_id, 
      NEW.worker_id, 
      NEW.date, 
      NEW.status, 
      'worker',
      CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul',
      CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul'
    )
    ON CONFLICT (worker_id, date) DO NOTHING;
    
    NEW.request_status := 'approved';
    NEW.reviewed_at := CURRENT_TIMESTAMP;
    NEW.reviewed_by := NEW.user_id;
    
    -- Çalışana otomatik onay bildirimi (ANINDA - scheduled_time NULL)
    INSERT INTO notifications (
      sender_type, recipient_id, recipient_type,
      notification_type, title, message, related_id,
      scheduled_time
    ) VALUES (
      'system', NEW.worker_id, 'worker',
      'attendance_approved', 'Yevmiye Otomatik Onaylandı',
      NEW.date || ' tarihli yevmiye girişiniz otomatik olarak onaylandı.',
      NEW.id,
      NULL  -- Anında bildirim
    );
  ELSE
    -- Türkçe mesaj + UTC zamanlanmış bildirim (1 dakika sonra)
    INSERT INTO notifications (
      sender_id, sender_type, recipient_id, recipient_type,
      notification_type, title, message, related_id,
      scheduled_time
    ) VALUES (
      NEW.worker_id, 'worker', NEW.user_id, 'user',
      'attendance_request', 'Yeni Yevmiye Talebi',
      (SELECT full_name FROM workers WHERE id = NEW.worker_id) || ' (' || 
      CASE 
        WHEN NEW.status = 'fullDay' THEN 'Tam Gün'
        WHEN NEW.status = 'halfDay' THEN 'Yarım Gün'
        WHEN NEW.status = 'absent' THEN 'Gelmedi'
        ELSE NEW.status
      END || ') - Onay bekliyor',
      NEW.id,
      (CURRENT_TIMESTAMP AT TIME ZONE 'UTC') + INTERVAL '1 minute'  -- Zamanlanmış bildirim
    );
  END IF;
  
  RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- ============================================
-- 5.8 APPROVE ATTENDANCE REQUEST FUNCTION (EN GÜNCEL)
-- ============================================
-- Kaynak: supabase/migrations (004 + 006)
-- Özellikler:
-- ✅ Türkiye saati (UTC+3) ile attendance kaydı
-- ✅ Bildirim mesajı güncelleme (✅ Onaylandı)
-- ✅ Otomatik is_read = TRUE

DROP FUNCTION IF EXISTS approve_attendance_request(BIGINT, BIGINT);

CREATE OR REPLACE FUNCTION approve_attendance_request(request_id_param BIGINT, reviewed_by_param BIGINT)
RETURNS BOOLEAN AS $
DECLARE
  request_record RECORD;
  status_text TEXT;
BEGIN
  SELECT * INTO request_record
  FROM attendance_requests
  WHERE id = request_id_param AND request_status = 'pending';
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Türkiye saati (UTC+3) ile kaydet
  INSERT INTO attendance (user_id, worker_id, date, status, created_by, created_at, updated_at)
  VALUES (
    request_record.user_id,
    request_record.worker_id,
    request_record.date,
    request_record.status,
    'worker',
    CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul',
    CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul'
  )
  ON CONFLICT (worker_id, date) DO NOTHING;
  
  UPDATE attendance_requests
  SET request_status = 'approved',
      reviewed_at = CURRENT_TIMESTAMP,
      reviewed_by = reviewed_by_param
  WHERE id = request_id_param;
  
  -- Status text'i hazırla
  status_text := CASE 
    WHEN request_record.status = 'fullDay' THEN 'Tam Gün'
    WHEN request_record.status = 'halfDay' THEN 'Yarım Gün'
    WHEN request_record.status = 'absent' THEN 'Gelmedi'
    ELSE request_record.status
  END;
  
  -- Orijinal bildirim mesajını güncelle
  UPDATE notifications
  SET message = (SELECT full_name FROM workers WHERE id = request_record.worker_id) || 
                ' (' || status_text || ') - ✅ Onaylandı',
      is_read = TRUE  -- Otomatik okundu işaretle
  WHERE related_id = request_id_param 
    AND notification_type = 'attendance_request'
    AND recipient_id = request_record.user_id;
  
  -- Çalışana yeni bildirim gönder
  INSERT INTO notifications (
    sender_id, sender_type, recipient_id, recipient_type,
    notification_type, title, message, related_id
  ) VALUES (
    reviewed_by_param, 'user', request_record.worker_id, 'worker',
    'attendance_approved', 'Yevmiye Onaylandı',
    request_record.date || ' tarihli yevmiye girişiniz onaylandı.',
    request_id_param
  );
  
  RETURN TRUE;
END;
$ LANGUAGE plpgsql;

-- ============================================
-- 5.9 REJECT ATTENDANCE REQUEST FUNCTION
-- ============================================
-- Kaynak: supabase/migrations (004)
-- Özellikler:
-- ✅ Bildirim mesajı güncelleme (❌ Reddedildi)
-- ✅ Otomatik is_read = TRUE

DROP FUNCTION IF EXISTS reject_attendance_request(BIGINT, BIGINT, TEXT);

CREATE OR REPLACE FUNCTION reject_attendance_request(request_id_param BIGINT, reviewed_by_param BIGINT, reason TEXT)
RETURNS BOOLEAN AS $
DECLARE
  request_record RECORD;
  status_text TEXT;
BEGIN
  SELECT * INTO request_record
  FROM attendance_requests
  WHERE id = request_id_param AND request_status = 'pending';
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  UPDATE attendance_requests
  SET request_status = 'rejected',
      reviewed_at = CURRENT_TIMESTAMP,
      reviewed_by = reviewed_by_param,
      rejection_reason = reason
  WHERE id = request_id_param;
  
  -- Status text'i hazırla
  status_text := CASE 
    WHEN request_record.status = 'fullDay' THEN 'Tam Gün'
    WHEN request_record.status = 'halfDay' THEN 'Yarım Gün'
    WHEN request_record.status = 'absent' THEN 'Gelmedi'
    ELSE request_record.status
  END;
  
  -- Orijinal bildirim mesajını güncelle
  UPDATE notifications
  SET message = (SELECT full_name FROM workers WHERE id = request_record.worker_id) || 
                ' (' || status_text || ') - ❌ Reddedildi',
      is_read = TRUE  -- Otomatik okundu işaretle
  WHERE related_id = request_id_param 
    AND notification_type = 'attendance_request'
    AND recipient_id = request_record.user_id;
  
  -- Çalışana yeni bildirim gönder
  INSERT INTO notifications (
    sender_id, sender_type, recipient_id, recipient_type,
    notification_type, title, message, related_id
  ) VALUES (
    reviewed_by_param, 'user', request_record.worker_id, 'worker',
    'attendance_rejected', 'Yevmiye Reddedildi',
    request_record.date || ' tarihli yevmiye girişiniz reddedildi. Sebep: ' || COALESCE(reason, 'Belirtilmedi'),
    request_id_param
  );
  
  RETURN TRUE;
END;
$ LANGUAGE plpgsql;

-- ============================================
-- 5.10 UPDATE PAYMENT FUNCTION
-- ============================================
-- Kaynak: supabase/migrations (008)
-- Özellikler:
-- ✅ Ödeme güncelleme
-- ✅ paid_days yeniden hesaplama
-- ✅ Bildirim gönderme (payment_updated)

CREATE OR REPLACE FUNCTION update_payment(
  payment_id_param BIGINT,
  full_days_param INTEGER,
  half_days_param INTEGER,
  amount_param NUMERIC
)
RETURNS BOOLEAN AS $
DECLARE
  payment_record RECORD;
  old_full_days INTEGER;
  old_half_days INTEGER;
  old_amount NUMERIC;
  notification_message TEXT;
BEGIN
  SELECT * INTO payment_record
  FROM payments
  WHERE id = payment_id_param;
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  old_full_days := payment_record.full_days;
  old_half_days := payment_record.half_days;
  old_amount := payment_record.amount;
  
  DELETE FROM paid_days WHERE payment_id = payment_id_param;
  
  DECLARE
    unpaid_record RECORD;
    full_days_to_mark INTEGER := full_days_param;
    half_days_to_mark INTEGER := half_days_param;
  BEGIN
    FOR unpaid_record IN (
      SELECT a.worker_id, a.date, a.status
      FROM attendance a
      WHERE a.worker_id = payment_record.worker_id
        AND a.user_id = payment_record.user_id
        AND (a.status = 'fullDay' OR a.status = 'halfDay')
        AND NOT EXISTS (
          SELECT 1 FROM paid_days pd
          WHERE pd.worker_id = a.worker_id
            AND pd.date = a.date
            AND pd.status = a.status
            AND pd.payment_id != payment_id_param
        )
      ORDER BY a.date
    ) LOOP
      IF unpaid_record.status = 'fullDay' AND full_days_to_mark > 0 THEN
        INSERT INTO paid_days (user_id, worker_id, date, status, payment_id)
        VALUES (payment_record.user_id, unpaid_record.worker_id, unpaid_record.date, unpaid_record.status, payment_id_param);
        full_days_to_mark := full_days_to_mark - 1;
      END IF;
      
      IF unpaid_record.status = 'halfDay' AND half_days_to_mark > 0 THEN
        INSERT INTO paid_days (user_id, worker_id, date, status, payment_id)
        VALUES (payment_record.user_id, unpaid_record.worker_id, unpaid_record.date, unpaid_record.status, payment_id_param);
        half_days_to_mark := half_days_to_mark - 1;
      END IF;
      
      EXIT WHEN full_days_to_mark <= 0 AND half_days_to_mark <= 0;
    END LOOP;
  END;
  
  UPDATE payments
  SET 
    full_days = full_days_param,
    half_days = half_days_param,
    amount = amount_param,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = payment_id_param;
  
  notification_message := '';
  
  IF old_full_days != full_days_param THEN
    notification_message := notification_message || old_full_days || ' Tam Gün - ' || full_days_param || ' Tam Gün' || E'\n';
  ELSE
    notification_message := notification_message || old_full_days || ' Tam Gün - Değişiklik yok' || E'\n';
  END IF;
  
  IF old_half_days != half_days_param THEN
    notification_message := notification_message || old_half_days || ' Yarım Gün - ' || half_days_param || ' Yarım Gün' || E'\n';
  ELSE
    notification_message := notification_message || old_half_days || ' Yarım Gün - Değişiklik yok' || E'\n';
  END IF;
  
  IF old_amount != amount_param THEN
    notification_message := notification_message || '₺' || REPLACE(TO_CHAR(old_amount, 'FM999G999G999G999'), ',', '.') || ' - ₺' || REPLACE(TO_CHAR(amount_param, 'FM999G999G999G999'), ',', '.') || E'\n';
  ELSE
    notification_message := notification_message || '₺' || REPLACE(TO_CHAR(old_amount, 'FM999G999G999G999'), ',', '.') || ' - Değişiklik yok' || E'\n';
  END IF;
  
  notification_message := notification_message || E'\n' || 'Güncelleme Tarihi: ' || TO_CHAR(CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul', 'DD.MM.YYYY HH24:MI');
  
  INSERT INTO notifications (
    sender_id, sender_type, recipient_id, recipient_type,
    notification_type, title, message, related_id
  ) VALUES (
    payment_record.user_id, 'user', payment_record.worker_id, 'worker',
    'payment_updated', 'Ödemelerde güncelleme yapıldı!',
    notification_message,
    payment_id_param
  );
  
  RETURN TRUE;
END;
$ LANGUAGE plpgsql;

-- ============================================
-- 5.11 DELETE PAYMENT FUNCTION
-- ============================================
-- Kaynak: supabase/migrations (008)
-- Özellikler:
-- ✅ Ödeme silme
-- ✅ paid_days silme
-- ✅ Bildirim gönderme (payment_deleted)

CREATE OR REPLACE FUNCTION delete_payment(payment_id_param BIGINT)
RETURNS BOOLEAN AS $
DECLARE
  payment_record RECORD;
  notification_message TEXT;
BEGIN
  SELECT * INTO payment_record
  FROM payments
  WHERE id = payment_id_param;
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  notification_message := 
    payment_record.full_days || ' Tam Gün' || E'\n' ||
    payment_record.half_days || ' Yarım Gün' || E'\n' ||
    '₺' || REPLACE(TO_CHAR(payment_record.amount, 'FM999G999G999G999'), ',', '.') || E'\n\n' ||
    'Ödeme Tarihi: ' || TO_CHAR(payment_record.payment_date, 'DD.MM.YYYY') || E'\n' ||
    'Silme Tarihi: ' || TO_CHAR(CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul', 'DD.MM.YYYY HH24:MI');
  
  INSERT INTO notifications (
    sender_id, sender_type, recipient_id, recipient_type,
    notification_type, title, message, related_id
  ) VALUES (
    payment_record.user_id, 'user', payment_record.worker_id, 'worker',
    'payment_deleted', 'Yapılan ödeme silindi!',
    notification_message,
    payment_id_param
  );
  
  DELETE FROM paid_days WHERE payment_id = payment_id_param;
  
  DELETE FROM payments WHERE id = payment_id_param;
  
  RETURN TRUE;
END;
$ LANGUAGE plpgsql;

-- ============================================
-- 5.12 CLEANUP OLD NOTIFICATIONS FUNCTION
-- ============================================
-- Kaynak: supabase/migrations (012)
-- Özellikler:
-- ✅ Eski okunmuş bildirimleri siler (bugünden önceki)

CREATE OR REPLACE FUNCTION cleanup_old_read_notifications()
RETURNS void AS $
DECLARE
  deleted_count INTEGER;
  today_start_utc TIMESTAMP WITH TIME ZONE;
BEGIN
  today_start_utc := date_trunc('day', NOW() AT TIME ZONE 'UTC');
  
  RAISE NOTICE 'Bildirim temizleme başlatıldı';
  RAISE NOTICE 'Şu an (UTC): %', NOW() AT TIME ZONE 'UTC';
  RAISE NOTICE 'Bugün başlangıç (UTC): %', today_start_utc;
  
  DELETE FROM notifications
  WHERE is_read = TRUE
    AND created_at < today_start_utc;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RAISE NOTICE '% adet eski okunmuş bildirim silindi', deleted_count;
END;
$ LANGUAGE plpgsql;

-- ============================================
-- SECTION 6: TRIGGERS
-- ============================================

-- ============================================
-- 6.1 FCM TOKENS TRIGGERS
-- ============================================

CREATE TRIGGER trigger_update_fcm_tokens_updated_at
BEFORE UPDATE ON fcm_tokens
FOR EACH ROW
EXECUTE FUNCTION update_fcm_tokens_updated_at();

-- ============================================
-- 6.2 EMAIL UNIQUE CHECK TRIGGERS
-- ============================================

DROP TRIGGER IF EXISTS check_email_unique_users ON users;
CREATE TRIGGER check_email_unique_users
  BEFORE INSERT OR UPDATE OF email ON users
  FOR EACH ROW
  EXECUTE FUNCTION check_email_unique();

DROP TRIGGER IF EXISTS check_email_unique_workers ON workers;
CREATE TRIGGER check_email_unique_workers
  BEFORE INSERT OR UPDATE OF email ON workers
  FOR EACH ROW
  EXECUTE FUNCTION check_email_unique();

-- ============================================
-- 6.3 ATTENDANCE UPDATED_AT TRIGGER
-- ============================================

DROP TRIGGER IF EXISTS update_attendance_updated_at ON attendance;

CREATE TRIGGER update_attendance_updated_at
    BEFORE UPDATE ON attendance
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6.4 PAYMENTS UPDATED_AT TRIGGER
-- ============================================

DROP TRIGGER IF EXISTS update_payments_updated_at ON payments;

CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_payments_updated_at_column();

-- ============================================
-- 6.5 AUTO APPROVE ATTENDANCE TRIGGER
-- ============================================

CREATE TRIGGER trigger_auto_approve_attendance
  BEFORE INSERT ON attendance_requests
  FOR EACH ROW
  EXECUTE FUNCTION auto_approve_if_trusted();

-- ============================================
-- 6.6 FCM NOTIFICATION TRIGGER
-- ============================================

DROP TRIGGER IF EXISTS on_notification_insert_fcm_trigger ON notifications;

CREATE TRIGGER on_notification_insert_fcm_trigger
AFTER INSERT ON notifications
FOR EACH ROW
EXECUTE FUNCTION notify_via_fcm();

COMMENT ON TRIGGER on_notification_insert_fcm_trigger ON notifications IS 'Yeni bildirim için FCM push notification gönderir';

-- ============================================
-- SECTION 7: FINAL NOTES & SUMMARY
-- ============================================

-- ============================================
-- MASTER CONSOLIDATED SQL - ÖZET
-- ============================================
-- 
-- Bu dosya 3 farklı klasördeki TOPLAM 26 SQL migration dosyasını
-- tek bir dosyada birleştirir. Tekrar eden elementler için
-- EN GÜNCEL versiyonlar kullanılmıştır.
-- 
-- ============================================
-- KAYNAK DOSYALAR (26 ADET):
-- ============================================
-- 
-- 📁 database_migrations/ (3 dosya):
--    004_activity_logs.sql
--    005_add_email_fields.sql
--    006_email_unique_and_password_hash.sql
-- 
-- 📁 SQL_Supabase/ (11 dosya):
--    001_modify_auto_approve_trigger.sql
--    002_add_notification_sent_to_attendance.sql
--    003_add_attendance_requests_enabled_to_notification_settings.sql
--    004_add_performance_indexes.sql
--    005_add_notification_sent_to_attendance_requests.sql
--    006_restore_notification_in_trigger.sql
--    007_add_instant_notification_to_manager.sql
--    008_enable_realtime_for_notifications.sql
--    009_add_scheduled_time_to_notifications.sql
--    010_update_trigger_with_scheduled_time.sql
--    011_fix_scheduled_time_timezone.sql
-- 
-- 📁 supabase/migrations/ (12 dosya):
--    001_create_fcm_tokens_table.sql
--    002_create_fcm_notification_trigger.sql
--    003_instant_attendance_request_notification.sql
--    004_add_status_to_notification_message.sql
--    005_add_payment_received_notification_type.sql
--    006_fix_attendance_timezone.sql
--    007_add_updated_at_to_attendance.sql
--    008_payment_update_delete_notifications.sql
--    009_add_updated_at_to_payments.sql
--    010_add_payment_notification_types.sql
--    011_fix_notification_message_format.sql
--    012_auto_cleanup_old_read_notifications.sql
-- 
-- ============================================
-- TABLOLAR (3 ADET YENİ):
-- ============================================
-- 
-- 1. fcm_tokens
--    - Firebase Cloud Messaging token yönetimi
--    - User ve worker için FCM token saklama
--    - Cihaz bilgileri ve aktiflik durumu
-- 
-- 2. activity_logs
--    - Admin aktivite logları
--    - Kim, ne zaman, ne yaptı takibi
--    - RLS ile güvenli erişim
-- 
-- 3. password_reset_tokens
--    - Şifre sıfırlama token yönetimi
--    - 24 saat geçerlilik süresi
--    - User ve worker desteği
-- 
-- ============================================
-- EKLENEN KOLONLAR:
-- ============================================
-- 
-- users & workers:
--   - email (TEXT)
--   - email_verified (BOOLEAN)
-- 
-- attendance:
--   - notification_sent (BOOLEAN) - WorkManager için
--   - updated_at (TIMESTAMPTZ)
-- 
-- attendance_requests:
--   - notification_sent (BOOLEAN)
-- 
-- notification_settings:
--   - attendance_requests_enabled (BOOLEAN)
-- 
-- notifications:
--   - scheduled_time (TIMESTAMPTZ) - Zamanlanmış bildirimler için
-- 
-- payments:
--   - updated_at (TIMESTAMPTZ)
-- 
-- ============================================
-- FONKSİYONLAR (15 ADET):
-- ============================================
-- 
-- FCM & Bildirimler:
--   1. notify_via_fcm() - FCM push notification gönderir
--   2. cleanup_inactive_fcm_tokens() - Eski token'ları temizler
--   3. cleanup_old_read_notifications() - Eski bildirimleri siler
-- 
-- Yevmiye İşlemleri:
--   4. auto_approve_if_trusted() - Otomatik onay (Türkiye saati + Türkçe)
--   5. approve_attendance_request() - Manuel onay (bildirim güncelleme)
--   6. reject_attendance_request() - Red (bildirim güncelleme)
-- 
-- Ödeme İşlemleri:
--   7. update_payment() - Ödeme güncelleme + bildirim
--   8. delete_payment() - Ödeme silme + bildirim
-- 
-- Şifre Sıfırlama:
--   9. create_password_reset_token() - Token oluştur
--   10. verify_reset_token() - Token doğrula
--   11. reset_password_with_token() - Şifre sıfırla
--   12. cleanup_expired_reset_tokens() - Eski token'ları temizle
-- 
-- Email & Diğer:
--   13. check_email_unique() - Email benzersizlik kontrolü
--   14. get_manager_info_for_notification() - Manager bilgisi
--   15. update_updated_at_column() - updated_at güncelleme
-- 
-- ============================================
-- INDEXLER (25+ ADET):
-- ============================================
-- 
-- Performance için optimize edilmiş indexler:
--   - fcm_tokens: user_id, worker_id, token, is_active
--   - activity_logs: admin_id, action_type, target_user_id, created_at
--   - password_reset_tokens: token, email, expires_at
--   - users & workers: email
--   - attendance: notification_sent, created_by, notification_lookup
--   - attendance_requests: notification_sent, status_notification
--   - notifications: recipient_id, created_at, scheduled_time, recipient_scheduled
-- 
-- ============================================
-- TRIGGER'LAR (6 ADET):
-- ============================================
-- 
-- 1. trigger_update_fcm_tokens_updated_at - FCM token güncelleme
-- 2. check_email_unique_users - User email kontrolü
-- 3. check_email_unique_workers - Worker email kontrolü
-- 4. update_attendance_updated_at - Attendance güncelleme
-- 5. update_payments_updated_at - Payment güncelleme
-- 6. trigger_auto_approve_attendance - Otomatik onay
-- 7. on_notification_insert_fcm_trigger - FCM bildirim gönderme
-- 
-- ============================================
-- ÖNEMLİ ÖZELLİKLER:
-- ============================================
-- 
-- ✅ FCM Push Notifications
--    - Firebase Cloud Messaging entegrasyonu
--    - Otomatik bildirim gönderimi
--    - Token yönetimi ve temizleme
-- 
-- ✅ Türkiye Saati (UTC+3)
--    - Attendance kayıtları Türkiye saati ile
--    - created_at ve updated_at otomatik dönüşüm
-- 
-- ✅ Türkçe Mesajlar
--    - "Tam Gün", "Yarım Gün", "Gelmedi"
--    - Tüm bildirimler Türkçe
-- 
-- ✅ Zamanlanmış Bildirimler
--    - scheduled_time kolonu
--    - Otomatik onay: NULL (anında)
--    - Manuel onay: UTC + 1 minute
-- 
-- ✅ Realtime
--    - Supabase Realtime entegrasyonu
--    - notifications tablosu için REPLICA IDENTITY FULL
-- 
-- ✅ Email Sistemi
--    - Şifre sıfırlama
--    - Email benzersizlik kontrolü (users + workers arası)
--    - Email doğrulama desteği
-- 
-- ✅ Activity Logs
--    - Admin işlem takibi
--    - RLS ile güvenli erişim
--    - JSON detaylar
-- 
-- ✅ Ödeme Sistemi
--    - Ödeme güncelleme/silme bildirimleri
--    - paid_days otomatik yönetimi
--    - Türkçe formatlanmış mesajlar
-- 
-- ✅ Performance
--    - Optimize edilmiş indexler
--    - Partial indexler (WHERE clause)
--    - ANALYZE komutları
-- 
-- ============================================
-- KULLANIM:
-- ============================================
-- 
-- Bu dosyayı Supabase SQL Editor'de çalıştırarak
-- tüm migration'ları tek seferde uygulayabilirsiniz.
-- 
-- Önceki 26 migration dosyası silinmemiştir,
-- inceleme ve referans için korunmuştur.
-- 
-- ============================================
-- SON GÜNCELLEME: 2026-02-25
-- ============================================
