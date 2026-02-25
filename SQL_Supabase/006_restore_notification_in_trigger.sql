-- ============================================
-- Migration 006: Restore Notification in auto_approve_if_trusted Trigger
-- Date: 2026-02-21
-- Purpose: Restore notification sending in trigger
--          When worker submits attendance request, manager should receive notification
-- ============================================

-- Drop existing trigger first
DROP TRIGGER IF EXISTS trigger_auto_approve_attendance ON attendance_requests;

-- Recreate function WITH notification logic
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
    
    -- Çalışana otomatik onay bildirimi gönder
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
    INSERT INTO notifications (
      sender_id, sender_type, recipient_id, recipient_type,
      notification_type, title, message, related_id
    ) VALUES (
      NEW.worker_id, 'worker', NEW.user_id, 'user',
      'attendance_request', 'Yeni Yevmiye Talebi',
      (SELECT full_name FROM workers WHERE id = NEW.worker_id) || ' ' || NEW.date || ' tarihli yevmiye girişi için onay bekliyor.',
      NEW.id
    );
  END IF;
  
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
-- 1. Otomatik onay bildirim kodu GERİ EKLENDİ (satır 40-48)
-- 2. Manuel onay bildirim kodu GERİ EKLENDİ (satır 50-60)
-- 3. Otomatik onay mantığı korundu
--
-- ETKİ:
-- - Güvenilir çalışanlar hala otomatik onaylanır VE bildirim alır
-- - Güvenilir olmayan çalışanlar talep gönderdiğinde yönetici bildirim alır
-- - Yönetici bildirim sayfasında talebi görür ve onay/red yapabilir
--
