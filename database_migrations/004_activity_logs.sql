-- Aktivite logları tablosu
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

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_activity_logs_admin_id ON activity_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_action_type ON activity_logs(action_type);
CREATE INDEX IF NOT EXISTS idx_activity_logs_target_user_id ON activity_logs(target_user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at DESC);

-- RLS (Row Level Security) politikaları
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- Admin kullanıcılar tüm logları görebilir
CREATE POLICY "Admins can view all activity logs"
    ON activity_logs FOR SELECT
    USING (true);

-- Sadece sistem activity_logs tablosuna insert yapabilir
CREATE POLICY "System can insert activity logs"
    ON activity_logs FOR INSERT
    WITH CHECK (true);

-- Hiç kimse activity_logs'u silemez veya güncelleyemez
CREATE POLICY "No one can update activity logs"
    ON activity_logs FOR UPDATE
    USING (false);

CREATE POLICY "No one can delete activity logs"
    ON activity_logs FOR DELETE
    USING (false);

-- Yorum
COMMENT ON TABLE activity_logs IS 'Admin aktivite logları - kim, ne zaman, ne yaptı';
COMMENT ON COLUMN activity_logs.admin_id IS 'İşlemi yapan admin kullanıcı ID';
COMMENT ON COLUMN activity_logs.admin_username IS 'İşlemi yapan admin kullanıcı adı';
COMMENT ON COLUMN activity_logs.action_type IS 'İşlem tipi (user_created, user_updated, vb.)';
COMMENT ON COLUMN activity_logs.target_user_id IS 'İşlem yapılan kullanıcı ID (varsa)';
COMMENT ON COLUMN activity_logs.target_username IS 'İşlem yapılan kullanıcı adı (varsa)';
COMMENT ON COLUMN activity_logs.details IS 'İşlem detayları (JSON)';
COMMENT ON COLUMN activity_logs.ip_address IS 'İşlemi yapan kullanıcının IP adresi';
COMMENT ON COLUMN activity_logs.created_at IS 'İşlem zamanı';
