-- ============================================
-- Migration 008: Payment Update/Delete with Notifications
-- Date: 2026-02-22
-- Purpose: Ödeme güncelleme ve silme işlemleri için fonksiyonlar ve bildirim tipleri
-- ============================================

-- ============================================
-- 1. YENİ BİLDİRİM TİPLERİNİ EKLE
-- ============================================
-- payment_updated: Ödeme güncellendiğinde
-- payment_deleted: Ödeme silindiğinde

-- Not: notification_type kolonu zaten string olduğu için yeni tipler eklenebilir

-- ============================================
-- 2. ÖDEME GÜNCELLEME FONKSİYONU
-- ============================================

CREATE OR REPLACE FUNCTION update_payment(
  payment_id_param BIGINT,
  full_days_param INTEGER,
  half_days_param INTEGER,
  amount_param NUMERIC
)
RETURNS BOOLEAN AS $$
DECLARE
  payment_record RECORD;
  old_full_days INTEGER;
  old_half_days INTEGER;
  old_amount NUMERIC;
  notification_message TEXT;
BEGIN
  -- Ödeme kaydını al
  SELECT * INTO payment_record
  FROM payments
  WHERE id = payment_id_param;
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Eski değerleri sakla
  old_full_days := payment_record.full_days;
  old_half_days := payment_record.half_days;
  old_amount := payment_record.amount;
  
  -- ⚡ FIX: Önce bu ödemeye ait paid_days kayıtlarını sil
  DELETE FROM paid_days WHERE payment_id = payment_id_param;
  
  -- ⚡ FIX: Yeni gün sayılarına göre paid_days kayıtlarını yeniden oluştur
  -- Ödenmemiş günleri al ve yeni sayılara göre işaretle
  DECLARE
    unpaid_record RECORD;
    full_days_to_mark INTEGER := full_days_param;
    half_days_to_mark INTEGER := half_days_param;
  BEGIN
    -- Ödenmemiş günleri al (bu ödeme hariç)
    FOR unpaid_record IN (
      SELECT a.worker_id, a.date, a.status
      FROM attendance a
      WHERE a.worker_id = payment_record.worker_id
        AND a.user_id = payment_record.user_id
        AND (a.status = 'fullDay' OR a.status = 'halfDay')
        AND NOT EXISTS (
          SELECT 1 FROM paid_days pd
          WHERE pd.worker_id = a.worker_id
            AND pd.date = a.date
            AND pd.status = a.status
            AND pd.payment_id != payment_id_param
        )
      ORDER BY a.date
    ) LOOP
      -- Tam günleri işaretle
      IF unpaid_record.status = 'fullDay' AND full_days_to_mark > 0 THEN
        INSERT INTO paid_days (user_id, worker_id, date, status, payment_id)
        VALUES (payment_record.user_id, unpaid_record.worker_id, unpaid_record.date, unpaid_record.status, payment_id_param);
        full_days_to_mark := full_days_to_mark - 1;
      END IF;
      
      -- Yarım günleri işaretle
      IF unpaid_record.status = 'halfDay' AND half_days_to_mark > 0 THEN
        INSERT INTO paid_days (user_id, worker_id, date, status, payment_id)
        VALUES (payment_record.user_id, unpaid_record.worker_id, unpaid_record.date, unpaid_record.status, payment_id_param);
        half_days_to_mark := half_days_to_mark - 1;
      END IF;
      
      -- Tüm günler işaretlendiyse döngüden çık
      EXIT WHEN full_days_to_mark <= 0 AND half_days_to_mark <= 0;
    END LOOP;
  END;
  
  -- Ödemeyi güncelle
  UPDATE payments
  SET 
    full_days = full_days_param,
    half_days = half_days_param,
    amount = amount_param,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = payment_id_param;
  
  -- Bildirim mesajını oluştur
  notification_message := '';
  
  -- Tam gün değişikliği
  IF old_full_days != full_days_param THEN
    notification_message := notification_message || old_full_days || ' Tam Gün - ' || full_days_param || ' Tam Gün' || E'\n';
  ELSE
    notification_message := notification_message || old_full_days || ' Tam Gün - Değişiklik yok' || E'\n';
  END IF;
  
  -- Yarım gün değişikliği
  IF old_half_days != half_days_param THEN
    notification_message := notification_message || old_half_days || ' Yarım Gün - ' || half_days_param || ' Yarım Gün' || E'\n';
  ELSE
    notification_message := notification_message || old_half_days || ' Yarım Gün - Değişiklik yok' || E'\n';
  END IF;
  
  -- Tutar değişikliği (binlik ayırıcı ile)
  IF old_amount != amount_param THEN
    notification_message := notification_message || '₺' || REPLACE(TO_CHAR(old_amount, 'FM999G999G999G999'), ',', '.') || ' - ₺' || REPLACE(TO_CHAR(amount_param, 'FM999G999G999G999'), ',', '.') || E'\n';
  ELSE
    notification_message := notification_message || '₺' || REPLACE(TO_CHAR(old_amount, 'FM999G999G999G999'), ',', '.') || ' - Değişiklik yok' || E'\n';
  END IF;
  
  -- Tarih bilgisi ekle (Türkiye saati - UTC+3)
  notification_message := notification_message || E'\n' || 'Güncelleme Tarihi: ' || TO_CHAR(CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul', 'DD.MM.YYYY HH24:MI');
  
  -- Çalışana bildirim gönder
  INSERT INTO notifications (
    sender_id, sender_type, recipient_id, recipient_type,
    notification_type, title, message, related_id
  ) VALUES (
    payment_record.user_id, 'user', payment_record.worker_id, 'worker',
    'payment_updated', 'Ödemelerde güncelleme yapıldı!',
    notification_message,
    payment_id_param
  );
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 3. ÖDEME SİLME FONKSİYONU
-- ============================================

CREATE OR REPLACE FUNCTION delete_payment(payment_id_param BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
  payment_record RECORD;
  notification_message TEXT;
BEGIN
  -- Ödeme kaydını al
  SELECT * INTO payment_record
  FROM payments
  WHERE id = payment_id_param;
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Bildirim mesajını oluştur (Türkiye saati - UTC+3, binlik ayırıcı ile)
  notification_message := 
    payment_record.full_days || ' Tam Gün' || E'\n' ||
    payment_record.half_days || ' Yarım Gün' || E'\n' ||
    '₺' || REPLACE(TO_CHAR(payment_record.amount, 'FM999G999G999G999'), ',', '.') || E'\n\n' ||
    'Ödeme Tarihi: ' || TO_CHAR(payment_record.payment_date, 'DD.MM.YYYY') || E'\n' ||
    'Silme Tarihi: ' || TO_CHAR(CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul', 'DD.MM.YYYY HH24:MI');
  
  -- Çalışana bildirim gönder
  INSERT INTO notifications (
    sender_id, sender_type, recipient_id, recipient_type,
    notification_type, title, message, related_id
  ) VALUES (
    payment_record.user_id, 'user', payment_record.worker_id, 'worker',
    'payment_deleted', 'Yapılan ödeme silindi!',
    notification_message,
    payment_id_param
  );
  
  -- ⚡ FIX: Önce bu ödemeye ait paid_days kayıtlarını sil
  DELETE FROM paid_days WHERE payment_id = payment_id_param;
  
  -- Ödemeyi sil
  DELETE FROM payments WHERE id = payment_id_param;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- NOTLAR
-- ============================================
--
-- Bu migration şunları yapar:
-- 1. update_payment fonksiyonu: Ödeme günceller ve bildirim gönderir
-- 2. delete_payment fonksiyonu: Ödeme siler ve bildirim gönderir
--
-- KULLANIM:
-- Supabase SQL Editor'de bu dosyayı çalıştır.
--
-- ============================================
