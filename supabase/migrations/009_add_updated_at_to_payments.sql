-- ============================================
-- Migration 009: Add updated_at to payments table
-- Date: 2026-02-22
-- Purpose: payments tablosuna updated_at kolonu ekle
-- ============================================

-- updated_at kolonunu ekle
ALTER TABLE payments 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- Mevcut kayıtlar için updated_at'i created_at ile aynı yap (eğer created_at varsa)
-- Yoksa payment_date ile aynı yap
UPDATE payments 
SET updated_at = COALESCE(created_at, payment_date)
WHERE updated_at IS NULL;

-- updated_at'i NOT NULL yap
ALTER TABLE payments 
ALTER COLUMN updated_at SET NOT NULL;

-- updated_at otomatik güncellensin
CREATE OR REPLACE FUNCTION update_payments_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger oluştur
DROP TRIGGER IF EXISTS update_payments_updated_at ON payments;

CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_payments_updated_at_column();

-- ============================================
-- NOTLAR
-- ============================================
--
-- Bu migration:
-- 1. payments tablosuna updated_at kolonu ekler
-- 2. Mevcut kayıtlar için updated_at değerini ayarlar
-- 3. Her güncelleme yapıldığında updated_at'in otomatik güncellenmesi için trigger ekler
--
-- ============================================
