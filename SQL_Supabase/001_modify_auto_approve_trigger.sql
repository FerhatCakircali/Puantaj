-- ============================================
-- Migration: Modify auto_approve_if_trusted Trigger
-- Date: 2026-02-19
-- Purpose: Remove notification sending from trigger
--          Keep auto-approval logic intact
--          WorkManager will handle batch notifications
-- ============================================

-- Drop existing trigger first
DROP TRIGGER IF EXISTS trigger_auto_approve_attendance ON attendance_requests;

-- Recreate function without notification logic
CREATE OR REPLACE FUNCTION auto_approve_if_trusted()
RETURNS TRIGGER AS $$
DECLARE
  is_trusted_worker BOOLEAN;
  auto_approve_enabled BOOLEAN;
BEGIN
  -- Çalışan güvenilir mi kontrol et
  SELECT w.is_trusted INTO is_trusted_worker
  FROM workers w
  WHERE w.id = NEW.worker_id;
  
  -- Yöneticinin otomatik onay ayarı açık mı kontrol et
  SELECT COALESCE(ns.auto_approve_trusted, FALSE) INTO auto_approve_enabled
  FROM notification_settings ns
  WHERE ns.user_id = NEW.user_id;
  
  -- Eğer her ikisi de true ise otomatik onayla
  IF COALESCE(is_trusted_worker, FALSE) AND auto_approve_enabled THEN
    -- Attendance tablosuna ekle
    INSERT INTO attendance (user_id, worker_id, date, status, created_by)
    VALUES (NEW.user_id, NEW.worker_id, NEW.date, NEW.status, 'worker')
    ON CONFLICT (worker_id, date) DO NOTHING;
    
    -- Request'i onayla
    NEW.request_status := 'approved';
    NEW.reviewed_at := CURRENT_TIMESTAMP;
    NEW.reviewed_by := NEW.user_id;
    
    -- NOT: Bildirim gönderme kodu KALDIRILDI
    -- WorkManager toplu bildirimleri yönetecek
  END IF;
  
  -- NOT: ELSE bloğu KALDIRILDI
  -- Otomatik onay yoksa bildirim gönderme
  -- WorkManager 15 dakikada bir toplu bildirim gönderecek
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger
CREATE TRIGGER trigger_auto_approve_attendance
  BEFORE INSERT ON attendance_requests
  FOR EACH ROW
  EXECUTE FUNCTION auto_approve_if_trusted();

-- ============================================
-- NOTLAR
-- ============================================
-- 
-- DEĞİŞİKLİKLER:
-- 1. Otomatik onay bildirim kodu kaldırıldı (satır 28-35)
-- 2. Manuel onay bildirim kodu kaldırıldı (satır 37-47)
-- 3. Otomatik onay mantığı korundu
-- 4. WorkManager artık tüm bildirimleri yönetecek
--
-- ETKİ:
-- - Güvenilir çalışanlar hala otomatik onaylanır
-- - Bildirimler artık 15 dakikada bir toplu gönderilir
-- - Spam bildirim sorunu çözülür
-- - Spec gereksinimlerine uygun hale gelir
--
