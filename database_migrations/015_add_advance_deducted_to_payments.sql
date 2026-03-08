-- ============================================
-- ADD ADVANCE_DEDUCTED COLUMN TO PAYMENTS
-- ============================================
-- Bu migration payments tablosuna advance_deducted kolonunu ekler
-- Bu kolon, ödemeden düşülen toplam avans tutarını saklar

ALTER TABLE payments
ADD COLUMN IF NOT EXISTS advance_deducted DECIMAL(10, 2) DEFAULT 0.0 CHECK (advance_deducted >= 0);

COMMENT ON COLUMN payments.advance_deducted IS 
'Bu ödemeden düşülen toplam avans tutarı (TL)';

-- Mevcut ödemelerin advance_deducted değerini hesapla ve güncelle
-- (Bu ödemeden düşülen avansların orijinal tutarlarını topla)
UPDATE payments p
SET advance_deducted = COALESCE((
  SELECT SUM(
    CASE 
      WHEN a.is_deducted = true THEN a.amount
      ELSE 0
    END
  )
  FROM advances a
  WHERE a.deducted_from_payment_id = p.id
), 0)
WHERE p.advance_deducted = 0 OR p.advance_deducted IS NULL;

-- NOT: Kısmi düşülen avanslar için orijinal tutarı bilmiyoruz
-- Bu yüzden sadece tamamen düşülen avansları hesaplıyoruz
-- Yeni ödemeler için doğru tutar kaydedilecek
