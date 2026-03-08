-- ============================================
-- ADD ADVANCE NOTIFICATION TYPES
-- ============================================
-- Bu migration avans bildirim tiplerini ekler:
-- - advance_created: Yeni avans ödemesi
-- - advance_updated: Avans güncellendi
-- - advance_deleted: Avans silindi

-- Mevcut constraint'i kaldır
ALTER TABLE notifications 
DROP CONSTRAINT IF EXISTS notifications_notification_type_check;

-- Yeni constraint ekle (avans tipleri dahil)
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
  'advance_created',
  'advance_updated',
  'advance_deleted',
  'general'
));

COMMENT ON CONSTRAINT notifications_notification_type_check ON notifications IS 
'Bildirim tipleri: attendance (devam), payment (ödeme), advance (avans), general (genel)';
