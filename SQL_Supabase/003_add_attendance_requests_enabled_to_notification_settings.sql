-- ============================================
-- Migration: Add attendance_requests_enabled to notification_settings
-- Date: 2026-02-19
-- Purpose: Allow managers to enable/disable attendance request notifications
--          Controls WorkManager background worker scheduling
-- ============================================

-- Add attendance_requests_enabled column to notification_settings table
ALTER TABLE notification_settings 
ADD COLUMN IF NOT EXISTS attendance_requests_enabled BOOLEAN NOT NULL DEFAULT TRUE;

-- Add comment for documentation
COMMENT ON COLUMN notification_settings.attendance_requests_enabled IS 
'Controls whether the manager receives batch notifications for new attendance requests. When enabled, WorkManager sends consolidated notifications every 15 minutes.';

-- ============================================
-- NOTLAR
-- ============================================
-- 
-- VARSAYILAN DEĞER: TRUE
-- - Yeni kullanıcılar için bildirimler varsayılan olarak açık
-- - Kullanıcı isterse ayarlardan kapatabilir
--
-- KULLANIM:
-- 1. Kullanıcı bildirim ayarları ekranında toggle'ı açar/kapar
-- 2. attendance_requests_enabled güncellenir
-- 3. BackgroundService.initializeAttendanceRequestWorker() çağrılır/iptal edilir
--
-- İLİŞKİLİ TABLOLAR:
-- - notification_settings (yöneticiler için)
-- - notification_settings_workers (çalışanlar için - bu alan YOK)
--
-- GERİ ALMA:
-- ALTER TABLE notification_settings DROP COLUMN IF EXISTS attendance_requests_enabled;
--
