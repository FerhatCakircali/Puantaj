-- ============================================
-- DATABASE MIGRATIONS - CONSOLIDATED
-- ============================================
-- Bu dosya tüm migration dosyalarını birleştirir
-- En güncel versiyonlar kullanılmıştır
-- Tarih: 2026-02-25
-- ============================================

-- ============================================
-- 1. ACTIVITY LOGS TABLE (004)
-- ============================================

CREATE TABLE IF NOT EXISTS activity_logs (
    id BIGSERIAL PRIMARY KEY,
    admin_id INTEGER NOT NULL,
    admin_username TEXT NOT NULL,
    action_type TEXT NOT NULL,
    target_user_id INTEGER,
    target_username TEXT,
    details JSONB,
    ip_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activity_logs_admin_id ON activity_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_action_type ON activity_logs(action_type);
CREATE INDEX IF NOT EXISTS idx_activity_logs_target_user_id ON activity_logs(target_user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at DESC);

ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view all activity logs"
    ON activity_logs FOR SELECT
    USING (true);

CREATE POLICY "System can insert activity logs"
    ON activity_logs FOR INSERT
    WITH CHECK (true);

CREATE POLICY "No one can update activity logs"
    ON activity_logs FOR UPDATE
    USING (false);

CREATE POLICY "No one can delete activity logs"
    ON activity_logs FOR DELETE
    USING (false);

COMMENT ON TABLE activity_logs IS 'Admin aktivite logları - kim, ne zaman, ne yaptı';
COMMENT ON COLUMN activity_logs.admin_id IS 'İşlemi yapan admin kullanıcı ID';
COMMENT ON COLUMN activity_logs.admin_username IS 'İşlemi yapan admin kullanıcı adı';
COMMENT ON COLUMN activity_logs.action_type IS 'İşlem tipi (user_created, user_updated, vb.)';
COMMENT ON COLUMN activity_logs.target_user_id IS 'İşlem yapılan kullanıcı ID (varsa)';
COMMENT ON COLUMN activity_logs.target_username IS 'İşlem yapılan kullanıcı adı (varsa)';
COMMENT ON COLUMN activity_logs.details IS 'İşlem detayları (JSON)';
COMMENT ON COLUMN activity_logs.ip_address IS 'İşlemi yapan kullanıcının IP adresi';
COMMENT ON COLUMN activity_logs.created_at IS 'İşlem zamanı';

-- ============================================
-- 2. EMAIL FIELDS (005)
-- ============================================

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS email TEXT,
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;

ALTER TABLE workers 
ADD COLUMN IF NOT EXISTS email TEXT,
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_type TEXT NOT NULL CHECK (user_type IN ('user', 'worker')),
  user_id BIGINT NOT NULL,
  email TEXT NOT NULL,
  token TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_workers_email ON workers(email);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_token ON password_reset_tokens(token);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_email ON password_reset_tokens(email);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_expires ON password_reset_tokens(expires_at);

ALTER TABLE password_reset_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "allow_all_password_reset_tokens" ON password_reset_tokens;
CREATE POLICY "allow_all_password_reset_tokens" ON password_reset_tokens FOR ALL USING (true);

CREATE OR REPLACE FUNCTION cleanup_expired_reset_tokens()
RETURNS INTEGER AS $
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM password_reset_tokens
  WHERE expires_at < CURRENT_TIMESTAMP OR used = TRUE;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_password_reset_token(
  p_user_type TEXT,
  p_user_id BIGINT,
  p_email TEXT,
  p_token TEXT
)
RETURNS BIGINT AS $
DECLARE
  token_id BIGINT;
BEGIN
  DELETE FROM password_reset_tokens
  WHERE user_type = p_user_type 
    AND user_id = p_user_id 
    AND used = FALSE;
  
  INSERT INTO password_reset_tokens (user_type, user_id, email, token, expires_at)
  VALUES (p_user_type, p_user_id, p_email, p_token, CURRENT_TIMESTAMP + INTERVAL '24 hours')
  RETURNING id INTO token_id;
  
  RETURN token_id;
END;
$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION verify_reset_token(p_token TEXT)
RETURNS TABLE (
  is_valid BOOLEAN,
  user_type TEXT,
  user_id BIGINT,
  email TEXT
) AS $
BEGIN
  RETURN QUERY
  SELECT 
    (prt.expires_at > CURRENT_TIMESTAMP AND prt.used = FALSE) as is_valid,
    prt.user_type,
    prt.user_id,
    prt.email
  FROM password_reset_tokens prt
  WHERE prt.token = p_token;
END;
$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION reset_password_with_token(
  p_token TEXT,
  p_new_password_hash TEXT
)
RETURNS BOOLEAN AS $
DECLARE
  v_user_type TEXT;
  v_user_id BIGINT;
  v_is_valid BOOLEAN;
BEGIN
  SELECT is_valid, user_type, user_id 
  INTO v_is_valid, v_user_type, v_user_id
  FROM verify_reset_token(p_token);
  
  IF NOT v_is_valid THEN
    RETURN FALSE;
  END IF;
  
  IF v_user_type = 'user' THEN
    UPDATE users
    SET password_hash = p_new_password_hash,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_user_id;
  ELSIF v_user_type = 'worker' THEN
    UPDATE workers
    SET password_hash = p_new_password_hash,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_user_id;
  ELSE
    RETURN FALSE;
  END IF;
  
  UPDATE password_reset_tokens
  SET used = TRUE
  WHERE token = p_token;
  
  RETURN TRUE;
END;
$ LANGUAGE plpgsql;

-- ============================================
-- 3. EMAIL UNIQUE CONSTRAINT (006 - EN GÜNCEL)
-- ============================================
-- 005'te eklenen UNIQUE constraint'leri kaldırıp
-- Tablolar arası email kontrolü için trigger ekliyor

ALTER TABLE users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE workers DROP CONSTRAINT IF EXISTS workers_email_key;

CREATE OR REPLACE FUNCTION check_email_unique()
RETURNS TRIGGER AS $
BEGIN
  IF NEW.email IS NULL OR NEW.email = '' THEN
    RETURN NEW;
  END IF;

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
$ LANGUAGE plpgsql;

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

-- ============================================
-- NOTLAR
-- ============================================
-- 
-- Bu dosya tüm migration dosyalarını birleştirir.
-- 
-- - activity_logs: 004 (Admin aktivite logları)
-- - email fields: 005 (Email alanları ve şifre sıfırlama)
-- - email unique: 006 (Tablolar arası email kontrolü)
-- 
-- ÖZELLIKLER:
-- ✅ Activity logs: Admin işlemlerini takip eder
-- ✅ Email fields: Şifre sıfırlama için email desteği
-- ✅ Password reset: Token bazlı şifre sıfırlama
-- ✅ Email unique: Users ve workers arası email kontrolü
-- ✅ RLS: Row Level Security politikaları
-- 
-- Önceki migration dosyaları silinmemiştir, inceleme için korunmuştur.
-- 
-- ============================================
