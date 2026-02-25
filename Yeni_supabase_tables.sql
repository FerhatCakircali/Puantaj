-- ============================================
-- SUPABASE VERITABANI ŞEMASI - TAM VERSİYON
-- Puantaj Yönetim Sistemi
-- ============================================

-- ============================================
-- 1. KULLANICI VE ROL YÖNETİMİ
-- ============================================

-- Kullanıcı rolleri için enum
CREATE TYPE user_role AS ENUM ('admin', 'manager', 'worker');

-- Kullanıcılar tablosu (Yöneticiler)
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  username TEXT UNIQUE NOT NULL CHECK (length(username) >= 3),
  password_hash TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  job_title TEXT NOT NULL,
  role user_role NOT NULL DEFAULT 'manager',
  is_admin BOOLEAN NOT NULL DEFAULT FALSE,
  is_blocked BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 2. ÇALIŞAN YÖNETİMİ
-- ============================================

-- Çalışanlar tablosu
CREATE TABLE workers (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL CHECK (length(username) >= 3),
  password_hash TEXT NOT NULL,
  full_name TEXT NOT NULL,
  title TEXT,
  phone TEXT,
  start_date DATE NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  is_trusted BOOLEAN NOT NULL DEFAULT FALSE, -- Otomatik onay için
  last_login TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 3. DEVAM TAKİP SİSTEMİ
-- ============================================

-- Devam takip tablosu (Onaylanmış kayıtlar)
CREATE TABLE attendance (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  worker_id BIGINT REFERENCES workers(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('fullDay', 'halfDay', 'absent')),
  created_by TEXT NOT NULL CHECK (created_by IN ('manager', 'worker')), -- Kim oluşturdu
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(worker_id, date) -- Bir çalışan için günde bir kayıt
);

-- Yevmiye talep tablosu (Çalışan talepleri)
CREATE TABLE attendance_requests (
  id BIGSERIAL PRIMARY KEY,
  worker_id BIGINT NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('fullDay', 'halfDay', 'absent')),
  request_status TEXT NOT NULL DEFAULT 'pending' CHECK (request_status IN ('pending', 'approved', 'rejected')),
  requested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reviewed_by BIGINT REFERENCES users(id),
  rejection_reason TEXT,
  UNIQUE(worker_id, date) -- Bir çalışan günde bir talep
);

-- ============================================
-- 4. ÖDEME YÖNETİMİ
-- ============================================

-- Ödemeler tablosu
CREATE TABLE payments (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  worker_id BIGINT REFERENCES workers(id) ON DELETE CASCADE,
  full_days INTEGER NOT NULL DEFAULT 0 CHECK (full_days >= 0),
  half_days INTEGER NOT NULL DEFAULT 0 CHECK (half_days >= 0),
  payment_date DATE NOT NULL,
  amount DECIMAL(10, 2) NOT NULL DEFAULT 0.0 CHECK (amount >= 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Ödenen günler tablosu
CREATE TABLE paid_days (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  worker_id BIGINT REFERENCES workers(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('fullDay', 'halfDay')),
  payment_id BIGINT REFERENCES payments(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 5. BİLDİRİM SİSTEMİ
-- ============================================

-- Bildirim ayarları tablosu (Yöneticiler için)
CREATE TABLE notification_settings (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  time TIME NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  auto_approve_trusted BOOLEAN NOT NULL DEFAULT FALSE, -- Güvenilir çalışanları otomatik onayla
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id) -- Her kullanıcı için bir ayar
);

-- Çalışan bildirim ayarları tablosu (Çalışanlar için)
CREATE TABLE notification_settings_workers (
  id BIGSERIAL PRIMARY KEY,
  worker_id BIGINT NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  time TIME NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(worker_id) -- Her çalışan için bir ayar
);

-- Çalışan hatırlatıcıları tablosu
CREATE TABLE employee_reminders (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  worker_id BIGINT NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  worker_name TEXT NOT NULL,
  reminder_date TIMESTAMP WITH TIME ZONE NOT NULL,
  message TEXT NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Genel bildirimler tablosu
CREATE TABLE notifications (
  id BIGSERIAL PRIMARY KEY,
  sender_id BIGINT,
  sender_type TEXT NOT NULL CHECK (sender_type IN ('user', 'worker', 'system')),
  recipient_id BIGINT NOT NULL,
  recipient_type TEXT NOT NULL CHECK (recipient_type IN ('user', 'worker')),
  notification_type TEXT NOT NULL CHECK (notification_type IN ('attendance_request', 'attendance_reminder', 'attendance_approved', 'attendance_rejected', 'general')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  related_id BIGINT, -- attendance_request_id veya başka ilişkili kayıt
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 6. PERFORMANS İÇİN İNDEXLER
-- ============================================

CREATE INDEX idx_workers_user_id ON workers(user_id);
CREATE INDEX idx_workers_username ON workers(username);
CREATE INDEX idx_workers_is_active ON workers(is_active);

CREATE INDEX idx_attendance_worker_id ON attendance(worker_id);
CREATE INDEX idx_attendance_user_id ON attendance(user_id);
CREATE INDEX idx_attendance_date ON attendance(date);
CREATE INDEX idx_attendance_worker_date ON attendance(worker_id, date);

CREATE INDEX idx_attendance_requests_worker_id ON attendance_requests(worker_id);
CREATE INDEX idx_attendance_requests_user_id ON attendance_requests(user_id);
CREATE INDEX idx_attendance_requests_status ON attendance_requests(request_status);
CREATE INDEX idx_attendance_requests_date ON attendance_requests(date);

CREATE INDEX idx_payments_worker_id ON payments(worker_id);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_date ON payments(payment_date);

CREATE INDEX idx_paid_days_payment_id ON paid_days(payment_id);
CREATE INDEX idx_paid_days_worker_id ON paid_days(worker_id);

CREATE INDEX idx_notification_settings_workers_worker_id ON notification_settings_workers(worker_id);
CREATE INDEX idx_notification_settings_workers_enabled ON notification_settings_workers(enabled);

CREATE INDEX idx_employee_reminders_user_id ON employee_reminders(user_id);
CREATE INDEX idx_employee_reminders_worker_id ON employee_reminders(worker_id);
CREATE INDEX idx_employee_reminders_date ON employee_reminders(reminder_date);
CREATE INDEX idx_employee_reminders_completed ON employee_reminders(is_completed);

CREATE INDEX idx_notifications_recipient ON notifications(recipient_id, recipient_type);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- ============================================
-- 7. YARDIMCI FONKSİYONLAR
-- ============================================

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

-- Kayıt sayısını döndüren fonksiyon
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

-- Çoklu koşulla kayıt sayısını döndüren fonksiyon
CREATE OR REPLACE FUNCTION count_records_multiple(table_name TEXT, conditions JSONB)
RETURNS INTEGER AS $$
DECLARE
  query TEXT;
  where_clause TEXT := '';
  result INTEGER;
  r RECORD;
  i INTEGER := 0;
BEGIN
  FOR r IN SELECT * FROM jsonb_each_text(conditions) LOOP
    IF i > 0 THEN
      where_clause := where_clause || ' AND ';
    END IF;
    where_clause := where_clause || format('%I = %L', r.key, r.value);
    i := i + 1;
  END LOOP;
  
  IF i = 0 THEN
    query := format('SELECT COUNT(*) FROM %I', table_name);
  ELSE
    query := format('SELECT COUNT(*) FROM %I WHERE %s', table_name, where_clause);
  END IF;
  
  EXECUTE query INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Çalışan için aylık istatistikleri hesaplayan fonksiyon
-- NOT: Bu fonksiyon artık Flutter tarafında kullanılmıyor!
-- Hesaplama Dart tarafında yapılıyor (attendance_request_repository.dart)
-- Bu fonksiyon sadece geriye dönük uyumluluk için saklanıyor.
CREATE OR REPLACE FUNCTION get_worker_monthly_stats(worker_id_param BIGINT, month_start DATE, month_end DATE)
RETURNS TABLE (
  total_full_days BIGINT,
  total_half_days BIGINT,
  total_absent_days BIGINT,
  total_amount DECIMAL
) AS $$
DECLARE
  days_in_period INTEGER;
  worked_days BIGINT;
BEGIN
  -- Dönem içindeki toplam gün sayısını hesapla
  days_in_period := month_end - month_start + 1;
  
  RETURN QUERY
  SELECT 
    -- Attendance tablosundan gün sayılarını hesapla
    COUNT(DISTINCT CASE WHEN a.status = 'fullDay' THEN a.date END) as total_full_days,
    COUNT(DISTINCT CASE WHEN a.status = 'halfDay' THEN a.date END) as total_half_days,
    -- Gelmedi = Toplam gün - (Tam gün + Yarım gün)
    (days_in_period - COUNT(DISTINCT CASE WHEN a.status IN ('fullDay', 'halfDay') THEN a.date END))::BIGINT as total_absent_days,
    -- Payments tablosundan ödenen tutarları hesapla (subquery ile)
    (
      SELECT COALESCE(SUM(p.amount), 0)
      FROM payments p
      WHERE p.worker_id = worker_id_param
        AND p.payment_date >= month_start
        AND p.payment_date <= month_end
    ) as total_amount
  FROM attendance a
  WHERE a.worker_id = worker_id_param
    AND a.date >= month_start
    AND a.date <= month_end;
END;
$$ LANGUAGE plpgsql;

-- Yevmiye girişi yapmamış çalışanları bulan fonksiyon
CREATE OR REPLACE FUNCTION get_workers_without_attendance(user_id_param BIGINT, check_date DATE)
RETURNS TABLE (
  worker_id BIGINT,
  worker_name TEXT,
  username TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    w.id as worker_id,
    w.full_name as worker_name,
    w.username
  FROM workers w
  WHERE w.user_id = user_id_param
    AND w.is_active = TRUE
    AND NOT EXISTS (
      SELECT 1 FROM attendance a 
      WHERE a.worker_id = w.id AND a.date = check_date
    )
    AND NOT EXISTS (
      SELECT 1 FROM attendance_requests ar 
      WHERE ar.worker_id = w.id AND ar.date = check_date
    );
END;
$$ LANGUAGE plpgsql;

-- Yevmiye yapmamış çalışanlara toplu bildirim gönderen fonksiyon
CREATE OR REPLACE FUNCTION send_attendance_reminder_to_workers(user_id_param BIGINT, check_date DATE)
RETURNS INTEGER AS $$
DECLARE
  worker_record RECORD;
  notification_count INTEGER := 0;
BEGIN
  -- Yevmiye yapmamış çalışanları bul ve bildirim gönder
  FOR worker_record IN 
    SELECT * FROM get_workers_without_attendance(user_id_param, check_date)
  LOOP
    INSERT INTO notifications (
      sender_id, sender_type, recipient_id, recipient_type,
      notification_type, title, message
    ) VALUES (
      user_id_param, 'user', worker_record.worker_id, 'worker',
      'attendance_reminder', 'Yevmiye Girişi Hatırlatması',
      'Bugün (' || check_date || ') için henüz yevmiye girişi yapmadınız. Lütfen giriş yapınız.'
    );
    
    notification_count := notification_count + 1;
  END LOOP;
  
  RETURN notification_count;
END;
$$ LANGUAGE plpgsql;

-- Çalışan için toplam ödeme miktarını hesaplayan fonksiyon
CREATE OR REPLACE FUNCTION get_worker_total_payments(worker_id_param BIGINT)
RETURNS DECIMAL AS $$
DECLARE
  total_amount DECIMAL;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO total_amount
  FROM payments
  WHERE worker_id = worker_id_param;
  
  RETURN total_amount;
END;
$$ LANGUAGE plpgsql;

-- Çalışan için geçmiş yevmiye kayıtlarını getiren fonksiyon (sadece okuma)
CREATE OR REPLACE FUNCTION get_worker_attendance_history(worker_id_param BIGINT, start_date DATE, end_date DATE)
RETURNS TABLE (
  attendance_date DATE,
  status TEXT,
  created_by TEXT,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.date as attendance_date,
    a.status,
    a.created_by,
    a.created_at
  FROM attendance a
  WHERE a.worker_id = worker_id_param
    AND a.date >= start_date
    AND a.date <= end_date
  ORDER BY a.date DESC;
END;
$$ LANGUAGE plpgsql;

-- Çalışan için bugünün yevmiye durumunu kontrol eden fonksiyon
CREATE OR REPLACE FUNCTION check_worker_today_attendance_status(worker_id_param BIGINT, check_date DATE)
RETURNS TABLE (
  can_submit BOOLEAN,
  status_type TEXT, -- 'none', 'pending', 'approved', 'rejected', 'manager_entered'
  status_value TEXT, -- 'fullDay', 'halfDay', 'absent' veya NULL
  message TEXT
) AS $$
DECLARE
  attendance_exists BOOLEAN;
  request_exists BOOLEAN;
  request_status TEXT;
  request_value TEXT;
  attendance_value TEXT;
BEGIN
  -- Yönetici tarafından girilmiş kayıt var mı?
  SELECT EXISTS(
    SELECT 1 FROM attendance 
    WHERE worker_id = worker_id_param AND date = check_date
  ) INTO attendance_exists;
  
  IF attendance_exists THEN
    SELECT a.status INTO attendance_value
    FROM attendance a
    WHERE a.worker_id = worker_id_param AND a.date = check_date;
    
    RETURN QUERY SELECT 
      FALSE as can_submit,
      'manager_entered'::TEXT as status_type,
      attendance_value as status_value,
      'Yöneticiniz bugün için girişinizi yaptı: ' || 
      CASE 
        WHEN attendance_value = 'fullDay' THEN 'Tam Gün'
        WHEN attendance_value = 'halfDay' THEN 'Yarım Gün'
        WHEN attendance_value = 'absent' THEN 'Gelmedi'
      END as message;
    RETURN;
  END IF;
  
  -- Çalışan tarafından gönderilmiş talep var mı?
  SELECT EXISTS(
    SELECT 1 FROM attendance_requests 
    WHERE worker_id = worker_id_param AND date = check_date
  ) INTO request_exists;
  
  IF request_exists THEN
    SELECT ar.request_status, ar.status INTO request_status, request_value
    FROM attendance_requests ar
    WHERE ar.worker_id = worker_id_param AND ar.date = check_date;
    
    IF request_status = 'pending' THEN
      RETURN QUERY SELECT 
        FALSE as can_submit,
        'pending'::TEXT as status_type,
        request_value as status_value,
        'Talebiniz onay bekliyor: ' || 
        CASE 
          WHEN request_value = 'fullDay' THEN 'Tam Gün'
          WHEN request_value = 'halfDay' THEN 'Yarım Gün'
          WHEN request_value = 'absent' THEN 'Gelmedi'
        END as message;
      RETURN;
    ELSIF request_status = 'approved' THEN
      RETURN QUERY SELECT 
        FALSE as can_submit,
        'approved'::TEXT as status_type,
        request_value as status_value,
        'Talebiniz onaylandı: ' || 
        CASE 
          WHEN request_value = 'fullDay' THEN 'Tam Gün'
          WHEN request_value = 'halfDay' THEN 'Yarım Gün'
          WHEN request_value = 'absent' THEN 'Gelmedi'
        END as message;
      RETURN;
    ELSIF request_status = 'rejected' THEN
      RETURN QUERY SELECT 
        TRUE as can_submit,
        'rejected'::TEXT as status_type,
        request_value as status_value,
        'Talebiniz reddedildi. Yeniden giriş yapabilirsiniz.' as message;
      RETURN;
    END IF;
  END IF;
  
  -- Hiçbir kayıt yok, giriş yapabilir
  RETURN QUERY SELECT 
    TRUE as can_submit,
    'none'::TEXT as status_type,
    NULL::TEXT as status_value,
    'Bugün için yevmiye girişi yapabilirsiniz.' as message;
END;
$$ LANGUAGE plpgsql;

-- Çalışan şifre değiştirme fonksiyonu
CREATE OR REPLACE FUNCTION change_worker_password(worker_id_param BIGINT, old_password_hash TEXT, new_password_hash TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  current_password TEXT;
BEGIN
  -- Mevcut şifreyi kontrol et
  SELECT password_hash INTO current_password
  FROM workers
  WHERE id = worker_id_param;
  
  -- Eski şifre doğru mu kontrol et
  IF current_password = old_password_hash THEN
    -- Yeni şifreyi güncelle
    UPDATE workers
    SET password_hash = new_password_hash,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = worker_id_param;
    
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Kullanıcı şifre değiştirme fonksiyonu
CREATE OR REPLACE FUNCTION change_user_password(user_id_param BIGINT, old_password_hash TEXT, new_password_hash TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  current_password TEXT;
BEGIN
  SELECT password_hash INTO current_password
  FROM users
  WHERE id = user_id_param;
  
  IF current_password = old_password_hash THEN
    UPDATE users
    SET password_hash = new_password_hash,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = user_id_param;
    
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Bekleyen talepleri toplu onaylayan fonksiyon
CREATE OR REPLACE FUNCTION approve_all_pending_requests(user_id_param BIGINT, reviewed_by_param BIGINT)
RETURNS INTEGER AS $$
DECLARE
  approved_count INTEGER := 0;
  request_record RECORD;
BEGIN
  -- Kullanıcının bekleyen tüm taleplerini al
  FOR request_record IN 
    SELECT * FROM attendance_requests 
    WHERE user_id = user_id_param 
    AND request_status = 'pending'
  LOOP
    -- Attendance tablosuna ekle
    INSERT INTO attendance (user_id, worker_id, date, status, created_by)
    VALUES (
      request_record.user_id,
      request_record.worker_id,
      request_record.date,
      request_record.status,
      'worker'
    )
    ON CONFLICT (worker_id, date) DO NOTHING;
    
    -- Request'i onayla
    UPDATE attendance_requests
    SET request_status = 'approved',
        reviewed_at = CURRENT_TIMESTAMP,
        reviewed_by = reviewed_by_param
    WHERE id = request_record.id;
    
    -- Bildirim oluştur
    INSERT INTO notifications (
      sender_id, sender_type, recipient_id, recipient_type,
      notification_type, title, message, related_id
    ) VALUES (
      reviewed_by_param, 'user', request_record.worker_id, 'worker',
      'attendance_approved', 'Yevmiye Onaylandı',
      request_record.date || ' tarihli yevmiye girişiniz onaylandı.',
      request_record.id
    );
    
    approved_count := approved_count + 1;
  END LOOP;
  
  RETURN approved_count;
END;
$$ LANGUAGE plpgsql;

-- Tek bir talebi onaylayan fonksiyon
CREATE OR REPLACE FUNCTION approve_attendance_request(request_id_param BIGINT, reviewed_by_param BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
  request_record RECORD;
BEGIN
  -- Talebi al
  SELECT * INTO request_record
  FROM attendance_requests
  WHERE id = request_id_param AND request_status = 'pending';
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Attendance tablosuna ekle (Türkiye saati ile)
  INSERT INTO attendance (user_id, worker_id, date, status, created_by, created_at, updated_at)
  VALUES (
    request_record.user_id,
    request_record.worker_id,
    request_record.date,
    request_record.status,
    'worker',
    CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul',
    CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul'
  )
  ON CONFLICT (worker_id, date) DO NOTHING;
  
  -- Request'i onayla
  UPDATE attendance_requests
  SET request_status = 'approved',
      reviewed_at = CURRENT_TIMESTAMP,
      reviewed_by = reviewed_by_param
  WHERE id = request_id_param;
  
  -- Bildirim oluştur
  INSERT INTO notifications (
    sender_id, sender_type, recipient_id, recipient_type,
    notification_type, title, message, related_id
  ) VALUES (
    reviewed_by_param, 'user', request_record.worker_id, 'worker',
    'attendance_approved', 'Yevmiye Onaylandı',
    request_record.date || ' tarihli yevmiye girişiniz onaylandı.',
    request_id_param
  );
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Tek bir talebi reddeden fonksiyon
CREATE OR REPLACE FUNCTION reject_attendance_request(request_id_param BIGINT, reviewed_by_param BIGINT, reason TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  request_record RECORD;
BEGIN
  -- Talebi al
  SELECT * INTO request_record
  FROM attendance_requests
  WHERE id = request_id_param AND request_status = 'pending';
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Request'i reddet
  UPDATE attendance_requests
  SET request_status = 'rejected',
      reviewed_at = CURRENT_TIMESTAMP,
      reviewed_by = reviewed_by_param,
      rejection_reason = reason
  WHERE id = request_id_param;
  
  -- Bildirim oluştur
  INSERT INTO notifications (
    sender_id, sender_type, recipient_id, recipient_type,
    notification_type, title, message, related_id
  ) VALUES (
    reviewed_by_param, 'user', request_record.worker_id, 'worker',
    'attendance_rejected', 'Yevmiye Reddedildi',
    request_record.date || ' tarihli yevmiye girişiniz reddedildi. Sebep: ' || COALESCE(reason, 'Belirtilmedi'),
    request_id_param
  );
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Otomatik onay kontrolü ve işlemi yapan fonksiyon
CREATE OR REPLACE FUNCTION auto_approve_if_trusted()
RETURNS TRIGGER AS $$
DECLARE
  is_trusted_worker BOOLEAN;
  auto_approve_enabled BOOLEAN;
BEGIN
  -- Çalışan güvenilir mi kontrol et
  SELECT w.is_trusted INTO is_trusted_worker
  FROM workers w
  WHERE w.id = NEW.worker_id;
  
  -- Yöneticinin otomatik onay ayarı açık mı kontrol et
  SELECT COALESCE(ns.auto_approve_trusted, FALSE) INTO auto_approve_enabled
  FROM notification_settings ns
  WHERE ns.user_id = NEW.user_id;
  
  -- Eğer her ikisi de true ise otomatik onayla
  IF COALESCE(is_trusted_worker, FALSE) AND auto_approve_enabled THEN
    -- Attendance tablosuna ekle (Türkiye saati ile)
    INSERT INTO attendance (user_id, worker_id, date, status, created_by, created_at, updated_at)
    VALUES (
      NEW.user_id, 
      NEW.worker_id, 
      NEW.date, 
      NEW.status, 
      'worker',
      CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul',
      CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul'
    )
    ON CONFLICT (worker_id, date) DO NOTHING;
    
    -- Request'i onayla
    NEW.request_status := 'approved';
    NEW.reviewed_at := CURRENT_TIMESTAMP;
    NEW.reviewed_by := NEW.user_id;
    
    -- Bildirim oluştur
    INSERT INTO notifications (
      sender_type, recipient_id, recipient_type,
      notification_type, title, message, related_id
    ) VALUES (
      'system', NEW.worker_id, 'worker',
      'attendance_approved', 'Yevmiye Otomatik Onaylandı',
      NEW.date || ' tarihli yevmiye girişiniz otomatik olarak onaylandı.',
      NEW.id
    );
  ELSE
    -- Otomatik onay yoksa yöneticiye bildirim gönder
    INSERT INTO notifications (
      sender_id, sender_type, recipient_id, recipient_type,
      notification_type, title, message, related_id
    ) VALUES (
      NEW.worker_id, 'worker', NEW.user_id, 'user',
      'attendance_request', 'Yeni Yevmiye Talebi',
      (SELECT full_name FROM workers WHERE id = NEW.worker_id) || ' ' || NEW.date || ' tarihli yevmiye girişi için onay bekliyor.',
      NEW.id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. TRİGGERLAR
-- ============================================

-- Otomatik onay trigger'ı
CREATE TRIGGER trigger_auto_approve_attendance
  BEFORE INSERT ON attendance_requests
  FOR EACH ROW
  EXECUTE FUNCTION auto_approve_if_trusted();

-- Updated_at otomatik güncelleme trigger'ı (users)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workers_updated_at
  BEFORE UPDATE ON workers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 9. ROW LEVEL SECURITY (RLS) POLİTİKALARI
-- ============================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE paid_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings_workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Geçici olarak tüm erişime izin ver (production'da düzenlenmeli)
CREATE POLICY "allow_all_users" ON users FOR ALL USING (true);
CREATE POLICY "allow_all_workers" ON workers FOR ALL USING (true);
CREATE POLICY "allow_all_attendance" ON attendance FOR ALL USING (true);
CREATE POLICY "allow_all_attendance_requests" ON attendance_requests FOR ALL USING (true);
CREATE POLICY "allow_all_payments" ON payments FOR ALL USING (true);
CREATE POLICY "allow_all_paid_days" ON paid_days FOR ALL USING (true);
CREATE POLICY "allow_all_notification_settings" ON notification_settings FOR ALL USING (true);
CREATE POLICY "allow_all_notification_settings_workers" ON notification_settings_workers FOR ALL USING (true);
CREATE POLICY "allow_all_employee_reminders" ON employee_reminders FOR ALL USING (true);
CREATE POLICY "allow_all_notifications" ON notifications FOR ALL USING (true);

-- ============================================
-- 10. BAŞLANGIÇ VERİLERİ
-- ============================================

-- Admin hesabı oluştur (şifre: ferhatcakircali - production'da hash'lenmeli)
INSERT INTO users (username, password_hash, first_name, last_name, job_title, role, is_admin, is_blocked)
SELECT 
  'admin', 
  'ferhatcakircali', -- ÖNEMLİ: Production'da bcrypt hash kullanılmalı
  'Ferhat', 
  'ÇAKIRCALI', 
  'System Administrator', 
  'admin',
  TRUE, 
  FALSE
WHERE NOT EXISTS (
  SELECT 1 FROM users WHERE username = 'admin'
);

-- ============================================
-- NOTLAR VE UYARILAR
-- ============================================

-- 1. ŞİFRE GÜVENLİĞİ:
--    Production ortamında password_hash alanına bcrypt veya argon2 
--    ile hash'lenmiş şifreler kaydedilmelidir.
--
-- 2. RLS POLİTİKALARI:
--    Şu anda tüm tablolar için "allow_all" politikası aktif.
--    Production'da kullanıcı bazlı kısıtlamalar eklenmeli.
--
-- 3. YEDEKLEME:
--    Düzenli veritabanı yedeklemeleri alınmalıdır.
--
-- 4. PERFORMANS:
--    Büyük veri setlerinde ek indexler gerekebilir.
--
-- 5. MİGRASYON:
--    Mevcut veriler varsa, migration script'leri hazırlanmalıdır.
--
-- 6. FONKSİYON KULLANIMI:
--    - send_attendance_reminder_to_workers(): Yevmiye yapmamış çalışanlara bildirim gönderir
--    - approve_all_pending_requests(): Tüm bekleyen talepleri toplu onayla
--    - approve_attendance_request(): Tek bir talebi onayla
--    - reject_attendance_request(): Tek bir talebi reddet
--    - get_worker_total_payments(): Çalışanın toplam aldığı para
--    - get_worker_monthly_stats(): Çalışanın aylık istatistikleri
--    - get_worker_attendance_history(): Çalışanın geçmiş yevmiye kayıtları
--    - change_worker_password(): Çalışan şifre değiştirme
--    - change_user_password(): Kullanıcı şifre değiştirme
--
-- 7. ÇALIŞAN PANELİ İÇİN GEREKLİ SORGULAR:
--    
--    a) Bugün için yevmiye durumu kontrolü (EN ÖNEMLİ):
--       SELECT * FROM check_worker_today_attendance_status(?, CURRENT_DATE)
--       Dönen değerler:
--       - can_submit: Giriş yapabilir mi? (true/false)
--       - status_type: 'none', 'pending', 'approved', 'rejected', 'manager_entered'
--       - status_value: 'fullDay', 'halfDay', 'absent' veya NULL
--       - message: Kullanıcıya gösterilecek mesaj
--    
--    b) Yevmiye talebi gönder:
--       INSERT INTO attendance_requests (worker_id, user_id, date, status)
--       VALUES (?, ?, CURRENT_DATE, 'fullDay')
--       (Trigger otomatik olarak onay kontrolü yapar ve bildirim gönderir)
--    
--    c) Aylık istatistikler:
--       SELECT * FROM get_worker_monthly_stats(?, '2026-02-01', '2026-02-28')
--    
--    d) Toplam kazanç:
--       SELECT get_worker_total_payments(?)
--    
--    e) Geçmiş kayıtlar (son 30 gün):
--       SELECT * FROM get_worker_attendance_history(?, CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE)
--    
--    f) Profil bilgilerini güncelle:
--       UPDATE workers SET full_name = ?, title = ?, phone = ?, updated_at = CURRENT_TIMESTAMP
--       WHERE id = ?
--    
--    g) Şifre değiştir:
--       SELECT change_worker_password(?, 'old_hash', 'new_hash')
--    
--    h) Okunmamış bildirimler:
--       SELECT * FROM notifications 
--       WHERE recipient_id = ? AND recipient_type = 'worker' AND is_read = FALSE
--       ORDER BY created_at DESC
--    
--    i) Bildirimi okundu işaretle:
--       UPDATE notifications SET is_read = TRUE WHERE id = ?
--    
--    j) Çalışan hatırlatıcı ayarlarını getir:
--       SELECT * FROM notification_settings_workers WHERE worker_id = ?
--    
--    k) Çalışan hatırlatıcı ayarlarını oluştur/güncelle (UPSERT):
--       INSERT INTO notification_settings_workers (worker_id, time, enabled)
--       VALUES (?, '18:00', true)
--       ON CONFLICT (worker_id) 
--       DO UPDATE SET 
--         time = EXCLUDED.time, 
--         enabled = EXCLUDED.enabled, 
--         last_updated = CURRENT_TIMESTAMP
--    
--    l) Çalışan hatırlatıcı ayarlarını sil:
--       DELETE FROM notification_settings_workers WHERE worker_id = ?
--
-- 8. YÖNETİCİ PANELİ İÇİN GEREKLİ SORGULAR:
--    
--    a) Bekleyen talepler (sayı):
--       SELECT COUNT(*) FROM attendance_requests 
--       WHERE user_id = ? AND request_status = 'pending'
--    
--    b) Bekleyen talepler (detaylı):
--       SELECT ar.*, w.full_name, w.username
--       FROM attendance_requests ar
--       JOIN workers w ON ar.worker_id = w.id
--       WHERE ar.user_id = ? AND ar.request_status = 'pending'
--       ORDER BY ar.requested_at DESC
--    
--    c) Yevmiye yapmamış çalışanlar:
--       SELECT * FROM get_workers_without_attendance(?, CURRENT_DATE)
--    
--    d) Toplu hatırlatma gönder:
--       SELECT send_attendance_reminder_to_workers(?, CURRENT_DATE)
--       (Dönen sayı: Kaç çalışana bildirim gönderildi)
--    
--    e) Toplu onay:
--       SELECT approve_all_pending_requests(?, ?)
--       (Dönen sayı: Kaç talep onaylandı)
--    
--    f) Tek onay:
--       SELECT approve_attendance_request(request_id, user_id)
--       (Dönen: true/false)
--    
--    g) Tek red:
--       SELECT reject_attendance_request(request_id, user_id, 'Red sebebi')
--       (Dönen: true/false)
--    
--    h) Otomatik onay ayarını güncelle:
--       UPDATE notification_settings 
--       SET auto_approve_trusted = true, last_updated = CURRENT_TIMESTAMP
--       WHERE user_id = ?
--    
--    i) Çalışanı güvenilir işaretle:
--       UPDATE workers SET is_trusted = true, updated_at = CURRENT_TIMESTAMP
--       WHERE id = ?
--    
--    j) Okunmamış bildirimler:
--       SELECT * FROM notifications 
--       WHERE recipient_id = ? AND recipient_type = 'user' AND is_read = FALSE
--       ORDER BY created_at DESC LIMIT 50
--    
--    k) Yönetici manuel yevmiye girişi:
--       INSERT INTO attendance (user_id, worker_id, date, status, created_by)
--       VALUES (?, ?, ?, ?, 'manager')
--       (Çalışan artık o gün için talep gönderemez)


-- ============================================
-- 9. BİLDİRİM AYARLARI TABLO AYIRIMI
-- ============================================
--
-- ÖNEMLI: Bildirim ayarları için 2 ayrı tablo kullanılıyor:
--
-- 1. notification_settings (Yöneticiler için):
--    - user_id -> users tablosuna referans
--    - auto_approve_trusted alanı VAR
--    - Yöneticilerin yevmiye hatırlatıcısı ve otomatik onay ayarları
--
-- 2. notification_settings_workers (Çalışanlar için):
--    - worker_id -> workers tablosuna referans
--    - auto_approve_trusted alanı YOK (çalışanlar için gereksiz)
--    - Çalışanların kendi yevmiye hatırlatıcısı ayarları
--
-- NEDEN AYRI TABLOLAR?
--    - ID çakışması riski YOK (users.id ve workers.id farklı tablolar)
--    - Her tablonun kendi mantığı var
--    - Temiz ve anlaşılır yapı
--    - Performans optimizasyonu
--
-- KULLANIM:
--    - Yönetici: notification_settings tablosunu kullan
--    - Çalışan: notification_settings_workers tablosunu kullan
--
-- ============================================
