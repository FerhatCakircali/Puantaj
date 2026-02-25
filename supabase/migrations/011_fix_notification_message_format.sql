-- ============================================
-- Migration 011: Fix Notification Message Format
-- Date: 2026-02-24
-- Purpose: Bildirim mesajında fullDay/halfDay yerine Türkçe göster
-- ============================================

-- Önce trigger'ı drop et
DROP TRIGGER IF EXISTS trigger_auto_approve_attendance ON attendance_requests;

-- Sonra fonksiyonu drop et
DROP FUNCTION IF EXISTS auto_approve_if_trusted();

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
    -- Attendance tablosuna ekle (Türkiye saati ile)
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
    
    -- Request'i onayla
    NEW.request_status := 'approved';
    NEW.reviewed_at := CURRENT_TIMESTAMP;
    NEW.reviewed_by := NEW.user_id;
    
    -- Bildirim oluştur
    INSERT INTO notifications (
      sender_type, recipient_id, recipient_type,
      notification_type, title, message, related_id
    ) VALUES (
      'system', NEW.worker_id, 'worker',
      'attendance_approved', 'Yevmiye Otomatik Onaylandı',
      NEW.date || ' tarihli yevmiye girişiniz otomatik olarak onaylandı.',
      NEW.id
    );
  ELSE
    -- Otomatik onay yoksa yöneticiye bildirim gönder
    -- ⚡ YENİ: Status bilgisini Türkçe olarak göster
    INSERT INTO notifications (
      sender_id, sender_type, recipient_id, recipient_type,
      notification_type, title, message, related_id
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
      NEW.id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı yeniden oluştur
CREATE TRIGGER trigger_auto_approve_attendance
  BEFORE INSERT ON attendance_requests
  FOR EACH ROW
  EXECUTE FUNCTION auto_approve_if_trusted();

-- ============================================
-- NOTLAR
-- ============================================
-- 
-- DEĞİŞİKLİK:
-- Bildirim mesajında status bilgisi artık Türkçe gösteriliyor
-- 
-- ÖNCE:
-- "test4 (fullDay) - Onay bekliyor"
-- 
-- SONRA:
-- "test4 (Tam Gün) - Onay bekliyor"
-- 
-- DESTEKLENEN DURUMLAR:
-- - fullDay → Tam Gün
-- - halfDay → Yarım Gün
-- - absent → Gelmedi
--
