-- =====================================================
-- RPC Fonksiyonu: get_payment_summary
-- =====================================================
-- Amaç: Belirli tarih aralığındaki ödeme özetini tek sorguda döndürür
--       N+1 query problemini çözer
--
-- Performans İyileştirmesi: 10+ query → 1 query (%90 azalma)
--
-- Parametreler:
--   - p_user_id: UUID - Kullanıcı ID'si
--   - p_start_date: DATE - Başlangıç tarihi
--   - p_end_date: DATE - Bitiş tarihi
--
-- Dönen Veri:
--   - total_payments: INTEGER - Toplam ödeme sayısı
--   - total_amount: NUMERIC - Toplam ödeme tutarı
--   - total_advances: INTEGER - Toplam avans sayısı
--   - total_advance_amount: NUMERIC - Toplam avans tutarı
--   - total_salaries: INTEGER - Toplam maaş ödemesi sayısı
--   - total_salary_amount: NUMERIC - Toplam maaş tutarı
--   - unique_workers: INTEGER - Ödeme alan benzersiz çalışan sayısı
--   - avg_payment_amount: NUMERIC - Ortalama ödeme tutarı
--
-- Kullanım:
--   SELECT * FROM get_payment_summary(
--     'user-uuid-here',
--     '2024-01-01',
--     '2024-01-31'
--   );
--
-- Saat Dilimi: Europe/Istanbul (UTC+3)
-- =====================================================

CREATE OR REPLACE FUNCTION get_payment_summary(
  p_user_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  total_payments INTEGER,
  total_amount NUMERIC,
  total_advances INTEGER,
  total_advance_amount NUMERIC,
  total_salaries INTEGER,
  total_salary_amount NUMERIC,
  unique_workers INTEGER,
  avg_payment_amount NUMERIC
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    -- Toplam ödeme sayısı
    COUNT(*)::INTEGER AS total_payments,
    
    -- Toplam ödeme tutarı
    COALESCE(SUM(p.amount), 0)::NUMERIC AS total_amount,
    
    -- Toplam avans sayısı
    COUNT(*) FILTER (WHERE p.is_advance = true)::INTEGER AS total_advances,
    
    -- Toplam avans tutarı
    COALESCE(
      SUM(p.amount) FILTER (WHERE p.is_advance = true), 
      0
    )::NUMERIC AS total_advance_amount,
    
    -- Toplam maaş ödemesi sayısı
    COUNT(*) FILTER (WHERE p.is_advance = false)::INTEGER AS total_salaries,
    
    -- Toplam maaş tutarı
    COALESCE(
      SUM(p.amount) FILTER (WHERE p.is_advance = false), 
      0
    )::NUMERIC AS total_salary_amount,
    
    -- Benzersiz çalışan sayısı
    COUNT(DISTINCT p.worker_id)::INTEGER AS unique_workers,
    
    -- Ortalama ödeme tutarı
    COALESCE(AVG(p.amount), 0)::NUMERIC AS avg_payment_amount
    
  FROM payments p
  INNER JOIN workers w ON p.worker_id = w.id
  WHERE w.user_id = p_user_id
    AND p.payment_date >= p_start_date
    AND p.payment_date <= p_end_date;
END;
$$;

-- =====================================================
-- Yetkilendirme: Authenticated kullanıcılar çalıştırabilir
-- =====================================================
GRANT EXECUTE ON FUNCTION get_payment_summary(UUID, DATE, DATE) TO authenticated;

-- =====================================================
-- Test Sorgusu (Geliştirme için)
-- =====================================================
-- SELECT * FROM get_payment_summary(
--   'your-user-id-here',
--   '2024-01-01',
--   '2024-12-31'
-- );
