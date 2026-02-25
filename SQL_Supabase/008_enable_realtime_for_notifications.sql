-- ============================================
-- Migration 008: Enable Realtime for Notifications Table
-- Date: 2026-02-21
-- Purpose: Enable Supabase Realtime for notifications table
--          This allows Flutter app to listen for new notifications in real-time
-- ============================================

-- Enable REPLICA IDENTITY for notifications table
-- This is required for Realtime to work with INSERT/UPDATE/DELETE events
ALTER TABLE notifications REPLICA IDENTITY FULL;

-- Add notifications table to supabase_realtime publication
-- This enables Realtime broadcasting for this table
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- ============================================
-- NOTLAR
-- ============================================
-- 
-- REPLICA IDENTITY FULL:
-- - Realtime için gerekli
-- - Tüm column değişikliklerini broadcast eder
-- - INSERT, UPDATE, DELETE eventlerini dinlemeye izin verir
--
-- supabase_realtime PUBLICATION:
-- - Supabase'in varsayılan Realtime publication'ı
-- - Bu publication'a eklenen tablolar Realtime ile broadcast edilir
--
-- FLUTTER TARAFINDA:
-- - UserNotificationListenerService bu broadcast'leri dinler
-- - onPostgresChanges ile INSERT eventlerini yakalar
-- - Yeni bildirim geldiğinde local notification gösterir
--
-- TEST:
-- 1. Bu SQL'i Supabase Dashboard'da çalıştır
-- 2. Flutter uygulamasında yönetici olarak giriş yap
-- 3. Başka cihazdan çalışan olarak yevmiye talebi gönder
-- 4. Yöneticinin cihazında anında bildirim görünmeli
--
