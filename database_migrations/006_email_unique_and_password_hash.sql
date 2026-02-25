-- ============================================
-- EMAIL UNIQUE CONSTRAINT VE PASSWORD HASH GÜNCELLEMESİ
-- ============================================

-- 1. Email unique constraint'i kaldır (tablolar arası kontrol için)
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE workers DROP CONSTRAINT IF EXISTS workers_email_key;

-- 2. Email unique kontrolü için fonksiyon (users + workers arası)
CREATE OR REPLACE FUNCTION check_email_unique()
RETURNS TRIGGER AS $$
BEGIN
  -- Email boşsa kontrol etme
  IF NEW.email IS NULL OR NEW.email = '' THEN
    RETURN NEW;
  END IF;

  -- Users tablosunda kontrol et (kendi ID'si hariç)
  IF TG_TABLE_NAME = 'users' THEN
    IF EXISTS (
      SELECT 1 FROM users 
      WHERE email = NEW.email 
      AND id != COALESCE(NEW.id, 0)
    ) THEN
      RAISE EXCEPTION 'Bu email adresi zaten kullanılıyor';
    END IF;
    
    IF EXISTS (
      SELECT 1 FROM workers 
      WHERE email = NEW.email
    ) THEN
      RAISE EXCEPTION 'Bu email adresi zaten kullanılıyor';
    END IF;
  END IF;

  -- Workers tablosunda kontrol et (kendi ID'si hariç)
  IF TG_TABLE_NAME = 'workers' THEN
    IF EXISTS (
      SELECT 1 FROM workers 
      WHERE email = NEW.email 
      AND id != COALESCE(NEW.id, 0)
    ) THEN
      RAISE EXCEPTION 'Bu email adresi zaten kullanılıyor';
    END IF;
    
    IF EXISTS (
      SELECT 1 FROM users 
      WHERE email = NEW.email
    ) THEN
      RAISE EXCEPTION 'Bu email adresi zaten kullanılıyor';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Trigger'ları oluştur
DROP TRIGGER IF EXISTS check_email_unique_users ON users;
CREATE TRIGGER check_email_unique_users
  BEFORE INSERT OR UPDATE OF email ON users
  FOR EACH ROW
  EXECUTE FUNCTION check_email_unique();

DROP TRIGGER IF EXISTS check_email_unique_workers ON workers;
CREATE TRIGGER check_email_unique_workers
  BEFORE INSERT OR UPDATE OF email ON workers
  FOR EACH ROW
  EXECUTE FUNCTION check_email_unique();

-- 4. Users tablosu için password_hash alanını güncelle (şu an plain text olanları hashle)
-- NOT: Bu migration çalıştırıldığında mevcut şifreler değişmeyecek
-- Yeni kayıtlar ve şifre değişiklikleri hashlenmiş olarak kaydedilecek

-- ============================================
-- NOTLAR
-- ============================================
-- 1. Email artık users ve workers tablolarında birbirini kontrol ediyor
-- 2. Aynı email her iki tabloda da kullanılamaz
-- 3. Users tablosu artık workers gibi hashlenmiş şifre kullanacak
-- 4. Mevcut kullanıcılar ilk giriş yaptıklarında şifreleri hashlenecek
