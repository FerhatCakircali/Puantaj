-- ============================================
-- Migration 005: Ödeme Bildirimi Tipi Ekle
-- ============================================
-- Tarih: 2026-02-22
-- Açıklama: notifications tablosuna 'payment_received' notification type'ı eklenir
-- Sebep: Ödeme yapıldığında çalışanlara bildirim gönderilebilmesi için

-- Önce mevcut constraint'i kaldır
ALTER TABLE notifications 
DROP CONSTRAINT IF EXISTS notifications_notification_type_check;

-- Yeni constraint'i ekle (payment_received dahil)
ALTER TABLE notifications 
ADD CONSTRAINT notifications_notification_type_check 
CHECK (notification_type IN (
  'attendance_request',      -- Yevmiye talebi
  'attendance_reminder',     -- Yevmiye hatırlatıcısı
  'attendance_approved',     -- Yevmiye onaylandı
  'attendance_rejected',     -- Yevmiye reddedildi
  'payment_received',        -- Ödeme yapıldı (YENİ)
  'general'                  -- Genel bildirim
));

-- Kontrol et
SELECT 
  constraint_name, 
  check_clause 
FROM information_schema.check_constraints 
WHERE constraint_name = 'notifications_notification_type_check';

-- ============================================
-- NOTLAR
-- ============================================
-- 
-- Bu migration'dan sonra ödeme bildirimleri gönderilebilir:
-- 
-- INSERT INTO notifications (
--   sender_id, sender_type, recipient_id, recipient_type,
--   notification_type, title, message, related_id
-- ) VALUES (
--   user_id, 'user', worker_id, 'worker',
--   'payment_received', 'Ödeme Yapıldı',
--   '3 Tam Gün, 2 Yarım Gün - Toplam 5000₺ ödendi',
--   worker_id
-- );
-- 
-- ============================================
