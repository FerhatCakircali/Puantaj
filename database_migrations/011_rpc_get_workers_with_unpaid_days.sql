-- =====================================================
-- RPC Fonksiyonu: get_workers_with_unpaid_days
-- =====================================================
-- Amaç: N+1 query problemini çözmek için workers, attendance ve paid_days
--       tablolarını tek sorguda JOIN ederek unpaid days bilgisini döndürür
--
-- Performans İyileştirmesi: 15+ query → 1 query (%93 azalma)
--
-- Parametreler:
--   - p_user_id: UUID - Kullanıcı ID'si (filtre için)
--
-- Dönen Veri:
--   - worker_id: INTEGER
--   - full_name: TEXT
--   - title: TEXT
--   - start_date: DATE
--   - unpaid_full_days: INTEGER
--   - unpaid_half_days: INTEGER
--   - total_unpaid_days: NUMERIC (full + half*0.5)
--
-- Kullanım:
--   SELECT * FROM get_workers_with_unpaid_days('user-uuid-here');
--
-- Saat Dilimi: Europe/Istanbul (UTC+3)
-- =====================================================

CREATE OR REPLACE FUNCTION get_workers_with_unpaid_days(p_user_id UUID)
RETURNS TABLE (
  worker_id INTEGER,
  full_name TEXT,
  title TEXT,
  start_date DATE,
  unpaid_full_days INTEGER,
  unpaid_half_days INTEGER,
  total_unpaid_days NUMERIC
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    w.id AS worker_id,
    w.full_name,
    w.title,
    w.start_date,
    -- Unpaid full days: attendance'da var ama paid_days'de yok
    COALESCE(
      (SELECT COUNT(*)::INTEGER
       FROM attendance a
       WHERE a.worker_id = w.id
         AND a.status = 'full_day'
         AND NOT EXISTS (
           SELECT 1 
           FROM paid_days pd
           WHERE pd.worker_id = w.id
             AND pd.attendance_date = a.attendance_date
             AND pd.is_full_day = true
         )
      ), 0
    ) AS unpaid_full_days,
    -- Unpaid half days: attendance'da var ama paid_days'de yok
    COALESCE(
      (SELECT COUNT(*)::INTEGER
       FROM attendance a
       WHERE a.worker_id = w.id
         AND a.status = 'half_day'
         AND NOT EXISTS (
           SELECT 1 
           FROM paid_days pd
           WHERE pd.worker_id = w.id
             AND pd.attendance_date = a.attendance_date
             AND pd.is_full_day = false
         )
      ), 0
    ) AS unpaid_half_days,
    -- Total unpaid days (full + half*0.5)
    COALESCE(
      (SELECT COUNT(*)::INTEGER
       FROM attendance a
       WHERE a.worker_id = w.id
         AND a.status = 'full_day'
         AND NOT EXISTS (
           SELECT 1 
           FROM paid_days pd
           WHERE pd.worker_id = w.id
             AND pd.attendance_date = a.attendance_date
             AND pd.is_full_day = true
         )
      ), 0
    )::NUMERIC + 
    (COALESCE(
      (SELECT COUNT(*)::INTEGER
       FROM attendance a
       WHERE a.worker_id = w.id
         AND a.status = 'half_day'
         AND NOT EXISTS (
           SELECT 1 
           FROM paid_days pd
           WHERE pd.worker_id = w.id
             AND pd.attendance_date = a.attendance_date
             AND pd.is_full_day = false
         )
      ), 0
    )::NUMERIC * 0.5) AS total_unpaid_days
  FROM workers w
  WHERE w.user_id = p_user_id
    AND w.is_active = true
  ORDER BY w.full_name ASC;
END;
$$;

-- =====================================================
-- Yetkilendirme: Authenticated kullanıcılar çalıştırabilir
-- =====================================================
GRANT EXECUTE ON FUNCTION get_workers_with_unpaid_days(UUID) TO authenticated;

-- =====================================================
-- Test Sorgusu (Geliştirme için)
-- =====================================================
-- SELECT * FROM get_workers_with_unpaid_days('your-user-id-here');
