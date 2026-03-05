-- ============================================
-- MIGRATION 012: AVANS VE MASRAF YÖNETİMİ
-- ============================================
-- Tarih: 2026-03-04
-- Açıklama: Çalışanlara avans verme ve iş masraflarını takip etme özellikleri
-- ============================================

-- ============================================
-- 1. ADVANCES TABLE (Avanslar)
-- ============================================
-- 💰 Çalışanlara verilen avansları saklar
-- İlişkiler: users (N-1), workers (N-1), payments (N-1)
-- is_deducted: Avans ödemeden düşüldü mü?

CREATE TABLE IF NOT EXISTS advances (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  worker_id BIGINT NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
  advance_date DATE NOT NULL,
  description TEXT,
  is_deducted BOOLEAN NOT NULL DEFAULT FALSE,
  deducted_from_payment_id BIGINT REFERENCES payments(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul'),
  updated_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul')
);

COMMENT ON TABLE advances IS 'Çalışanlara verilen avansları saklar';
COMMENT ON COLUMN advances.user_id IS 'Avansı veren yönetici';
COMMENT ON COLUMN advances.worker_id IS 'Avansı alan çalışan';
COMMENT ON COLUMN advances.amount IS 'Avans tutarı (TL)';
COMMENT ON COLUMN advances.advance_date IS 'Avans verilme tarihi';
COMMENT ON COLUMN advances.description IS 'Avans açıklaması (opsiyonel)';
COMMENT ON COLUMN advances.is_deducted IS 'Avans ödemeden düşüldü mü?';
COMMENT ON COLUMN advances.deducted_from_payment_id IS 'Hangi ödemeden düşüldü (varsa)';

-- ============================================
-- 2. EXPENSES TABLE (Masraflar)
-- ============================================
-- 🏗️ İş masraflarını (malzeme, ulaşım vb.) saklar
-- İlişkiler: users (N-1)
-- category: malzeme, ulasim, ekipman, diger

CREATE TABLE IF NOT EXISTS expenses (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expense_type TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('malzeme', 'ulasim', 'ekipman', 'diger')),
  amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
  expense_date DATE NOT NULL,
  description TEXT,
  receipt_url TEXT,
  created_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul'),
  updated_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul')
);

COMMENT ON TABLE expenses IS 'İş masraflarını (malzeme, ulaşım vb.) saklar';
COMMENT ON COLUMN expenses.user_id IS 'Masrafı kaydeden yönetici';
COMMENT ON COLUMN expenses.expense_type IS 'Masraf türü (örn: 1 ton demir, nakliye)';
COMMENT ON COLUMN expenses.category IS 'Kategori: malzeme, ulasim, ekipman, diger';
COMMENT ON COLUMN expenses.amount IS 'Masraf tutarı (TL)';
COMMENT ON COLUMN expenses.expense_date IS 'Masraf tarihi';
COMMENT ON COLUMN expenses.description IS 'Masraf açıklaması (opsiyonel)';
COMMENT ON COLUMN expenses.receipt_url IS 'Fatura/fiş fotoğrafı URL (opsiyonel)';

-- ============================================
-- 3. INDEXES (Performans İçin)
-- ============================================

-- Advances indexes
CREATE INDEX IF NOT EXISTS idx_advances_user_id ON advances(user_id);
CREATE INDEX IF NOT EXISTS idx_advances_worker_id ON advances(worker_id);
CREATE INDEX IF NOT EXISTS idx_advances_date ON advances(advance_date);
CREATE INDEX IF NOT EXISTS idx_advances_is_deducted ON advances(is_deducted) WHERE is_deducted = FALSE;
CREATE INDEX IF NOT EXISTS idx_advances_worker_date ON advances(worker_id, advance_date);

COMMENT ON INDEX idx_advances_is_deducted IS 'Düşülmemiş avansları hızlı bulmak için partial index';

-- Expenses indexes
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON expenses(user_id, expense_date);

-- ============================================
-- 4. TRIGGERS (Otomatik Güncelleme)
-- ============================================

-- Avans updated_at trigger
DROP TRIGGER IF EXISTS update_advances_updated_at ON advances;
CREATE TRIGGER update_advances_updated_at
  BEFORE UPDATE ON advances
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Masraf updated_at trigger
DROP TRIGGER IF EXISTS update_expenses_updated_at ON expenses;
CREATE TRIGGER update_expenses_updated_at
  BEFORE UPDATE ON expenses
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 5. RLS POLICIES (Güvenlik)
-- ============================================

ALTER TABLE advances ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- Advances policies
DROP POLICY IF EXISTS "allow_all_advances" ON advances;
CREATE POLICY "allow_all_advances" ON advances FOR ALL USING (true);

-- Expenses policies
DROP POLICY IF EXISTS "allow_all_expenses" ON expenses;
CREATE POLICY "allow_all_expenses" ON expenses FOR ALL USING (true);

-- ============================================
-- 6. HELPER FUNCTIONS (Yardımcı Fonksiyonlar)
-- ============================================

-- Çalışanın toplam avansını hesaplayan fonksiyon
CREATE OR REPLACE FUNCTION get_worker_total_advances(worker_id_param BIGINT)
RETURNS DECIMAL AS $$
DECLARE
  total_advance DECIMAL;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO total_advance
  FROM advances
  WHERE worker_id = worker_id_param;
  
  RETURN total_advance;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_worker_total_advances(BIGINT) IS 'Çalışanın toplam avansını hesaplar';

-- Çalışanın düşülmemiş avansını hesaplayan fonksiyon
CREATE OR REPLACE FUNCTION get_worker_pending_advances(worker_id_param BIGINT)
RETURNS DECIMAL AS $$
DECLARE
  pending_advance DECIMAL;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO pending_advance
  FROM advances
  WHERE worker_id = worker_id_param AND is_deducted = FALSE;
  
  RETURN pending_advance;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_worker_pending_advances(BIGINT) IS 'Çalışanın henüz düşülmemiş avansını hesaplar';

-- Kategoriye göre toplam masrafı hesaplayan fonksiyon
CREATE OR REPLACE FUNCTION get_expenses_by_category(user_id_param BIGINT, category_param TEXT)
RETURNS DECIMAL AS $$
DECLARE
  total_expense DECIMAL;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO total_expense
  FROM expenses
  WHERE user_id = user_id_param AND category = category_param;
  
  RETURN total_expense;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_expenses_by_category(BIGINT, TEXT) IS 'Belirli kategorideki toplam masrafı hesaplar';

-- Yöneticinin aylık toplam masrafını hesaplayan fonksiyon
CREATE OR REPLACE FUNCTION get_monthly_expenses(user_id_param BIGINT, month_start DATE, month_end DATE)
RETURNS DECIMAL AS $$
DECLARE
  monthly_total DECIMAL;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO monthly_total
  FROM expenses
  WHERE user_id = user_id_param
    AND expense_date >= month_start
    AND expense_date <= month_end;
  
  RETURN monthly_total;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_monthly_expenses(BIGINT, DATE, DATE) IS 'Belirli ay aralığındaki toplam masrafı hesaplar';

-- Yöneticinin aylık toplam avansını hesaplayan fonksiyon
CREATE OR REPLACE FUNCTION get_monthly_advances(user_id_param BIGINT, month_start DATE, month_end DATE)
RETURNS DECIMAL AS $$
DECLARE
  monthly_total DECIMAL;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO monthly_total
  FROM advances
  WHERE user_id = user_id_param
    AND advance_date >= month_start
    AND advance_date <= month_end;
  
  RETURN monthly_total;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_monthly_advances(BIGINT, DATE, DATE) IS 'Belirli ay aralığındaki toplam avansı hesaplar';

-- En çok harcanan kategoriyi bulan fonksiyon
CREATE OR REPLACE FUNCTION get_top_expense_category(user_id_param BIGINT)
RETURNS TABLE (
  category TEXT,
  total_amount DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.category,
    SUM(e.amount) as total_amount
  FROM expenses e
  WHERE e.user_id = user_id_param
  GROUP BY e.category
  ORDER BY total_amount DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_top_expense_category(BIGINT) IS 'En çok harcanan kategoriyi ve tutarını döndürür';

-- ============================================
-- 7. ANALYZE TABLES (Performans Optimizasyonu)
-- ============================================

ANALYZE advances;
ANALYZE expenses;

-- ============================================
-- 8. KURULUM MESAJLARI
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ Avans ve Masraf tabloları oluşturuldu';
  RAISE NOTICE '✅ İndeksler eklendi';
  RAISE NOTICE '✅ Trigger''lar aktif';
  RAISE NOTICE '✅ RLS policies ayarlandı';
  RAISE NOTICE '✅ Yardımcı fonksiyonlar hazır';
  RAISE NOTICE '';
  RAISE NOTICE '📊 YENİ TABLOLAR:';
  RAISE NOTICE '  - advances: Çalışan avansları';
  RAISE NOTICE '  - expenses: İş masrafları';
  RAISE NOTICE '';
  RAISE NOTICE '🔧 YENİ FONKSİYONLAR:';
  RAISE NOTICE '  - get_worker_total_advances()';
  RAISE NOTICE '  - get_worker_pending_advances()';
  RAISE NOTICE '  - get_expenses_by_category()';
  RAISE NOTICE '  - get_monthly_expenses()';
  RAISE NOTICE '  - get_monthly_advances()';
  RAISE NOTICE '  - get_top_expense_category()';
END $$;
