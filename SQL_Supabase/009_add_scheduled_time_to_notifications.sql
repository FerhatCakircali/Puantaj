-- ============================================
-- Migration 009: Add scheduled_time to notifications
-- Date: 2026-02-21
-- Purpose: Zamanlanmış bildirimler için scheduled_time kolonu ekle
--          Yevmiye hatırlatıcısı gibi çalışacak
-- ============================================

-- scheduled_time kolonu ekle
ALTER TABLE notifications 
ADD COLUMN scheduled_time TIMESTAMP WITH TIME ZONE;

-- Index ekle (performans için)
CREATE INDEX idx_notifications_scheduled_time 
ON notifications(scheduled_time) 
WHERE scheduled_time IS NOT NULL AND is_read = FALSE;

-- Index ekle (recipient_id + scheduled_time)
CREATE INDEX idx_notifications_recipient_scheduled 
ON notifications(recipient_id, scheduled_time) 
WHERE scheduled_time IS NOT NULL AND is_read = FALSE;

-- ============================================
-- NOTLAR
-- ============================================
-- 
-- scheduled_time:
-- - NULL ise: Anında bildirim (Realtime ile gösterilir)
-- - Değer varsa: Zamanlanmış bildirim (o zamanda gösterilir)
--
-- Kullanım:
-- - Yevmiye talebi: scheduled_time = NOW() + 1 dakika
-- - Yevmiye hatırlatıcısı: scheduled_time = bugün saat 15:41
-- - Anında bildirim: scheduled_time = NULL
--
-- Flutter tarafında:
-- - Her 10 saniyede bir kontrol et
-- - scheduled_time <= NOW() AND is_read = false olan bildirimleri getir
-- - Local notification göster
--
