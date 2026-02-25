-- ============================================
-- Migration: Add notification_sent column to attendance table
-- Date: 2026-02-19
-- Purpose: Track which attendance requests have been notified
--          Prevents duplicate notifications
-- ============================================

-- Add notification_sent column to attendance table
ALTER TABLE attendance 
ADD COLUMN IF NOT EXISTS notification_sent BOOLEAN NOT NULL DEFAULT FALSE;

-- Add comment for documentation
COMMENT ON COLUMN attendance.notification_sent IS 
'Tracks whether this attendance record has been included in a notification. Used by WorkManager to prevent duplicate notifications.';

-- Create index for efficient filtering
-- This index will be used by WorkManager to query unnotified requests
CREATE INDEX IF NOT EXISTS idx_attendance_notification_sent 
ON attendance(notification_sent) 
WHERE notification_sent = FALSE;

-- Create composite index for common query pattern
-- WorkManager will filter by: created_by='worker' AND notification_sent=false
CREATE INDEX IF NOT EXISTS idx_attendance_created_by_notification_sent 
ON attendance(created_by, notification_sent) 
WHERE created_by = 'worker';

-- ============================================
-- NOTLAR
-- ============================================
-- 
-- KULLANIM:
-- 1. WorkManager her 15 dakikada bir çalışır
-- 2. notification_sent=false olan kayıtları bulur
-- 3. Toplu bildirim gönderir
-- 4. Kayıtları notification_sent=true olarak işaretler
--
-- PERFORMANS:
-- - Partial index kullanıldı (WHERE notification_sent = FALSE)
-- - Sadece false olan kayıtlar indexlenir
-- - Daha az disk kullanımı, daha hızlı sorgular
--
-- GERİ ALMA:
-- ALTER TABLE attendance DROP COLUMN IF EXISTS notification_sent;
-- DROP INDEX IF EXISTS idx_attendance_notification_sent;
-- DROP INDEX IF EXISTS idx_attendance_created_by_notification_sent;
--
