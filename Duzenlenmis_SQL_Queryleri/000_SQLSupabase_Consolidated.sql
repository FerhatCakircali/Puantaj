-- ============================================
-- SQL_SUPABASE MIGRATIONS - CONSOLIDATED
-- ============================================
-- Bu dosya tüm migration dosyalarını birleştirir
-- En güncel versiyonlar kullanılmıştır
-- Tarih: 2026-02-25
-- ============================================

-- ============================================
-- 1. ATTENDANCE TABLE - notification_sent COLUMN (002)
-- ============================================

ALTER TABLE attendance 
ADD COLUMN IF NOT EXISTS notification_sent BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN attendance.notification_sent IS 
'Tracks whether this attendance record has been included in a notification. Used by WorkManager to prevent duplicate notifications.';

CREATE INDEX IF NOT EXISTS idx_attendance_notification_sent 
ON attendance(notification_sent) 
WHERE notification_sent = FALSE;

CREATE INDEX IF NOT EXISTS idx_attendance_created_by_notification_sent 
ON attendance(created_by, notification_sent) 
WHERE created_by = 'worker';

-- ============================================
-- 2. NOTIFICATION_SETTINGS - attendance_requests_enabled COLUMN (003)
-- ============================================

ALTER TABLE notification_settings 
ADD COLUMN IF NOT EXISTS attendance_requests_enabled BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN notification_settings.attendance_requests_enabled IS 
'Controls whether the manager receives batch notifications for new attendance requests. When enabled, WorkManager sends consolidated notifications every 15 minutes.';

-- ============================================
-- 3. PERFORMANCE INDEXES (004)
-- ============================================

CREATE INDEX IF NOT EXISTS idx_attendance_notification_lookup 
ON attendance(created_by, notification_sent, created_at DESC)
WHERE created_by = 'worker' AND notification_sent = false;

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

ANALYZE attendance;
ANALYZE notifications;

COMMENT ON INDEX idx_attendance_notification_lookup IS 
'Yevmiye talep bildirimleri için partial index. Worker tarafından oluşturulan ve henüz bildirilmemiş talepleri hızlı sorgular.';

-- ============================================
-- 4. ATTENDANCE_REQUESTS - notification_sent COLUMN (005)
-- ============================================

ALTER TABLE attendance_requests 
ADD COLUMN IF NOT EXISTS notification_sent BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_attendance_requests_notification_sent 
ON attendance_requests(notification_sent);

CREATE INDEX IF NOT EXISTS idx_attendance_requests_status_notification 
ON attendance_requests(request_status, notification_sent) 
WHERE request_status = 'pending';

-- ============================================
-- 5. MANAGER INFO FUNCTION (007)
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
-- 6. ENABLE REALTIME FOR NOTIFICATIONS (008)
-- ============================================

ALTER TABLE notifications REPLICA IDENTITY FULL;

ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- ============================================
-- 7. NOTIFICATIONS - scheduled_time COLUMN (009)
-- ============================================

ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS scheduled_time TIMESTAMP WITH TIME ZONE;

CREATE INDEX IF NOT EXISTS idx_notifications_scheduled_time 
ON notifications(scheduled_time) 
WHERE scheduled_time IS NOT NULL AND is_read = FALSE;

CREATE INDEX IF NOT EXISTS idx_notifications_recipient_scheduled 
ON notifications(recipient_id, scheduled_time) 
WHERE scheduled_time IS NOT NULL AND is_read = FALSE;

-- ============================================
-- 8. AUTO APPROVE FUNCTION (001, 006, 010, 011 - EN GÜNCEL)
-- ============================================
-- 001: Bildirim kaldırıldı (WorkManager için)
-- 006: Bildirim geri eklendi
-- 010: scheduled_time eklendi
-- 011: Timezone düzeltmesi (UTC)

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
    -- ⚡ supabase/migrations/006: Türkiye saati ile kaydet
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
    
    -- ⚡ 006 + 010: Çalışana otomatik onay bildirimi (ANINDA - scheduled_time NULL)
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
    -- ⚡ supabase/migrations/011 + SQL_Supabase/011: Türkçe mesaj + UTC zamanlanmış bildirim
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
      (CURRENT_TIMESTAMP AT TIME ZONE 'UTC') + INTERVAL '1 minute'  -- ⚡ 011: UTC saati + 1 dakika
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
-- NOTLAR
-- ============================================
-- 
-- Bu dosya tüm migration dosyalarını birleştirir.
-- Çakışan fonksiyonlar için en güncel versiyonlar kullanılmıştır:
-- 
-- - auto_approve_if_trusted: TÜMÜ BİRLEŞTİRİLDİ
--   * supabase/migrations/006: Türkiye saati (created_at, updated_at)
--   * supabase/migrations/011: Türkçe mesaj formatı (Tam Gün, Yarım Gün)
--   * SQL_Supabase/010: scheduled_time eklendi
--   * SQL_Supabase/011: UTC + 1 minute (zamanlanmış bildirim)
-- - notification_sent: 002 + 005 (attendance ve attendance_requests)
-- - attendance_requests_enabled: 003 (notification_settings)
-- - Performance indexes: 004 (attendance ve notifications)
-- - get_manager_info_for_notification: 007 (Manager bilgisi)
-- - Realtime: 008 (notifications tablosu)
-- - scheduled_time: 009 (notifications kolonu)
-- 
-- ÖZELLIKLER:
-- ✅ Otomatik onay: Güvenilir çalışanlar için
-- ✅ Türkiye saati: Attendance kayıtları UTC+3 ile
-- ✅ Türkçe mesajlar: Bildirimler Türkçe
-- ✅ Zamanlanmış bildirimler: scheduled_time ile (1 dakika sonra)
-- ✅ Realtime: Supabase Realtime ile anında bildirim
-- ✅ Performance: Optimized indexes
-- 
-- Önceki migration dosyaları silinmemiştir, inceleme için korunmuştur.
-- 
-- ============================================
