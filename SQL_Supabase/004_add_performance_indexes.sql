-- Migration: Performance İndexleri
-- Tarih: 2026-02-19
-- Açıklama: Yevmiye talep bildirimleri için performans indexleri

-- ============================================================================
-- 1. Attendance tablosu için composite index
-- ============================================================================
-- Bu index, bildirilmemiş worker taleplerini hızlı sorgulamak için kullanılır
-- Query: WHERE created_by='worker' AND notification_sent=false
CREATE INDEX IF NOT EXISTS idx_attendance_notification_lookup 
ON attendance(created_by, notification_sent, created_at DESC)
WHERE created_by = 'worker' AND notification_sent = false;

-- ============================================================================
-- 2. Notifications tablosu için index kontrolü
-- ============================================================================
-- Notifications tablosunda recipient_id ve created_at için index olup olmadığını kontrol et
-- Eğer yoksa oluştur
DO $$
BEGIN
    -- recipient_id için index kontrolü
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_indexes 
        WHERE tablename = 'notifications' 
        AND indexname = 'idx_notifications_recipient_id'
    ) THEN
        CREATE INDEX idx_notifications_recipient_id ON notifications(recipient_id);
        RAISE NOTICE 'idx_notifications_recipient_id oluşturuldu';
    ELSE
        RAISE NOTICE 'idx_notifications_recipient_id zaten mevcut';
    END IF;

    -- created_at için index kontrolü
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_indexes 
        WHERE tablename = 'notifications' 
        AND indexname = 'idx_notifications_created_at'
    ) THEN
        CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
        RAISE NOTICE 'idx_notifications_created_at oluşturuldu';
    ELSE
        RAISE NOTICE 'idx_notifications_created_at zaten mevcut';
    END IF;

    -- Composite index kontrolü (recipient_id + created_at)
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_indexes 
        WHERE tablename = 'notifications' 
        AND indexname = 'idx_notifications_recipient_created'
    ) THEN
        CREATE INDEX idx_notifications_recipient_created ON notifications(recipient_id, created_at DESC);
        RAISE NOTICE 'idx_notifications_recipient_created oluşturuldu';
    ELSE
        RAISE NOTICE 'idx_notifications_recipient_created zaten mevcut';
    END IF;

    -- recipient_type + recipient_id composite index (daha spesifik sorgular için)
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_indexes 
        WHERE tablename = 'notifications' 
        AND indexname = 'idx_notifications_recipient_type_id'
    ) THEN
        CREATE INDEX idx_notifications_recipient_type_id ON notifications(recipient_type, recipient_id);
        RAISE NOTICE 'idx_notifications_recipient_type_id oluşturuldu';
    ELSE
        RAISE NOTICE 'idx_notifications_recipient_type_id zaten mevcut';
    END IF;
END $$;

-- ============================================================================
-- 3. Index istatistiklerini güncelle
-- ============================================================================
-- PostgreSQL'in query planner'ının doğru kararlar alması için
ANALYZE attendance;
ANALYZE notifications;

-- ============================================================================
-- 4. Index kullanım bilgisi
-- ============================================================================
COMMENT ON INDEX idx_attendance_notification_lookup IS 
'Yevmiye talep bildirimleri için partial index. Worker tarafından oluşturulan ve henüz bildirilmemiş talepleri hızlı sorgular.';

