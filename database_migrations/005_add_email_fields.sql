-- ============================================
-- EMAIL ALANLARI EKLEME MİGRASYONU
-- Şifre sıfırlama özelliği için
-- ============================================

-- Users tablosuna email alanı ekle
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS email TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;

-- Workers tablosuna email alanı ekle
ALTER TABLE workers 
ADD COLUMN IF NOT EXISTS email TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;

-- Şifre sıfırlama token tablosu oluştur
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

-- Index'ler ekle
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_workers_email ON workers(email);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_token ON password_reset_tokens(token);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_email ON password_reset_tokens(email);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_expires ON password_reset_tokens(expires_at);

-- RLS politikası ekle
ALTER TABLE password_reset_tokens ENABLE ROW LEVEL SECURITY;

-- Politika varsa önce sil, sonra oluştur
DROP POLICY IF EXISTS "allow_all_password_reset_tokens" ON password_reset_tokens;
CREATE POLICY "allow_all_password_reset_tokens" ON password_reset_tokens FOR ALL USING (true);

-- Eski token'ları temizleyen fonksiyon
CREATE OR REPLACE FUNCTION cleanup_expired_reset_tokens()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM password_reset_tokens
  WHERE expires_at < CURRENT_TIMESTAMP OR used = TRUE;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Şifre sıfırlama token'ı oluşturan fonksiyon
CREATE OR REPLACE FUNCTION create_password_reset_token(
  p_user_type TEXT,
  p_user_id BIGINT,
  p_email TEXT,
  p_token TEXT
)
RETURNS BIGINT AS $$
DECLARE
  token_id BIGINT;
BEGIN
  -- Eski token'ları sil
  DELETE FROM password_reset_tokens
  WHERE user_type = p_user_type 
    AND user_id = p_user_id 
    AND used = FALSE;
  
  -- Yeni token oluştur (24 saat geçerli)
  INSERT INTO password_reset_tokens (user_type, user_id, email, token, expires_at)
  VALUES (p_user_type, p_user_id, p_email, p_token, CURRENT_TIMESTAMP + INTERVAL '24 hours')
  RETURNING id INTO token_id;
  
  RETURN token_id;
END;
$$ LANGUAGE plpgsql;

-- Token doğrulama fonksiyonu
CREATE OR REPLACE FUNCTION verify_reset_token(p_token TEXT)
RETURNS TABLE (
  is_valid BOOLEAN,
  user_type TEXT,
  user_id BIGINT,
  email TEXT
) AS $$
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
$$ LANGUAGE plpgsql;

-- Şifre sıfırlama fonksiyonu (token ile)
CREATE OR REPLACE FUNCTION reset_password_with_token(
  p_token TEXT,
  p_new_password_hash TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_user_type TEXT;
  v_user_id BIGINT;
  v_is_valid BOOLEAN;
BEGIN
  -- Token'ı doğrula
  SELECT is_valid, user_type, user_id 
  INTO v_is_valid, v_user_type, v_user_id
  FROM verify_reset_token(p_token);
  
  IF NOT v_is_valid THEN
    RETURN FALSE;
  END IF;
  
  -- Şifreyi güncelle
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
  
  -- Token'ı kullanılmış olarak işaretle
  UPDATE password_reset_tokens
  SET used = TRUE
  WHERE token = p_token;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- NOTLAR
-- ============================================
-- 1. Email alanları opsiyonel (NULL olabilir)
-- 2. Email unique constraint var (aynı email iki kez kullanılamaz)
-- 3. Token'lar 24 saat geçerli
-- 4. Kullanılan veya süresi geçen token'lar otomatik temizlenebilir
-- 5. Email doğrulama özelliği için email_verified alanı eklendi
