-- FCM Tokens Tablosu
-- Firebase Cloud Messaging token'larını saklar
-- Her kullanıcı/çalışan için bir veya daha fazla cihaz token'ı olabilir

CREATE TABLE IF NOT EXISTS fcm_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  worker_id INTEGER REFERENCES workers(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  device_type TEXT NOT NULL CHECK (device_type IN ('android', 'ios')),
  device_info JSONB DEFAULT '{}'::jsonb, -- Cihaz bilgileri (model, OS version, vb.)
  is_active BOOLEAN DEFAULT TRUE, -- Token aktif mi?
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ DEFAULT NOW(), -- Son kullanım zamanı
  
  -- Constraint: user_id veya worker_id'den biri olmalı (ikisi birden olamaz)
  CONSTRAINT check_user_or_worker CHECK (
    (user_id IS NOT NULL AND worker_id IS NULL) OR
    (user_id IS NULL AND worker_id IS NOT NULL)
  )
);

-- Index'ler (performans için)
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_worker_id ON fcm_tokens(worker_id) WHERE worker_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_token ON fcm_tokens(token);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_is_active ON fcm_tokens(is_active) WHERE is_active = TRUE;

-- Updated_at otomatik güncelleme trigger'ı
CREATE OR REPLACE FUNCTION update_fcm_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_fcm_tokens_updated_at
BEFORE UPDATE ON fcm_tokens
FOR EACH ROW
EXECUTE FUNCTION update_fcm_tokens_updated_at();

-- RLS (Row Level Security) Politikaları
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Service role için tam erişim (Edge Function'lar ve uygulama için)
-- NOT: Custom auth sistemi kullanıldığı için RLS'i basit tutuyoruz
CREATE POLICY "Service role has full access"
ON fcm_tokens FOR ALL
USING (true); -- Tüm işlemler için izin ver (uygulama service_role key kullanıyor)

-- Alternatif: Daha güvenli bir yaklaşım için user_id/worker_id bazlı kontrol
-- Ancak Supabase Auth kullanmadığınız için bu politikalar devre dışı
-- CREATE POLICY "Users can view own tokens"
-- ON fcm_tokens FOR SELECT
-- USING (user_id = current_setting('app.current_user_id')::INTEGER);

-- Yardımcı fonksiyon: Eski/inactive token'ları temizle
CREATE OR REPLACE FUNCTION cleanup_inactive_fcm_tokens()
RETURNS void AS $$
BEGIN
  -- 90 günden eski ve kullanılmayan token'ları sil
  DELETE FROM fcm_tokens
  WHERE is_active = FALSE
    AND updated_at < NOW() - INTERVAL '90 days';
    
  -- 180 günden uzun süredir kullanılmayan token'ları deaktif et
  UPDATE fcm_tokens
  SET is_active = FALSE
  WHERE last_used_at < NOW() - INTERVAL '180 days'
    AND is_active = TRUE;
END;
$$ LANGUAGE plpgsql;

-- Yorum ekle
COMMENT ON TABLE fcm_tokens IS 'Firebase Cloud Messaging token''larını saklar. Her kullanıcı/çalışan için birden fazla cihaz token''ı olabilir.';
COMMENT ON COLUMN fcm_tokens.token IS 'Firebase FCM token (unique)';
COMMENT ON COLUMN fcm_tokens.device_type IS 'Cihaz tipi: android veya ios';
COMMENT ON COLUMN fcm_tokens.device_info IS 'Cihaz bilgileri (model, OS version, app version, vb.)';
COMMENT ON COLUMN fcm_tokens.is_active IS 'Token aktif mi? Eski/geçersiz token''lar deaktif edilir.';
COMMENT ON COLUMN fcm_tokens.last_used_at IS 'Token''ın son kullanım zamanı (push notification gönderildiğinde güncellenir)';
