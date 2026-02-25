-- ============================================
-- SUPABASE MIGRATIONS - CONSOLIDATED
-- ============================================
-- Bu dosya tüm migration dosyalarını birleştirir
-- En güncel versiyonlar kullanılmıştır
-- Tarih: 2026-02-25
-- ============================================

-- ============================================
-- 1. FCM TOKENS TABLE (001)
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

CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_worker_id ON fcm_tokens(worker_id) WHERE worker_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_token ON fcm_tokens(token);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_is_active ON fcm_tokens(is_active) WHERE is_active = TRUE;

CREATE OR REPLACE FUNCTION update_fcm_tokens_updated_at()
RETURNS TRIGGER AS $
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_fcm_tokens_updated_at
BEFORE UPDATE ON fcm_tokens
FOR EACH ROW
EXECUTE FUNCTION update_fcm_tokens_updated_at();

ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role has full access"
ON fcm_tokens FOR ALL
USING (true);

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

COMMENT ON TABLE fcm_tokens IS 'Firebase Cloud Messaging token''larını saklar. Her kullanıcı/çalışan için birden fazla cihaz token''ı olabilir.';
COMMENT ON COLUMN fcm_tokens.token IS 'Firebase FCM token (unique)';
COMMENT ON COLUMN fcm_tokens.device_type IS 'Cihaz tipi: android veya ios';
COMMENT ON COLUMN fcm_tokens.device_info IS 'Cihaz bilgileri (model, OS version, app version, vb.)';
COMMENT ON COLUMN fcm_tokens.is_active IS 'Token aktif mi? Eski/geçersiz token''lar deaktif edilir.';
COMMENT ON COLUMN fcm_tokens.last_used_at IS 'Token''ın son kullanım zamanı (push notification gönderildiğinde güncellenir)';

-- ============================================
-- 2. FCM NOTIFICATION TRIGGER (002)
-- ============================================

CREATE OR REPLACE FUNCTION notify_via_fcm()
RETURNS TRIGGER AS $
DECLARE
  request_id bigint;
BEGIN
  BEGIN
    SELECT net.http_post(
      url := 'https://YOUR_PROJECT_ID.supabase.co/functions/v1/send-push-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY_HERE'
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

DROP TRIGGER IF EXISTS on_notification_insert_fcm_trigger ON notifications;

CREATE TRIGGER on_notification_insert_fcm_trigger
AFTER INSERT ON notifications
FOR EACH ROW
EXECUTE FUNCTION notify_via_fcm();

COMMENT ON FUNCTION notify_via_fcm() IS 'Yeni bildirim eklendiğinde FCM Edge Function''ını çağırır';
COMMENT ON TRIGGER on_notification_insert_fcm_trigger ON notifications IS 'Yeni bildirim için FCM push notification gönderir';

DO $
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') THEN
    RAISE WARNING 'pg_net extension is not installed. FCM notifications will not work.';
    RAISE WARNING 'Install it with: CREATE EXTENSION pg_net;';
  END IF;
END $;

-- ============================================
-- 3. NOTIFICATION TYPES (005, 010 - EN GÜNCEL)
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
-- 4. AUTO APPROVE FUNCTION (003, 006, 011 - EN GÜNCEL)
-- ============================================

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
    
    INSERT INTO notifications (
      sender_type, recipient_id, recipient_type,
      notification_type, title, message, related_id,
      scheduled_time
    ) VALUES (
      'system', NEW.worker_id, 'worker',
      'attendance_approved', 'Yevmiye Otomatik Onaylandı',
      NEW.date || ' tarihli yevmiye girişiniz otomatik olarak onaylandı.',
      NEW.id,
      NULL
    );
  ELSE
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
      (CURRENT_TIMESTAMP AT TIME ZONE 'UTC') + INTERVAL '1 minute'  -- ⚡ SQL_Supabase/011: Zamanlanmış bildirim
    );
  END IF;
  
  RETURN NEW;
END;
$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_approve_attendance
  BEFORE INSERT ON attendance_requests
  FOR EACH ROW
  EXECUTE FUNCTION auto_approve_if_trusted();

-- ============================================
-- 5. APPROVE ATTENDANCE REQUEST (004 + 006 - BİRLEŞTİRİLMİŞ)
-- ============================================
-- 004: Bildirim mesajı güncelleme + is_read = TRUE
-- 006: Türkiye saati (UTC+3) ile kaydetme

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
  
  -- ⚡ 006: Türkiye saati (UTC+3) ile kaydet
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
  
  -- ⚡ 004: Status text'i hazırla
  status_text := CASE 
    WHEN request_record.status = 'fullDay' THEN 'Tam Gün'
    WHEN request_record.status = 'halfDay' THEN 'Yarım Gün'
    WHEN request_record.status = 'absent' THEN 'Gelmedi'
    ELSE request_record.status
  END;
  
  -- ⚡ 004: Orijinal bildirim mesajını güncelle
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
-- 6. REJECT ATTENDANCE REQUEST (004)
-- ============================================
-- Bildirim mesajı güncelleme + is_read = TRUE

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
  
  -- ⚡ 004: Status text'i hazırla
  status_text := CASE 
    WHEN request_record.status = 'fullDay' THEN 'Tam Gün'
    WHEN request_record.status = 'halfDay' THEN 'Yarım Gün'
    WHEN request_record.status = 'absent' THEN 'Gelmedi'
    ELSE request_record.status
  END;
  
  -- ⚡ 004: Orijinal bildirim mesajını güncelle
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
-- 7. ATTENDANCE UPDATED_AT (007)
-- ============================================

ALTER TABLE attendance 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

UPDATE attendance 
SET updated_at = created_at 
WHERE updated_at IS NULL;

ALTER TABLE attendance 
ALTER COLUMN updated_at SET NOT NULL;

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_attendance_updated_at ON attendance;

CREATE TRIGGER update_attendance_updated_at
    BEFORE UPDATE ON attendance
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 8. PAYMENTS UPDATED_AT (009)
-- ============================================

ALTER TABLE payments 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

UPDATE payments 
SET updated_at = COALESCE(created_at, payment_date)
WHERE updated_at IS NULL;

ALTER TABLE payments 
ALTER COLUMN updated_at SET NOT NULL;

CREATE OR REPLACE FUNCTION update_payments_updated_at_column()
RETURNS TRIGGER AS $
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_payments_updated_at ON payments;

CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_payments_updated_at_column();

-- ============================================
-- 9. UPDATE PAYMENT FUNCTION (008)
-- ============================================

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
-- 10. DELETE PAYMENT FUNCTION (008)
-- ============================================

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
-- 11. AUTO CLEANUP OLD NOTIFICATIONS (012)
-- ============================================

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
-- NOTLAR
-- ============================================
-- 
-- Bu dosya tüm migration dosyalarını birleştirir.
-- Çakışan fonksiyonlar için en güncel versiyonlar kullanılmıştır:
-- 
-- - auto_approve_if_trusted: TÜMÜ BİRLEŞTİRİLDİ
--   * 003: Anında bildirim (scheduled_time = NULL)
--   * 006: Türkiye saati (created_at, updated_at)
--   * 011: Türkçe mesaj formatı (Tam Gün, Yarım Gün)
--   * SQL_Supabase/011: UTC + 1 minute (zamanlanmış bildirim)
-- - approve_attendance_request: 004 + 006 (Bildirim güncelleme + Türkiye saati)
-- - reject_attendance_request: 004 (Bildirim güncelleme)
-- - notification_type constraint: 010 (Tüm ödeme tipleri dahil)
-- - update_payment: 008 (Ödeme güncelleme + bildirim)
-- - delete_payment: 008 (Ödeme silme + bildirim)
-- - cleanup_old_read_notifications: 012 (Otomatik temizleme)
-- 
-- ÖZELLIKLER:
-- ✅ FCM: Firebase Cloud Messaging desteği
-- ✅ Otomatik onay: Güvenilir çalışanlar için
-- ✅ Türkiye saati: Attendance kayıtları UTC+3 ile
-- ✅ Türkçe mesajlar: Bildirimler Türkçe
-- ✅ Zamanlanmış bildirimler: scheduled_time ile (1 dakika sonra)
-- ✅ Ödeme sistemi: Bildirimli ödeme takibi
-- ✅ Otomatik temizlik: Eski bildirimleri temizler
-- 
-- Önceki migration dosyaları silinmemiştir, inceleme için korunmuştur.
-- 
-- ============================================
