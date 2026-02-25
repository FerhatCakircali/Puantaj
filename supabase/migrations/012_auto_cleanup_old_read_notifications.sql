-- ============================================
-- Migration 012: Auto Cleanup Old Read Notifications
-- ============================================
-- Date: 2026-02-25
-- Purpose: Okunmuş bildirimleri otomatik olarak temizle (1 günden eski)
--          Türkiye saati (UTC+3) dikkate alınarak
-- ============================================

-- Fonksiyon: Eski okunmuş bildirimleri sil
CREATE OR REPLACE FUNCTION cleanup_old_read_notifications()
RETURNS void AS $$
DECLARE
  deleted_count INTEGER;
  today_start_utc TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Bugünün başlangıcını UTC'de hesapla
  today_start_utc := date_trunc('day', NOW() AT TIME ZONE 'UTC');
  
  -- Debug log
  RAISE NOTICE 'Bildirim temizleme başlatıldı';
  RAISE NOTICE 'Şu an (UTC): %', NOW() AT TIME ZONE 'UTC';
  RAISE NOTICE 'Bugün başlangıç (UTC): %', today_start_utc;
  
  -- Bugünden önceki okunmuş bildirimleri sil
  DELETE FROM notifications
  WHERE is_read = TRUE
    AND created_at < today_start_utc;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RAISE NOTICE '% adet eski okunmuş bildirim silindi', deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- KULLANIM
-- ============================================
-- Manuel çalıştırma:
-- SELECT cleanup_old_read_notifications();
--
-- Otomatik çalıştırma için pg_cron extension gerekli:
-- 1. Supabase Dashboard → Database → Extensions → pg_cron'u aktifleştir
-- 2. Aşağıdaki komutu çalıştır:
--
-- SELECT cron.schedule(
--   'cleanup-old-notifications',
--   '0 1 * * *',  -- Her gün saat 01:00'da (UTC)
--   'SELECT cleanup_old_read_notifications();'
-- );
--
-- NOT: Supabase'de pg_cron varsayılan olarak kapalıdır.
-- Eğer extension yoksa, uygulama açıldığında Dart kodu ile temizleme yapılır.

-- ============================================
-- AÇIKLAMA
-- ============================================
-- 
-- SORUN:
-- - Okunmuş bildirimler veritabanında birikmekte
-- - Kullanıcı deneyimini olumsuz etkiliyor
-- 
-- ÇÖZÜM:
-- - Her gün saat 01:00'da (UTC) otomatik temizleme
-- - Sadece is_read = TRUE olan bildirimler silinir
-- - Bugünden önceki bildirimler silinir (bugünkiler kalır)
-- 
-- ÖRNEK:
-- - Bugün: 25 Şubat 2026 (UTC 00:00)
-- - Silinecek: 24 Şubat ve öncesi (is_read = TRUE)
-- - Kalacak: 25 Şubat (bugün)
-- 
-- TÜRKİYE SAATİ:
-- - UTC 01:00 = Türkiye 04:00
-- - Yani her gün sabah 04:00'te temizleme yapılır
-- 
-- ============================================
