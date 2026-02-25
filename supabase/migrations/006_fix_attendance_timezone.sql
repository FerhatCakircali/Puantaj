-- ============================================
-- Migration 006: Fix Attendance Timezone (Turkey Time - UTC+3)
-- Date: 2026-02-22
-- Purpose: Yevmiye kayıtlarının created_at ve updated_at alanlarını Türkiye saati ile kaydetmek
-- ============================================

-- ============================================
-- SORUN:
-- Yevmiye kayıtları UTC saati ile kaydediliyor, bu yüzden ekranda 3 saat geriden görünüyor.
-- Örnek: Gerçek saat 16:00 ama ekranda 13:00 görünüyor.
--
-- ÇÖZÜM:
-- approve_attendance_request ve auto_approve_if_trusted fonksiyonlarını güncelle.
-- created_at ve updated_at alanlarını Türkiye saati (UTC+3) ile kaydet.
-- ============================================

-- ============================================
-- 1. TRİGGER'I SİL (Fonksiyonu silmeden önce)
-- ============================================

DROP TRIGGER IF EXISTS trigger_auto_approve_attendance ON attendance_requests;

-- ============================================
-- 2. approve_attendance_request FONKSİYONUNU GÜNCELLE
-- ============================================

DROP FUNCTION IF EXISTS approve_attendance_request(BIGINT, BIGINT);

CREATE OR REPLACE FUNCTION approve_attendance_request(request_id_param BIGINT, reviewed_by_param BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
  request_record RECORD;
BEGIN
  -- Talebi al
  SELECT * INTO request_record
  FROM attendance_requests
  WHERE id = request_id_param AND request_status = 'pending';
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- ⚡ FIX: Türkiye saati (UTC+3) ile kaydet
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
  
  -- Request'i onayla
  UPDATE attendance_requests
  SET request_status = 'approved',
      reviewed_at = CURRENT_TIMESTAMP,
      reviewed_by = reviewed_by_param
  WHERE id = request_id_param;
  
  -- Bildirim oluştur
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
$$ LANGUAGE plpgsql;

-- ============================================
-- 3. auto_approve_if_trusted FONKSİYONUNU GÜNCELLE
-- ============================================

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
    -- ⚡ FIX: Türkiye saati (UTC+3) ile kaydet
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

-- ============================================
-- 4. TRİGGER'I YENİDEN OLUŞTUR
-- ============================================

DROP TRIGGER IF EXISTS trigger_auto_approve_attendance ON attendance_requests;

CREATE TRIGGER trigger_auto_approve_attendance
  BEFORE INSERT ON attendance_requests
  FOR EACH ROW
  EXECUTE FUNCTION auto_approve_if_trusted();

-- ============================================
-- NOTLAR
-- ============================================
--
-- Bu migration şunları yapar:
-- 1. approve_attendance_request fonksiyonunu günceller
-- 2. auto_approve_if_trusted fonksiyonunu günceller
-- 3. Trigger'ı yeniden oluşturur
--
-- SONUÇ:
-- - Yevmiye onaylandığında: Türkiye saati ile kaydedilir
-- - Otomatik onaylandığında: Türkiye saati ile kaydedilir
-- - Ekranda doğru saat görünür (16:00, 13:00 değil)
--
-- DART TARAFINDA:
-- - AttendanceService.markAttendance metodu da güncellendi
-- - Yönetici manuel yevmiye girişi de Türkiye saati kullanıyor
--
-- KULLANIM:
-- Supabase SQL Editor'de bu dosyayı çalıştır.
--
-- ============================================
