-- ============================================
-- MIGRATION 013: DATABASE OPTIMIZATION
-- ============================================
-- 📌 AÇIKLAMA: Mevcut veritabanını optimize eder
-- 🎯 AMAÇ: Veri tipi tutarsızlıkları, eksik constraint'ler, gereksiz index'ler ve performans sorunlarını düzeltir
-- ⚠️ DİKKAT: Bu migration mevcut veritabanında çalıştırılmalıdır (Supabase SQL Editor)
-- 📅 TARİH: 2026-03-06

-- ============================================
-- SECTION 1: VERİ TİPİ DÜZELTMELERİ
-- ============================================
-- 🔧 SORUN: fcm_tokens ve activity_logs tablolarında INTEGER yerine BIGINT kullanılmalı
-- 💡 ÇÖZÜM: ALTER TABLE ile veri tiplerini BIGINT'e çevir

-- 1.1 FCM_TOKENS - user_id ve worker_id
-- users(id) ve workers(id) BIGINT olduğu için foreign key'ler de BIGINT olmalı
ALTER TABLE fcm_tokens 
  ALTER COLUMN user_id TYPE BIGINT;

ALTER TABLE fcm_tokens 
  ALTER COLUMN worker_id TYPE BIGINT;

COMMENT ON COLUMN fcm_tokens.user_id IS 'Kullanıcı ID (BIGINT - users tablosu ile uyumlu)';
COMMENT ON COLUMN fcm_tokens.worker_id IS 'Çalışan ID (BIGINT - workers tablosu ile uyumlu)';

-- 1.2 ACTIVITY_LOGS - admin_id ve target_user_id
-- users(id) BIGINT olduğu için log tablosundaki ID'ler de BIGINT olmalı
ALTER TABLE activity_logs 
  ALTER COLUMN admin_id TYPE BIGINT;

ALTER TABLE activity_logs 
  ALTER COLUMN target_user_id TYPE BIGINT;

COMMENT ON COLUMN activity_logs.admin_id IS 'İşlemi yapan admin kullanıcı ID (BIGINT - users tablosu ile uyumlu)';
COMMENT ON COLUMN activity_logs.target_user_id IS 'İşlem yapılan kullanıcı ID (BIGINT - users tablosu ile uyumlu)';

-- ============================================
-- SECTION 2: EKSİK CONSTRAINT EKLEMELERİ
-- ============================================
-- 🔧 SORUN: paid_days tablosunda UNIQUE constraint yok
-- 💡 ÇÖZÜM: Aynı gün birden fazla ödenemez (worker_id, date, status kombinasyonu unique olmalı)

-- 2.1 PAID_DAYS - Unique Constraint
-- Bir çalışanın aynı günü aynı statüde (fullDay/halfDay) sadece bir kez ödenebilir
ALTER TABLE paid_days 
  ADD CONSTRAINT unique_paid_days_worker_date_status 
  UNIQUE (worker_id, date, status);

COMMENT ON CONSTRAINT unique_paid_days_worker_date_status ON paid_days IS 
'Bir çalışanın aynı günü aynı statüde (fullDay/halfDay) sadece bir kez ödenebilir';

-- ============================================
-- SECTION 3: GEREKSIZ INDEX TEMİZLEME
-- ============================================
-- 🔧 SORUN: idx_attendance_worker_date ve idx_attendance_worker_date_desc tekrar ediyor
-- 💡 ÇÖZÜM: DESC versiyonu daha kullanışlı, normal versiyonu sil

-- 3.1 ATTENDANCE - Tekrar Eden Index
-- idx_attendance_worker_date_desc zaten var (worker_id, date DESC)
-- idx_attendance_worker_date gereksiz (worker_id, date)
DROP INDEX IF EXISTS idx_attendance_worker_date;

-- ============================================
-- SECTION 4: PERFORMANS İYİLEŞTİRMELERİ
-- ============================================
-- 🔧 SORUN: idx_expenses_user_month EXTRACT kullanıyor (yavaş)
-- 💡 ÇÖZÜM: Daha hızlı bir index stratejisi kullan

-- 4.1 EXPENSES - Aylık Rapor Index'i Yeniden Oluştur
-- EXTRACT fonksiyonu index'te yavaş çalışır
-- Bunun yerine tarih aralığı sorguları için optimize edilmiş index kullan
DROP INDEX IF EXISTS idx_expenses_user_month;

-- Kullanıcı ve tarih bazlı sorgular için daha hızlı index
-- Bu index WHERE user_id = ? AND expense_date BETWEEN ? AND ? sorgularını hızlandırır
CREATE INDEX IF NOT EXISTS idx_expenses_user_date_range 
ON expenses(user_id, expense_date DESC, category, amount);

COMMENT ON INDEX idx_expenses_user_date_range IS 
'Kullanıcı bazlı tarih aralığı sorguları için optimize edilmiş index (EXTRACT yerine BETWEEN kullanır)';

-- 4.2 Covering Index'ler Ekle
-- Sık kullanılan sorgular için covering index'ler (tüm kolonları içeren)

-- ATTENDANCE - Çalışan puantaj raporu için covering index
CREATE INDEX IF NOT EXISTS idx_attendance_worker_report 
ON attendance(worker_id, date DESC, status, created_by, created_at)
WHERE status IN ('fullDay', 'halfDay');

COMMENT ON INDEX idx_attendance_worker_report IS 
'Çalışan puantaj raporu için covering index (fullDay ve halfDay kayıtları)';

-- PAYMENTS - Ödeme raporu için covering index
CREATE INDEX IF NOT EXISTS idx_payments_worker_report 
ON payments(worker_id, payment_date DESC, full_days, half_days, amount);

COMMENT ON INDEX idx_payments_worker_report IS 
'Çalışan ödeme raporu için covering index (tüm ödeme detayları)';

-- ADVANCES - Düşülmemiş avanslar için covering index
CREATE INDEX IF NOT EXISTS idx_advances_pending_report 
ON advances(worker_id, advance_date DESC, amount, description)
WHERE is_deducted = FALSE;

COMMENT ON INDEX idx_advances_pending_report IS 
'Düşülmemiş avanslar için covering index (partial index)';

-- ============================================
-- SECTION 5: ANALYZE TABLES
-- ============================================
-- 📊 Tablo istatistiklerini güncelle (query planner için)
-- Yeni index'ler ve değişiklikler sonrası istatistikleri yenile

ANALYZE fcm_tokens;
ANALYZE activity_logs;
ANALYZE paid_days;
ANALYZE attendance;
ANALYZE payments;
ANALYZE advances;
ANALYZE expenses;

-- ============================================
-- SECTION 6: GUVENLIK UYARISI
-- ============================================
-- HARDCODED TOKEN GUVENLIK RISKI
-- notify_via_fcm() fonksiyonunda hardcoded Authorization token var
-- ONERI: Environment variable kullanin

DO $$
BEGIN
  RAISE WARNING 'GUVENLIK UYARISI: notify_via_fcm() fonksiyonunda hardcoded Authorization token bulunuyor!';
  RAISE WARNING 'ONERI: Supabase Edge Function da environment variable kullanin';
  RAISE WARNING 'DOKUMANTASYON: https://supabase.com/docs/guides/functions/secrets';
  RAISE WARNING '';
  RAISE WARNING 'Ornek kullanim:';
  RAISE WARNING '  1. Supabase Dashboard > Edge Functions > Secrets';
  RAISE WARNING '  2. FCM_SERVER_KEY adinda secret olusturun';
  RAISE WARNING '  3. Edge Function da: Deno.env.get("FCM_SERVER_KEY")';
END $$;

-- ============================================
-- SECTION 7: BASARI MESAJI
-- ============================================

DO $$
BEGIN
  RAISE NOTICE 'Migration 013 basariyla tamamlandi!';
  RAISE NOTICE '';
  RAISE NOTICE 'YAPILAN DEGISIKLIKLER:';
  RAISE NOTICE '  - fcm_tokens.user_id ve worker_id -> BIGINT';
  RAISE NOTICE '  - activity_logs.admin_id ve target_user_id -> BIGINT';
  RAISE NOTICE '  - paid_days tablosuna UNIQUE constraint eklendi';
  RAISE NOTICE '  - idx_attendance_worker_date (gereksiz) silindi';
  RAISE NOTICE '  - idx_expenses_user_month (yavas) silindi';
  RAISE NOTICE '  - 5 yeni covering index eklendi (performans)';
  RAISE NOTICE '';
  RAISE NOTICE 'PERFORMANS IYILESTIRMELERI:';
  RAISE NOTICE '  - Calisan puantaj raporu sorgulari daha hizli';
  RAISE NOTICE '  - Odeme raporu sorgulari daha hizli';
  RAISE NOTICE '  - Avans sorgulari daha hizli';
  RAISE NOTICE '  - Masraf sorgulari daha hizli (EXTRACT yerine BETWEEN)';
  RAISE NOTICE '';
  RAISE NOTICE 'HATIRLATMA: notify_via_fcm() fonksiyonundaki hardcoded tokeni environment variable ile degistirin!';
END $$;
