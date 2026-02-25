-- ============================================
-- Migration 004: Update Notification Message on Approval/Rejection
-- Date: 2026-02-22
-- Purpose: Yevmiye talebi onaylandığında/reddedildiğinde bildirim mesajını güncelle
-- ============================================

-- Drop existing functions
DROP FUNCTION IF EXISTS approve_attendance_request(BIGINT, BIGINT);
DROP FUNCTION IF EXISTS reject_attendance_request(BIGINT, BIGINT, TEXT);

-- Recreate approve function WITH notification message update
CREATE OR REPLACE FUNCTION approve_attendance_request(request_id_param BIGINT, reviewed_by_param BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
  request_record RECORD;
  status_text TEXT;
BEGIN
  -- Talebi al
  SELECT * INTO request_record
  FROM attendance_requests
  WHERE id = request_id_param AND request_status = 'pending';
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Attendance tablosuna ekle
  INSERT INTO attendance (user_id, worker_id, date, status, created_by)
  VALUES (
    request_record.user_id,
    request_record.worker_id,
    request_record.date,
    request_record.status,
    'worker'
  )
  ON CONFLICT (worker_id, date) DO NOTHING;
  
  -- Request'i onayla
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
  
  -- ⚡ YENİ: Orijinal bildirim mesajını güncelle
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
$$ LANGUAGE plpgsql;

-- Recreate reject function WITH notification message update
CREATE OR REPLACE FUNCTION reject_attendance_request(request_id_param BIGINT, reviewed_by_param BIGINT, reason TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  request_record RECORD;
  status_text TEXT;
BEGIN
  -- Talebi al
  SELECT * INTO request_record
  FROM attendance_requests
  WHERE id = request_id_param AND request_status = 'pending';
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Request'i reddet
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
  
  -- ⚡ YENİ: Orijinal bildirim mesajını güncelle
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
$$ LANGUAGE plpgsql;

-- ============================================
-- NOTLAR
-- ============================================
-- 
-- DEĞİŞİKLİKLER:
-- 1. Onay/red yapıldığında orijinal bildirim mesajı güncelleniyor
-- 2. Bildirim otomatik okundu işaretleniyor (is_read = TRUE)
-- 
-- ÖNCE:
-- Mesaj: "test2 (Tam Gün) - Onay bekliyor"
-- 
-- ONAYLANINCA:
-- Mesaj: "test2 (Tam Gün) - ✅ Onaylandı"
-- 
-- REDDEDİLİNCE:
-- Mesaj: "test2 (Tam Gün) - ❌ Reddedildi"
-- 
-- AVANTAJLAR:
-- - Kullanıcı bildirimler sayfasında güncel durumu görür
-- - Onay/red butonları kaybolur (is_read = TRUE)
-- - Durum badge'i gösterilir
--
