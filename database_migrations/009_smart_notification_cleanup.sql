-- ============================================
-- SMART NOTIFICATION CLEANUP SYSTEM
-- ============================================
-- Akıllı bildirim temizleme sistemi
-- 
-- KURALLAR:
-- 1. Okunmuş + bildirimin geldiği saatten 24 saat sonra → SİL
-- 2. Okunmamış → KALSIN (okunana kadar)
-- 3. Okundu + bildirimin geldiği saatten 24 saat geçmişse → HEMEN SİL (trigger ile)
-- 4. Okunmamış + bildirimin geldiği saatten 7 gün geçmişse → SİL

-- ============================================
-- 1. Bildirim Tiplerini Düzelt (007'den)
-- ============================================
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_notification_type_check;

ALTER TABLE notifications ADD CONSTRAINT notifications_notification_type_check 
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
-- 2. Akıllı Bildirim Temizleme Fonksiyonu
-- ============================================
CREATE OR REPLACE FUNCTION smart_cleanup_notifications()
RETURNS void AS $$
DECLARE
  deleted_read_count INTEGER;
  deleted_old_unread_count INTEGER;
  now_turkey TIMESTAMP WITH TIME ZONE;
  twentyfour_hours_ago TIMESTAMP WITH TIME ZONE;
  seven_days_ago TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Şu anki zaman (Türkiye saati)
  now_turkey := NOW() AT TIME ZONE 'Europe/Istanbul';
  
  -- 24 saat önce
  twentyfour_hours_ago := now_turkey - INTERVAL '24 hours';
  
  -- 7 gün önce
  seven_days_ago := now_turkey - INTERVAL '7 days';
  
  RAISE NOTICE '🧹 Akıllı bildirim temizleme başlatıldı';
  RAISE NOTICE '⏰ Şu an (Türkiye): %', now_turkey;
  RAISE NOTICE '📅 24 saat önce: %', twentyfour_hours_ago;
  RAISE NOTICE '📅 7 gün önce: %', seven_days_ago;
  
  -- KURAL 1: Okunmuş + bildirimin geldiği saatten 24 saat geçmiş bildirimleri sil
  DELETE FROM notifications
  WHERE is_read = TRUE
    AND created_at < twentyfour_hours_ago;
  
  GET DIAGNOSTICS deleted_read_count = ROW_COUNT;
  
  -- KURAL 4: Okunmamış + bildirimin geldiği saatten 7 gün geçmiş bildirimleri sil
  DELETE FROM notifications
  WHERE is_read = FALSE
    AND created_at < seven_days_ago;
  
  GET DIAGNOSTICS deleted_old_unread_count = ROW_COUNT;
  
  RAISE NOTICE '✅ % adet okunmuş 24 saat eski bildirim silindi', deleted_read_count;
  RAISE NOTICE '✅ % adet 7 gün eski okunmamış bildirim silindi', deleted_old_unread_count;
  RAISE NOTICE '📊 Kalan bildirim sayısı: %', (SELECT COUNT(*) FROM notifications);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION smart_cleanup_notifications() IS 
'Akıllı bildirim temizleme: Okunmuş bildirimleri 24 saat sonra, okunmamış bildirimleri 7 gün sonra siler. Bildirimin geldiği saatten itibaren hesaplanır.';

-- ============================================
-- 3. Okunduğunda Anında Temizleme Trigger'ı
-- ============================================
-- KURAL 3: Bildirim okunduğunda, bildirimin geldiği saatten 24 saat geçmişse hemen sil

CREATE OR REPLACE FUNCTION cleanup_on_notification_read()
RETURNS TRIGGER AS $$
DECLARE
  now_turkey TIMESTAMP WITH TIME ZONE;
  notification_age INTERVAL;
BEGIN
  -- Sadece is_read FALSE'dan TRUE'ya değiştiğinde çalış
  IF NEW.is_read = TRUE AND OLD.is_read = FALSE THEN
    -- Şu anki zaman (Türkiye saati)
    now_turkey := NOW() AT TIME ZONE 'Europe/Istanbul';
    
    -- Bildirimin yaşı
    notification_age := now_turkey - NEW.created_at;
    
    -- Eğer bildirim 24 saatten eski ise, hemen sil
    IF notification_age >= INTERVAL '24 hours' THEN
      RAISE LOG '🗑️ Bildirim okundu ve 24 saat geçmiş, siliniyor: ID=%, Yaş=%, Tarih=%', NEW.id, notification_age, NEW.created_at;
      
      -- Bildirimi sil
      DELETE FROM notifications WHERE id = NEW.id;
      
      -- NULL döndürerek UPDATE işlemini iptal et (zaten silindi)
      RETURN NULL;
    END IF;
  END IF;
  
  -- Normal UPDATE devam etsin
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_on_notification_read() IS 
'Bildirim okunduğunda, bildirimin geldiği saatten 24 saat geçmişse hemen siler. 24 saat geçmemişse kalır.';

-- Trigger'ı oluştur
DROP TRIGGER IF EXISTS trigger_cleanup_on_read ON notifications;
CREATE TRIGGER trigger_cleanup_on_read
  BEFORE UPDATE OF is_read ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION cleanup_on_notification_read();

COMMENT ON TRIGGER trigger_cleanup_on_read ON notifications IS 
'Bildirim okunduğunda otomatik temizleme yapar (eski ise)';

-- ============================================
-- 4. pg_cron Extension Kontrolü
-- ============================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    RAISE WARNING '⚠️ pg_cron extension yüklü değil!';
    RAISE WARNING '📦 Supabase Dashboard > Database > Extensions > pg_cron (enable)';
    RAISE WARNING '🔧 Extension aktif edilene kadar otomatik temizleme çalışmayacak.';
  ELSE
    RAISE NOTICE '✅ pg_cron extension yüklü - Otomatik temizleme aktif';
  END IF;
END $$;

-- ============================================
-- 5. Cron Job: Akıllı Bildirim Temizleme
-- ============================================
-- Her saat başı çalışır (bildirimin geldiği saatten 24 saat sonra silmek için)

-- Mevcut job'ı sil (varsa)
SELECT cron.unschedule('cleanup-old-notifications') 
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'cleanup-old-notifications'
);

-- Yeni cron job ekle - Her saat başı
SELECT cron.schedule(
  'cleanup-old-notifications',
  '0 * * * *', -- Her saat başı (00:00, 01:00, 02:00, ...)
  $$SELECT smart_cleanup_notifications()$$
);

-- ============================================
-- 6. Cron Job: FCM Token Temizleme
-- ============================================
-- Her Pazar saat 03:00 (Türkiye saati) = 00:00 UTC

SELECT cron.unschedule('cleanup-inactive-fcm-tokens') 
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'cleanup-inactive-fcm-tokens'
);

SELECT cron.schedule(
  'cleanup-inactive-fcm-tokens',
  '0 0 * * 0', -- Her Pazar 00:00 UTC (03:00 Türkiye saati)
  $$SELECT cleanup_inactive_fcm_tokens()$$
);

-- ============================================
-- 7. Cron Job: Activity Log Temizleme
-- ============================================
-- Her Pazartesi saat 02:00 (Türkiye saati) = 23:00 UTC Pazar

SELECT cron.unschedule('cleanup-old-activity-logs') 
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'cleanup-old-activity-logs'
);

SELECT cron.schedule(
  'cleanup-old-activity-logs',
  '0 23 * * 0', -- Her Pazar 23:00 UTC (Pazartesi 02:00 Türkiye saati)
  $$SELECT cleanup_old_activity_logs()$$
);

-- ============================================
-- 8. Cron Job: Şifre Sıfırlama Token Temizleme
-- ============================================
-- Her gün saat 04:00 (Türkiye saati) = 01:00 UTC

SELECT cron.unschedule('cleanup-expired-reset-tokens') 
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'cleanup-expired-reset-tokens'
);

SELECT cron.schedule(
  'cleanup-expired-reset-tokens',
  '0 1 * * *', -- Her gün 01:00 UTC (04:00 Türkiye saati)
  $$SELECT cleanup_expired_reset_tokens()$$
);

-- ============================================
-- 9. İlk Temizleme (Şimdi Çalıştır)
-- ============================================
SELECT smart_cleanup_notifications();
SELECT cleanup_expired_reset_tokens();

-- ============================================
-- 10. Kontrol Sorguları
-- ============================================
-- Cron job'ları görmek için:
-- SELECT jobname, schedule, active, command FROM cron.job ORDER BY jobname;

-- Cron job geçmişini görmek için:
-- SELECT j.jobname, d.start_time, d.end_time, d.status, d.return_message
-- FROM cron.job_run_details d
-- JOIN cron.job j ON j.jobid = d.jobid
-- ORDER BY d.start_time DESC LIMIT 20;

-- Bildirimleri kontrol et:
-- SELECT 
--   recipient_type,
--   is_read,
--   COUNT(*) as count,
--   MIN(created_at) as oldest,
--   MAX(created_at) as newest
-- FROM notifications
-- GROUP BY recipient_type, is_read
-- ORDER BY recipient_type, is_read;

-- ============================================
-- 11. Kurulum Mesajları
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Akıllı bildirim temizleme sistemi kuruldu';
  RAISE NOTICE '📋 KURALLAR:';
  RAISE NOTICE '  1. Okunmuş + bildirimin geldiği saatten 24 saat sonra → Otomatik sil (her saat başı kontrol)';
  RAISE NOTICE '  2. Okunmamış → Kalır (okunana kadar)';
  RAISE NOTICE '  3. Okundu + bildirimin geldiği saatten 24 saat geçmişse → Anında sil (trigger)';
  RAISE NOTICE '  4. Okunmamış + bildirimin geldiği saatten 7 gün geçmişse → Otomatik sil (her saat başı kontrol)';
  RAISE NOTICE '';
  RAISE NOTICE '📅 Cron Job Zamanları:';
  RAISE NOTICE '  - Bildirimler: Her saat başı (bildirimin geldiği saatten 24 saat sonra silmek için)';
  RAISE NOTICE '  - FCM Token''lar: Her Pazar 03:00 (Türkiye saati)';
  RAISE NOTICE '  - Activity Log''lar: Her Pazartesi 02:00 (Türkiye saati)';
  RAISE NOTICE '  - Reset Token''lar: Her gün 04:00 (Türkiye saati)';
END $$;
