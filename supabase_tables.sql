-- Supabase için tek bir SQL sorgusu
-- Tablolar ve yardımcı fonksiyonlar

-- Kullanıcılar tablosu
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  job_title TEXT NOT NULL,
  is_admin INTEGER NOT NULL DEFAULT 0,
  is_blocked BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Çalışanlar tablosu
CREATE TABLE workers (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  title TEXT,
  phone TEXT,
  start_date TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Devam takip tablosu
CREATE TABLE attendance (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  worker_id BIGINT REFERENCES workers(id) ON DELETE CASCADE,
  date TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('fullDay', 'halfDay', 'absent'))
);

-- Ödemeler tablosu
CREATE TABLE payments (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  worker_id BIGINT REFERENCES workers(id) ON DELETE CASCADE,
  full_days INTEGER NOT NULL DEFAULT 0,
  half_days INTEGER NOT NULL DEFAULT 0,
  payment_date TEXT NOT NULL,
  amount DECIMAL(10, 2) NOT NULL DEFAULT 0.0
);

-- Ödenen günler tablosu
CREATE TABLE paid_days (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  worker_id BIGINT REFERENCES workers(id) ON DELETE CASCADE,
  date TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('fullDay', 'halfDay')),
  payment_id BIGINT REFERENCES payments(id) ON DELETE CASCADE
);

-- Bildirim ayarları tablosu
CREATE TABLE notification_settings (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  time TEXT NOT NULL,
  enabled INTEGER NOT NULL DEFAULT 1,
  last_updated TEXT NOT NULL
);

-- Çalışan hatırlatıcıları tablosu
CREATE TABLE employee_reminders (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  worker_id BIGINT NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  worker_name TEXT NOT NULL,
  reminder_date TIMESTAMP WITH TIME ZONE NOT NULL,
  message TEXT NOT NULL,
  is_completed INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Sahipsiz ödemeleri bulan fonksiyon
CREATE OR REPLACE FUNCTION find_orphaned_payments(user_id_param BIGINT, worker_id_param BIGINT)
RETURNS TABLE (id BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT p.id 
  FROM payments p
  LEFT JOIN paid_days pd ON p.id = pd.payment_id
  WHERE p.user_id = user_id_param 
  AND p.worker_id = worker_id_param
  GROUP BY p.id
  HAVING COUNT(pd.id) = 0;
END;
$$ LANGUAGE plpgsql;

-- Ödeme gün sayılarını hesaplayan fonksiyon
CREATE OR REPLACE FUNCTION get_payment_day_counts(user_id_param BIGINT, worker_id_param BIGINT)
RETURNS TABLE (payment_id BIGINT, full_days BIGINT, half_days BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id as payment_id,
    COUNT(CASE WHEN pd.status = 'fullDay' THEN 1 ELSE NULL END) as full_days,
    COUNT(CASE WHEN pd.status = 'halfDay' THEN 1 ELSE NULL END) as half_days
  FROM payments p
  LEFT JOIN paid_days pd ON p.id = pd.payment_id
  WHERE p.user_id = user_id_param 
  AND p.worker_id = worker_id_param
  GROUP BY p.id;
END;
$$ LANGUAGE plpgsql;

-- Kayıt sayısını döndüren stored procedure
CREATE OR REPLACE FUNCTION count_records(table_name TEXT, where_field TEXT, where_value TEXT)
RETURNS INTEGER AS $$
DECLARE
  query TEXT;
  result INTEGER;
BEGIN
  IF where_field IS NULL OR where_value IS NULL THEN
    query := format('SELECT COUNT(*) FROM %I', table_name);
  ELSE
    query := format('SELECT COUNT(*) FROM %I WHERE %I = %L', table_name, where_field, where_value);
  END IF;
  
  EXECUTE query INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Çoklu koşulla kayıt sayısını döndüren stored procedure
CREATE OR REPLACE FUNCTION count_records_multiple(table_name TEXT, conditions JSONB)
RETURNS INTEGER AS $$
DECLARE
  query TEXT;
  where_clause TEXT := '';
  result INTEGER;
  r RECORD;
  i INTEGER := 0;
BEGIN
  -- Koşulları WHERE cümlesi haline getir
  FOR r IN SELECT * FROM jsonb_each_text(conditions) LOOP
    IF i > 0 THEN
      where_clause := where_clause || ' AND ';
    END IF;
    where_clause := where_clause || format('%I = %L', r.key, r.value);
    i := i + 1;
  END LOOP;
  
  -- Tam sorguyu oluştur
  IF i = 0 THEN
    query := format('SELECT COUNT(*) FROM %I', table_name);
  ELSE
    query := format('SELECT COUNT(*) FROM %I WHERE %s', table_name, where_clause);
  END IF;
  
  -- Sorguyu çalıştır
  EXECUTE query INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Tabloların RLS (Row Level Security) politikalarını tanımla
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE paid_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_reminders ENABLE ROW LEVEL SECURITY;

-- Her tablo için RLS politikalarını oluştur
CREATE POLICY "allow_all_users" ON users FOR ALL USING (true);
CREATE POLICY "allow_all_workers" ON workers FOR ALL USING (true);
CREATE POLICY "allow_all_attendance" ON attendance FOR ALL USING (true);
CREATE POLICY "allow_all_payments" ON payments FOR ALL USING (true);
CREATE POLICY "allow_all_paid_days" ON paid_days FOR ALL USING (true);
CREATE POLICY "allow_all_notification_settings" ON notification_settings FOR ALL USING (true);
CREATE POLICY "users_can_manage_their_reminders" ON employee_reminders FOR ALL USING (true);

-- Bildirim ayarları tablosunun varsayılan değerlerini düzelt
ALTER TABLE notification_settings ALTER COLUMN time DROP DEFAULT;
ALTER TABLE notification_settings ALTER COLUMN enabled DROP DEFAULT; 

-- Admin hesabı oluştur (eğer yoksa)
INSERT INTO users (username, password, first_name, last_name, job_title, is_admin, is_blocked)
SELECT 'admin', 'ferhatcakircali', 'Ferhat', 'ÇAKIRCALI', 'System Administrator', 1, FALSE
WHERE NOT EXISTS (
  SELECT 1 FROM users WHERE username = 'admin'
); 