-- ============================================
-- Migration 005: Add notification_sent to attendance_requests
-- ============================================
-- Yevmiye talep tablosuna bildirim gönderildi kolonu ekler
-- Bu kolon, WorkManager'ın hangi talepleri bildirdiğini takip eder

-- notification_sent kolonu ekle (IF NOT EXISTS yok, hata alırsa zaten var demektir)
ALTER TABLE attendance_requests 
ADD COLUMN IF NOT EXISTS notification_sent BOOLEAN NOT NULL DEFAULT FALSE;

-- Performans için index ekle
CREATE INDEX IF NOT EXISTS idx_attendance_requests_notification_sent 
ON attendance_requests(notification_sent);

-- Composite index: request_status + notification_sent (daha hızlı sorgular için)
CREATE INDEX IF NOT EXISTS idx_attendance_requests_status_notification 
ON attendance_requests(request_status, notification_sent) 
WHERE request_status = 'pending';
