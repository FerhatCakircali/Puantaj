-- ============================================
-- ADD ADVANCE_DEDUCTED COLUMN TO PAYMENTS
-- ============================================
-- Bu migration payments tablosuna advance_deducted kolonunu ekler
-- Bu kolon, ödemeden düşülen toplam avans tutarını saklar

ALTER TABLE payments
ADD COLUMN IF NOT EXISTS advance_deducted DECIMAL(10, 2) DEFAULT 0.0 CHECK (advance_deducted >= 0);

COMMENT ON COLUMN payments.advance_deducted IS 
'Bu ödemeden düşülen toplam avans tutarı (TL)';
