-- ============================================
-- Migration 010: Add Payment Notification Types to Constraint
-- Date: 2026-02-22
-- Purpose: notifications tablosundaki CHECK constraint'e yeni ödeme bildirim tiplerini ekle
-- ============================================

-- Önce mevcut constraint'i kaldır
ALTER TABLE notifications 
DROP CONSTRAINT IF EXISTS notifications_notification_type_check;

-- Yeni constraint'i tüm bildirim tipleriyle birlikte ekle
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
  'general'
));

-- ============================================
-- NOTLAR
-- ============================================
--
-- Bu migration:
-- 1. Mevcut notification_type CHECK constraint'ini kaldırır
-- 2. Yeni ödeme bildirim tiplerini (payment_updated, payment_deleted) içeren
--    güncellenmiş constraint'i ekler
--
-- ============================================
