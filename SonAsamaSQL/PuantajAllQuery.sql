-- ============================================
-- PUANTAJ YÖNETİM SİSTEMİ  
-- ERD ve SQL Şeması 
-- ============================================

-- ============================================
-- SECTION 0: EXTENSIONS (PostgreSQL Eklentileri)
-- ============================================
-- 📌 AÇIKLAMA: PostgreSQL eklentilerini aktifleştirir
-- Bu bölüm veritabanına ekstra özellikler kazandırır

-- pgcrypto: Şifre hash'leme için (bcrypt)
-- 🔐 Şifreleri güvenli bir şekilde bcrypt algoritması ile hash'ler
-- Flutter PasswordHasher servisi ile uyumlu (cost=10)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================
-- SECTION 1: ENUM TYPES
-- ============================================
-- 📌 AÇIKLAMA: Özel veri tipleri tanımlar
-- Enum'lar belirli değerler arasından seçim yapılmasını sağlar

-- Kullanıcı rolleri için enum
-- 👥 Sistemdeki kullanıcı rollerini tanımlar: admin, manager, worker
CREATE TYPE user_role AS ENUM ('admin', 'manager', 'worker');

-- ============================================
-- SECTION 2: CORE TABLES (Ana Tablolar)
-- ============================================
-- 📌 AÇIKLAMA: Sistemin temel tablolarını oluşturur
-- Bu tablolar uygulamanın çekirdek verilerini saklar

-- ============================================
-- 2.1 USERS TABLE (Yöneticiler)
-- ============================================
-- 👤 Yönetici ve admin kullanıcılarının bilgilerini saklar
-- İlişkiler: workers (1-N), attendance (1-N), payments (1-N)

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
  created_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul'),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul'),
  -- Migration eklemeleri:
  email TEXT,
  email_verified BOOLEAN DEFAULT FALSE
);

-- ============================================
-- 2.2 WORKERS TABLE (Çalışanlar)
-- ============================================
-- 👷 Çalışan bilgilerini saklar (yöneticiye bağlı)
-- İlişkiler: users (N-1), attendance (1-N), payments (1-N)
-- is_trusted: Güvenilir çalışanlar otomatik onay alır

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
  is_trusted BOOLEAN NOT NULL DEFAULT FALSE,
  last_login TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul'),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul'),
  -- Migration eklemeleri:
  email TEXT,
  email_verified BOOLEAN DEFAULT FALSE
);

-- ============================================
-- 2.3 ATTENDANCE TABLE (Devam Takip)
-- ============================================
-- 📅 Onaylanmış yevmiye kayıtlarını saklar
-- status: fullDay (tam gün), halfDay (yarım gün), absent (gelmedi)
-- created_by: manager (yönetici girdi) veya worker (çalışan girdi)
-- notification_sent: Bildirim kontrolü için (tekrar bildirim önleme)

CREATE TABLE attendance (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  worker_id BIGINT REFERENCES workers(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('fullDay', 'halfDay', 'absent')),
  created_by TEXT NOT NULL CHECK (created_by IN ('manager', 'worker')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul'),
  UNIQUE(worker_id, date),
  -- Migration eklemeleri:
  notification_sent BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul') NOT NULL
);

COMMENT ON COLUMN attendance.notification_sent IS 
'Bu yevmiye kaydının bildirime dahil edilip edilmediğini takip eder. FCM servisi tarafından tekrar bildirim gönderilmesini önlemek için kullanılır.';

-- ============================================
-- 2.4 ATTENDANCE_REQUESTS TABLE (Yevmiye Talepleri)
-- ============================================
-- 📝 Çalışanların yevmiye taleplerini saklar
-- request_status: pending (bekliyor), approved (onaylandı), rejected (reddedildi)
-- Güvenilir çalışanlar otomatik approved olur (trigger ile)

CREATE TABLE attendance_requests (
  id BIGSERIAL PRIMARY KEY,
  worker_id BIGINT NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('fullDay', 'halfDay', 'absent')),
  request_status TEXT NOT NULL DEFAULT 'pending' CHECK (request_status IN ('pending', 'approved', 'rejected')),
  requested_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul'),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reviewed_by BIGINT REFERENCES users(id),
  rejection_reason TEXT,
  UNIQUE(worker_id, date),
  -- Migration eklemeleri:
  notification_sent BOOLEAN NOT NULL DEFAULT FALSE
);

-- ============================================
-- 2.5 PAYMENTS TABLE (Ödemeler)
-- ============================================
-- 💰 Çalışanlara yapılan ödemeleri saklar
-- full_days: Ödenen tam gün sayısı
-- half_days: Ödenen yarım gün sayısı
-- amount: Ödeme tutarı (TL)

CREATE TABLE payments (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  worker_id BIGINT REFERENCES workers(id) ON DELETE CASCADE,
  full_days INTEGER NOT NULL DEFAULT 0 CHECK (full_days >= 0),
  half_days INTEGER NOT NULL DEFAULT 0 CHECK (half_days >= 0),
  payment_date DATE NOT NULL,
  amount DECIMAL(10, 2) NOT NULL DEFAULT 0.0 CHECK (amount >= 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul'),
  -- Migration eklemeleri:
  updated_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul') NOT NULL
);

-- ============================================
-- 2.6 PAID_DAYS TABLE (Ödenen Günler)
-- ============================================
-- 📊 Hangi günlerin hangi ödemede kullanıldığını takip eder
-- İlişki: payments (N-1), attendance (referans)
-- Bir gün sadece bir kez ödenebilir

CREATE TABLE paid_days (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  worker_id BIGINT REFERENCES workers(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('fullDay', 'halfDay')),
  payment_id BIGINT REFERENCES payments(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul'),
  CONSTRAINT unique_paid_days_worker_date_status UNIQUE (worker_id, date, status)
);

-- ============================================
-- 2.7 NOTIFICATION_SETTINGS TABLE (Yönetici Bildirim Ayarları)
-- ============================================
-- ⚙️ Yöneticilerin bildirim tercihlerini saklar
-- time: Günlük hatırlatma saati
-- auto_approve_trusted: Güvenilir çalışanları otomatik onayla
-- attendance_requests_enabled: Yevmiye talep bildirimleri (FCM ile anında push notification)

CREATE TABLE notification_settings (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  time TIME NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  auto_approve_trusted BOOLEAN NOT NULL DEFAULT FALSE,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul'),
  UNIQUE(user_id),
  -- Migration eklemeleri:
  attendance_requests_enabled BOOLEAN NOT NULL DEFAULT TRUE
);

COMMENT ON COLUMN notification_settings.attendance_requests_enabled IS 
'Yöneticinin yeni yevmiye talepleri için bildirim alıp almayacağını kontrol eder. Aktif olduğunda FCM ile anında push notification gönderilir.';

-- ============================================
-- 2.8 NOTIFICATION_SETTINGS_WORKERS TABLE (Çalışan Bildirim Ayarları)
-- ============================================
-- ⚙️ Çalışanların bildirim tercihlerini saklar
-- time: Günlük yevmiye hatırlatma saati
-- NOT: Yönetici ayarlarından ayrı tablo (farklı mantık)

CREATE TABLE notification_settings_workers (
  id BIGSERIAL PRIMARY KEY,
  worker_id BIGINT NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  time TIME NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul'),
  UNIQUE(worker_id)
);

-- ============================================
-- 2.9 EMPLOYEE_REMINDERS TABLE (Çalışan Hatırlatıcıları)
-- ============================================
-- 🔔 Yöneticilerin çalışanlar için oluşturduğu hatırlatıcılar
-- reminder_date: Hatırlatma zamanı
-- is_completed: Tamamlandı mı?

CREATE TABLE employee_reminders (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  worker_id BIGINT NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  worker_name TEXT NOT NULL,
  reminder_date TIMESTAMP WITH TIME ZONE NOT NULL,
  message TEXT NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul')
);

-- ============================================
-- 2.10 NOTIFICATIONS TABLE (Genel Bildirimler)
-- ============================================
-- 🔔 Tüm sistem bildirimlerini saklar
-- sender_type: user, worker, system
-- recipient_type: user, worker
-- notification_type: attendance_reminder, attendance_request, payment_notification, vb.
-- FCM ile anında push notification gönderilir

CREATE TABLE notifications (
  id BIGSERIAL PRIMARY KEY,
  sender_id BIGINT,
  sender_type TEXT NOT NULL CHECK (sender_type IN ('user', 'worker', 'system')),
  recipient_id BIGINT NOT NULL,
  recipient_type TEXT NOT NULL CHECK (recipient_type IN ('user', 'worker')),
  notification_type TEXT NOT NULL CHECK (notification_type IN (
    'attendance_reminder',
    'attendance_request',
    'attendance_approved',
    'attendance_rejected',
    'payment_notification',
    'payment_received',
    'payment_updated',
    'payment_deleted',
    'general'
  )),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  related_id BIGINT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul')
);

-- ============================================
-- SECTION 3: MIGRATION TABLES (Yeni Tablolar)
-- ============================================
-- 📌 AÇIKLAMA: Sonradan eklenen özellikler için tablolar
-- Migration dosyalarından birleştirilmiştir

-- ============================================
-- 3.1 FCM_TOKENS TABLE (Firebase Cloud Messaging)
-- ============================================
-- 📱 Push notification için FCM token'larını saklar
-- Her kullanıcı/çalışan birden fazla cihaza sahip olabilir
-- is_active: Token geçerli mi? (eski token'lar deaktif edilir)

CREATE TABLE IF NOT EXISTS fcm_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  worker_id BIGINT REFERENCES workers(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  device_type TEXT NOT NULL CHECK (device_type IN ('android', 'ios')),
  device_info JSONB DEFAULT '{}'::jsonb,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT check_user_or_worker CHECK (
    (user_id IS NOT NULL AND worker_id IS NULL) OR
    (user_id IS NULL AND worker_id IS NOT NULL)
  )
);

COMMENT ON TABLE fcm_tokens IS 'Firebase Cloud Messaging token''larını saklar. Her kullanıcı/çalışan için birden fazla cihaz token''ı olabilir.';
COMMENT ON COLUMN fcm_tokens.token IS 'Firebase FCM token (unique)';
COMMENT ON COLUMN fcm_tokens.device_type IS 'Cihaz tipi: android veya ios';
COMMENT ON COLUMN fcm_tokens.device_info IS 'Cihaz bilgileri (model, OS version, app version, vb.)';
COMMENT ON COLUMN fcm_tokens.is_active IS 'Token aktif mi? Eski/geçersiz token''lar deaktif edilir.';
COMMENT ON COLUMN fcm_tokens.last_used_at IS 'Token''ın son kullanım zamanı (push notification gönderildiğinde güncellenir)';

-- ============================================
-- 3.2 ACTIVITY_LOGS TABLE (Admin Aktivite Logları)
-- ============================================
-- 📋 Admin kullanıcılarının yaptığı işlemleri loglar
-- action_type: user_created, user_updated, user_deleted, vb.
-- details: İşlem detayları (JSON formatında)
-- Güvenlik ve denetim için kullanılır

CREATE TABLE IF NOT EXISTS activity_logs (
    id BIGSERIAL PRIMARY KEY,
    admin_id BIGINT NOT NULL,
    admin_username TEXT NOT NULL,
    action_type TEXT NOT NULL,
    target_user_id BIGINT,
    target_username TEXT,
    details JSONB,
    ip_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

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
-- 3.3 PASSWORD_RESET_TOKENS TABLE (Şifre Sıfırlama)
-- ============================================
-- 🔑 Şifre sıfırlama token'larını saklar
-- user_type: user veya worker
-- expires_at: Token geçerlilik süresi (24 saat)
-- used: Token kullanıldı mı?

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_type TEXT NOT NULL CHECK (user_type IN ('user', 'worker')),
  user_id BIGINT NOT NULL,
  email TEXT NOT NULL,
  token TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul')
);

-- ============================================
-- 3.4 ADVANCES TABLE (Avanslar)
-- ============================================
-- 💰 Çalışanlara verilen avansları saklar
-- İlişkiler: users (N-1), workers (N-1), payments (N-1)
-- is_deducted: Avans ödemeden düşüldü mü?

CREATE TABLE IF NOT EXISTS advances (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  worker_id BIGINT NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
  advance_date DATE NOT NULL,
  description TEXT,
  is_deducted BOOLEAN NOT NULL DEFAULT FALSE,
  deducted_from_payment_id BIGINT REFERENCES payments(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul'),
  updated_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul')
);

COMMENT ON TABLE advances IS 'Çalışanlara verilen avansları saklar';
COMMENT ON COLUMN advances.user_id IS 'Avansı veren yönetici';
COMMENT ON COLUMN advances.worker_id IS 'Avansı alan çalışan';
COMMENT ON COLUMN advances.amount IS 'Avans tutarı (TL)';
COMMENT ON COLUMN advances.advance_date IS 'Avans verilme tarihi';
COMMENT ON COLUMN advances.description IS 'Avans açıklaması (opsiyonel)';
COMMENT ON COLUMN advances.is_deducted IS 'Avans ödemeden düşüldü mü?';
COMMENT ON COLUMN advances.deducted_from_payment_id IS 'Hangi ödemeden düşüldü (varsa)';

-- ============================================
-- 3.5 EXPENSES TABLE (Masraflar)
-- ============================================
-- 🏗️ İş masraflarını (malzeme, ulaşım vb.) saklar
-- İlişkiler: users (N-1)
-- category: malzeme, ulasim, ekipman, diger

CREATE TABLE IF NOT EXISTS expenses (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expense_type TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('malzeme', 'ulasim', 'ekipman', 'diger')),
  amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
  expense_date DATE NOT NULL,
  description TEXT,
  receipt_url TEXT,
  created_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul'),
  updated_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul')
);

COMMENT ON TABLE expenses IS 'İş masraflarını (malzeme, ulaşım vb.) saklar';
COMMENT ON COLUMN expenses.user_id IS 'Masrafı kaydeden yönetici';
COMMENT ON COLUMN expenses.expense_type IS 'Masraf türü (örn: 1 ton demir, nakliye)';
COMMENT ON COLUMN expenses.category IS 'Kategori: malzeme, ulasim, ekipman, diger';
COMMENT ON COLUMN expenses.amount IS 'Masraf tutarı (TL)';
COMMENT ON COLUMN expenses.expense_date IS 'Masraf tarihi';
COMMENT ON COLUMN expenses.description IS 'Masraf açıklaması (opsiyonel)';
COMMENT ON COLUMN expenses.receipt_url IS 'Fatura/fiş fotoğrafı URL (opsiyonel)';

-- ============================================
-- SECTION 4: INDEXES (Performans İçin)
-- ============================================
-- 📌 AÇIKLAMA: Veritabanı sorgularını hızlandıran indexler
-- Index'ler WHERE, JOIN, ORDER BY sorgularını optimize eder

-- ============================================
-- 4.1 USERS & WORKERS INDEXES
-- ============================================
-- 🔍 Kullanıcı ve çalışan aramalarını hızlandırır

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_admin ON users(is_admin);
CREATE INDEX IF NOT EXISTS idx_users_blocked ON users(is_blocked);

CREATE INDEX IF NOT EXISTS idx_workers_user_id ON workers(user_id);
CREATE INDEX IF NOT EXISTS idx_workers_username ON workers(username);
CREATE INDEX IF NOT EXISTS idx_workers_is_active ON workers(is_active);
CREATE INDEX IF NOT EXISTS idx_workers_email ON workers(email);

-- Kullanıcı bazlı çalışan sorguları için (composite index)
CREATE INDEX IF NOT EXISTS idx_workers_user_name 
ON workers(user_id, full_name);

-- Başlangıç tarihi sıralama için
CREATE INDEX IF NOT EXISTS idx_workers_start_date 
ON workers(start_date DESC);

-- ============================================
-- 4.2 ATTENDANCE INDEXES
-- ============================================
-- 📅 Yevmiye sorgularını hızlandırır
-- Partial index'ler: Sadece belirli koşullardaki kayıtları indexler (daha hızlı)

CREATE INDEX idx_attendance_worker_id ON attendance(worker_id);
CREATE INDEX idx_attendance_user_id ON attendance(user_id);
CREATE INDEX idx_attendance_date ON attendance(date);

CREATE INDEX IF NOT EXISTS idx_attendance_notification_sent 
ON attendance(notification_sent) 
WHERE notification_sent = FALSE;

CREATE INDEX IF NOT EXISTS idx_attendance_created_by_notification_sent 
ON attendance(created_by, notification_sent) 
WHERE created_by = 'worker';

CREATE INDEX IF NOT EXISTS idx_attendance_notification_lookup 
ON attendance(created_by, notification_sent, created_at DESC)
WHERE created_by = 'worker' AND notification_sent = false;

COMMENT ON INDEX idx_attendance_notification_lookup IS 
'Yevmiye talep bildirimleri için partial index. Worker tarafından oluşturulan ve henüz FCM ile bildirilmemiş talepleri hızlı sorgular.';

-- Çalışan ve tarih bazlı puantaj sorguları için (DESC order)
CREATE INDEX IF NOT EXISTS idx_attendance_worker_date_desc 
ON attendance(worker_id, date DESC);

-- Kullanıcı ve tarih bazlı sorgular için (DESC order)
CREATE INDEX IF NOT EXISTS idx_attendance_user_date_desc 
ON attendance(user_id, date DESC);

-- Tarih aralığı sorguları için (DESC order)
CREATE INDEX IF NOT EXISTS idx_attendance_date_desc 
ON attendance(date DESC);

-- Çalışan puantaj raporu için (composite index - en sık kullanılan)
CREATE INDEX IF NOT EXISTS idx_attendance_worker_user_date 
ON attendance(worker_id, user_id, date DESC);

-- Çalışan puantaj raporu için covering index (fullDay ve halfDay kayıtları)
CREATE INDEX IF NOT EXISTS idx_attendance_worker_report 
ON attendance(worker_id, date DESC, status, created_by, created_at)
WHERE status IN ('fullDay', 'halfDay');

-- ============================================
-- 4.3 ATTENDANCE_REQUESTS INDEXES
-- ============================================
-- 📝 Yevmiye talep sorgularını hızlandırır
-- Pending talepleri hızlı bulmak için optimize edilmiş

CREATE INDEX idx_attendance_requests_worker_id ON attendance_requests(worker_id);
CREATE INDEX idx_attendance_requests_user_id ON attendance_requests(user_id);
CREATE INDEX idx_attendance_requests_status ON attendance_requests(request_status);
CREATE INDEX idx_attendance_requests_date ON attendance_requests(date);

CREATE INDEX IF NOT EXISTS idx_attendance_requests_notification_sent 
ON attendance_requests(notification_sent);

CREATE INDEX IF NOT EXISTS idx_attendance_requests_status_notification 
ON attendance_requests(request_status, notification_sent) 
WHERE request_status = 'pending';

-- Tarih sıralama için (DESC order)
CREATE INDEX IF NOT EXISTS idx_attendance_requests_date_desc 
ON attendance_requests(date DESC);

-- ============================================
-- 4.4 PAYMENTS & PAID_DAYS INDEXES
-- ============================================
-- 💰 Ödeme sorgularını hızlandırır

CREATE INDEX idx_payments_worker_id ON payments(worker_id);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_date ON payments(payment_date);

CREATE INDEX idx_paid_days_payment_id ON paid_days(payment_id);
CREATE INDEX idx_paid_days_worker_id ON paid_days(worker_id);

-- Çalışan bazlı ödeme sorguları için (DESC order)
CREATE INDEX IF NOT EXISTS idx_payments_worker_date 
ON payments(worker_id, payment_date DESC);

-- Kullanıcı bazlı ödeme sorguları için (DESC order)
CREATE INDEX IF NOT EXISTS idx_payments_user_date 
ON payments(user_id, payment_date DESC);

-- Ödeme tarihi sıralama için (DESC order)
CREATE INDEX IF NOT EXISTS idx_payments_date_desc 
ON payments(payment_date DESC);

-- Ödeme raporu için (composite index)
CREATE INDEX IF NOT EXISTS idx_payments_worker_user_date 
ON payments(worker_id, user_id, payment_date DESC);

-- Ödeme raporu için covering index (tüm ödeme detayları)
CREATE INDEX IF NOT EXISTS idx_payments_worker_report 
ON payments(worker_id, payment_date DESC, full_days, half_days, amount);

-- ============================================
-- 4.5 NOTIFICATION SETTINGS INDEXES
-- ============================================

CREATE INDEX idx_notification_settings_workers_worker_id ON notification_settings_workers(worker_id);
CREATE INDEX idx_notification_settings_workers_enabled ON notification_settings_workers(enabled);

-- ============================================
-- 4.6 EMPLOYEE_REMINDERS INDEXES
-- ============================================

CREATE INDEX idx_employee_reminders_user_id ON employee_reminders(user_id);
CREATE INDEX idx_employee_reminders_worker_id ON employee_reminders(worker_id);
CREATE INDEX idx_employee_reminders_date ON employee_reminders(reminder_date);
CREATE INDEX idx_employee_reminders_completed ON employee_reminders(is_completed);

-- Hatırlatıcı tarihi ve kullanıcı bazlı sorgular için (composite index)
CREATE INDEX IF NOT EXISTS idx_employee_reminders_user_date 
ON employee_reminders(user_id, reminder_date);

-- Tamamlanma durumu için (composite index)
CREATE INDEX IF NOT EXISTS idx_employee_reminders_completed 
ON employee_reminders(is_completed);

-- Hatırlatıcı tarihi sıralama için (DESC order)
CREATE INDEX IF NOT EXISTS idx_employee_reminders_date_desc 
ON employee_reminders(reminder_date DESC);

-- Sadece tamamlanmamış hatırlatıcılar için (partial index)
CREATE INDEX IF NOT EXISTS idx_reminders_pending 
ON employee_reminders(user_id, reminder_date) 
WHERE is_completed = false;

-- ============================================
-- 4.7 NOTIFICATIONS INDEXES
-- ============================================

CREATE INDEX idx_notifications_recipient ON notifications(recipient_id, recipient_type);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_indexes 
        WHERE tablename = 'notifications' 
        AND indexname = 'idx_notifications_recipient_id'
    ) THEN
        CREATE INDEX idx_notifications_recipient_id ON notifications(recipient_id);
        RAISE NOTICE 'idx_notifications_recipient_id oluşturuldu';
    ELSE
        RAISE NOTICE 'idx_notifications_recipient_id zaten mevcut';
    END IF;

    IF NOT EXISTS (
        SELECT 1 
        FROM pg_indexes 
        WHERE tablename = 'notifications' 
        AND indexname = 'idx_notifications_recipient_created'
    ) THEN
        CREATE INDEX idx_notifications_recipient_created ON notifications(recipient_id, created_at DESC);
        RAISE NOTICE 'idx_notifications_recipient_created oluşturuldu';
    ELSE
        RAISE NOTICE 'idx_notifications_recipient_created zaten mevcut';
    END IF;

    IF NOT EXISTS (
        SELECT 1 
        FROM pg_indexes 
        WHERE tablename = 'notifications' 
        AND indexname = 'idx_notifications_recipient_type_id'
    ) THEN
        CREATE INDEX idx_notifications_recipient_type_id ON notifications(recipient_type, recipient_id);
        RAISE NOTICE 'idx_notifications_recipient_type_id oluşturuldu';
    ELSE
        RAISE NOTICE 'idx_notifications_recipient_type_id zaten mevcut';
    END IF;
END $$;

-- ============================================
-- 4.8 FCM_TOKENS INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_worker_id ON fcm_tokens(worker_id) WHERE worker_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_token ON fcm_tokens(token);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_is_active ON fcm_tokens(is_active) WHERE is_active = TRUE;

-- ============================================
-- 4.9 ACTIVITY_LOGS INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_activity_logs_admin_id ON activity_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_action_type ON activity_logs(action_type);
CREATE INDEX IF NOT EXISTS idx_activity_logs_target_user_id ON activity_logs(target_user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at DESC);

-- Admin kullanıcı bazlı loglar için (composite index)
CREATE INDEX IF NOT EXISTS idx_activity_logs_admin 
ON activity_logs(admin_id, created_at DESC);

-- ============================================
-- 4.10 PASSWORD_RESET_TOKENS INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_token ON password_reset_tokens(token);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_email ON password_reset_tokens(email);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_expires ON password_reset_tokens(expires_at);

-- ============================================
-- 4.11 ADVANCES INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_advances_user_id ON advances(user_id);
CREATE INDEX IF NOT EXISTS idx_advances_worker_id ON advances(worker_id);
CREATE INDEX IF NOT EXISTS idx_advances_date ON advances(advance_date);
CREATE INDEX IF NOT EXISTS idx_advances_is_deducted ON advances(is_deducted) WHERE is_deducted = FALSE;
CREATE INDEX IF NOT EXISTS idx_advances_worker_date ON advances(worker_id, advance_date);

COMMENT ON INDEX idx_advances_is_deducted IS 'Düşülmemiş avansları hızlı bulmak için partial index';

-- Çalışan bazlı avans sorguları için (DESC order)
CREATE INDEX IF NOT EXISTS idx_advances_worker_date_desc 
ON advances(worker_id, advance_date DESC);

-- Kullanıcı bazlı avans sorguları için (DESC order)
CREATE INDEX IF NOT EXISTS idx_advances_user_date_desc 
ON advances(user_id, advance_date DESC);

-- Avans tarihi sıralama için (DESC order)
CREATE INDEX IF NOT EXISTS idx_advances_date_desc 
ON advances(advance_date DESC);

-- Avans raporu için (composite index)
CREATE INDEX IF NOT EXISTS idx_advances_worker_user_date 
ON advances(worker_id, user_id, advance_date DESC);

-- Düşülmemiş avanslar için covering index (partial index)
CREATE INDEX IF NOT EXISTS idx_advances_pending_report 
ON advances(worker_id, advance_date DESC, amount, description)
WHERE is_deducted = FALSE;

-- ============================================
-- 4.12 EXPENSES INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON expenses(user_id, expense_date);

-- Kullanıcı ve tarih bazlı masraf sorguları için (DESC order)
CREATE INDEX IF NOT EXISTS idx_expenses_user_date_desc 
ON expenses(user_id, expense_date DESC);

-- Kategori bazlı sorgular için (DESC order)
CREATE INDEX IF NOT EXISTS idx_expenses_category_date 
ON expenses(category, expense_date DESC);

-- Masraf tarihi sıralama için (DESC order)
CREATE INDEX IF NOT EXISTS idx_expenses_date_desc 
ON expenses(expense_date DESC);

-- Kullanıcı bazlı tarih aralığı sorguları için optimize edilmiş index (EXTRACT yerine BETWEEN)
CREATE INDEX IF NOT EXISTS idx_expenses_user_date_range 
ON expenses(user_id, expense_date DESC, category, amount);

-- ============================================
-- 4.13 ANALYZE TABLES
-- ============================================
-- 📊 Tablo istatistiklerini günceller (query planner için)

ANALYZE users;
ANALYZE workers;
ANALYZE attendance;
ANALYZE attendance_requests;
ANALYZE payments;
ANALYZE paid_days;
ANALYZE notifications;
ANALYZE employee_reminders;
ANALYZE activity_logs;
ANALYZE advances;
ANALYZE expenses;
ANALYZE fcm_tokens;

-- ============================================
-- 4.14 EK PERFORMANS İNDEKSLERİ
-- ============================================
-- 🚀 Sık kullanılan sorgular için özel indeksler
-- NOT: Bu bölümdeki indeksler 4.1-4.13'te OLMAYAN yeni indekslerdir

-- ============================================
-- 4.14.1 NOTIFICATIONS - Okunmamış Bildirimler (YENİ)
-- ============================================
-- ⚡ EN SIK KULLANILAN: WHERE recipient_id = ? AND recipient_type = ? AND is_read = FALSE
CREATE INDEX IF NOT EXISTS idx_notifications_unread_lookup 
ON notifications(recipient_id, recipient_type, is_read, created_at DESC)
WHERE is_read = FALSE;

COMMENT ON INDEX idx_notifications_unread_lookup IS 
'Okunmamış bildirimleri hızlı getirmek için partial composite index. Worker ve User dashboard''larında kullanılır.';

-- Bildirim tipi bazlı sorgular için (YENİ)
CREATE INDEX IF NOT EXISTS idx_notifications_type_recipient 
ON notifications(notification_type, recipient_id, created_at DESC);

COMMENT ON INDEX idx_notifications_type_recipient IS 
'Bildirim tipine göre filtreleme için (attendance_request, payment_notification, vb.)';

-- Related_id ile bildirim bulma (onay/red işlemleri için) (YENİ)
CREATE INDEX IF NOT EXISTS idx_notifications_related_id 
ON notifications(related_id, notification_type)
WHERE related_id IS NOT NULL;

COMMENT ON INDEX idx_notifications_related_id IS 
'Yevmiye talebi onay/red işlemlerinde orijinal bildirimi bulmak için kullanılır.';

-- ============================================
-- 4.14.2 ATTENDANCE_REQUESTS - Pending Talepler (YENİ)
-- ============================================
-- ⚡ EN SIK KULLANILAN: WHERE worker_id = ? AND date = ?
CREATE INDEX IF NOT EXISTS idx_attendance_requests_worker_date_unique 
ON attendance_requests(worker_id, date, request_status);

COMMENT ON INDEX idx_attendance_requests_worker_date_unique IS 
'Çalışanın belirli bir tarihteki talep durumunu hızlı kontrol eder.';

-- Yönetici için bekleyen talepler (YENİ)
CREATE INDEX IF NOT EXISTS idx_attendance_requests_user_pending 
ON attendance_requests(user_id, request_status, requested_at DESC)
WHERE request_status = 'pending';

COMMENT ON INDEX idx_attendance_requests_user_pending IS 
'Yöneticinin bekleyen taleplerini hızlı listelemek için partial index.';

-- Çalışan için talep geçmişi (YENİ)
CREATE INDEX IF NOT EXISTS idx_attendance_requests_worker_reviewed 
ON attendance_requests(worker_id, reviewed_at DESC)
WHERE reviewed_at IS NOT NULL;

COMMENT ON INDEX idx_attendance_requests_worker_reviewed IS 
'Çalışanın onaylanmış/reddedilmiş talep geçmişi için.';

-- ============================================
-- 4.14.3 PAID_DAYS - Ödeme Kontrolü (YENİ)
-- ============================================
-- ⚡ EN SIK KULLANILAN: WHERE worker_id = ? AND date = ? AND status = ?
CREATE INDEX IF NOT EXISTS idx_paid_days_worker_date_status 
ON paid_days(worker_id, date, status);

COMMENT ON INDEX idx_paid_days_worker_date_status IS 
'Belirli bir günün ödenip ödenmediğini kontrol etmek için composite index.';

-- Ödeme silme/güncelleme için (YENİ)
CREATE INDEX IF NOT EXISTS idx_paid_days_payment_worker 
ON paid_days(payment_id, worker_id, date);

COMMENT ON INDEX idx_paid_days_payment_worker IS 
'Ödeme silme ve güncelleme işlemlerinde kullanılır.';

-- Ödenmemiş günleri bulmak için (YENİ)
CREATE INDEX IF NOT EXISTS idx_paid_days_worker_date_lookup 
ON paid_days(worker_id, date);

COMMENT ON INDEX idx_paid_days_worker_date_lookup IS 
'Çalışanın hangi günlerinin ödendiğini hızlı kontrol eder.';

-- ============================================
-- 4.14.4 FCM_TOKENS - Token Yönetimi (YENİ)
-- ============================================

-- Aktif token'ları user/worker bazlı getirmek için (YENİ)
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_active 
ON fcm_tokens(user_id, is_active, last_used_at DESC)
WHERE user_id IS NOT NULL AND is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_fcm_tokens_worker_active 
ON fcm_tokens(worker_id, is_active, last_used_at DESC)
WHERE worker_id IS NOT NULL AND is_active = TRUE;

COMMENT ON INDEX idx_fcm_tokens_user_active IS 
'Kullanıcının aktif FCM token''larını push notification için hızlı getirir.';

COMMENT ON INDEX idx_fcm_tokens_worker_active IS 
'Çalışanın aktif FCM token''larını push notification için hızlı getirir.';

-- Eski token temizleme için (YENİ)
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_cleanup 
ON fcm_tokens(is_active, updated_at)
WHERE is_active = FALSE;

COMMENT ON INDEX idx_fcm_tokens_cleanup IS 
'Eski deaktif token''ları temizlemek için (cleanup_inactive_fcm_tokens fonksiyonu).';

-- ============================================
-- 4.14.5 NOTIFICATION_SETTINGS - Ayar Kontrolü (YENİ)
-- ============================================

-- Aktif bildirim ayarları için (YENİ)
CREATE INDEX IF NOT EXISTS idx_notification_settings_enabled 
ON notification_settings(enabled, time)
WHERE enabled = TRUE;

COMMENT ON INDEX idx_notification_settings_enabled IS 
'Aktif bildirim ayarlarını zamanlamak için (cron job veya scheduler).';

-- ============================================
-- 4.14.6 NOTIFICATION_SETTINGS_WORKERS - Çalışan Ayarları (YENİ)
-- ============================================

-- Aktif çalışan bildirim ayarları için (YENİ)
CREATE INDEX IF NOT EXISTS idx_notification_settings_workers_enabled_time 
ON notification_settings_workers(enabled, time)
WHERE enabled = TRUE;

COMMENT ON INDEX idx_notification_settings_workers_enabled_time IS 
'Aktif çalışan bildirim ayarlarını zamanlamak için.';

-- ============================================
-- 4.14.7 WORKERS - Aktif Çalışanlar (YENİ)
-- ============================================

-- ⚡ EN SIK KULLANILAN: WHERE user_id = ? AND is_active = TRUE (YENİ)
CREATE INDEX IF NOT EXISTS idx_workers_user_active 
ON workers(user_id, is_active, full_name)
WHERE is_active = TRUE;

COMMENT ON INDEX idx_workers_user_active IS 
'Yöneticinin aktif çalışanlarını hızlı listelemek için partial index.';

-- Username ve email kontrolü için (case-insensitive) (YENİ)
CREATE INDEX IF NOT EXISTS idx_workers_username_lower 
ON workers(LOWER(username));

CREATE INDEX IF NOT EXISTS idx_workers_email_lower 
ON workers(LOWER(email))
WHERE email IS NOT NULL;

COMMENT ON INDEX idx_workers_username_lower IS 
'Case-insensitive username araması için.';

COMMENT ON INDEX idx_workers_email_lower IS 
'Case-insensitive email araması için.';

-- ============================================
-- 4.14.8 USERS - Kullanıcı Araması (YENİ)
-- ============================================

-- Username ve email kontrolü için (case-insensitive) (YENİ)
CREATE INDEX IF NOT EXISTS idx_users_username_lower 
ON users(LOWER(username));

CREATE INDEX IF NOT EXISTS idx_users_email_lower 
ON users(LOWER(email))
WHERE email IS NOT NULL;

COMMENT ON INDEX idx_users_username_lower IS 
'Case-insensitive username araması için.';

COMMENT ON INDEX idx_users_email_lower IS 
'Case-insensitive email araması için.';

-- Aktif yöneticiler için (YENİ)
CREATE INDEX IF NOT EXISTS idx_users_active 
ON users(is_blocked, is_admin)
WHERE is_blocked = FALSE;

COMMENT ON INDEX idx_users_active IS 
'Bloklanmamış kullanıcıları hızlı filtrelemek için.';

-- ============================================
-- 4.14.9 PASSWORD_RESET_TOKENS - Token Kontrolü (YENİ)
-- ============================================

-- ⚡ EN SIK KULLANILAN: WHERE token = ? AND expires_at > NOW() AND used = FALSE (YENİ)
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_valid 
ON password_reset_tokens(token, expires_at, used)
WHERE used = FALSE;

COMMENT ON INDEX idx_password_reset_tokens_valid IS 
'Geçerli şifre sıfırlama token''larını hızlı kontrol eder.';

-- Email ile token arama (YENİ)
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_email_valid 
ON password_reset_tokens(email, user_type, expires_at)
WHERE used = FALSE;

COMMENT ON INDEX idx_password_reset_tokens_email_valid IS 
'Email ile geçerli token''ları bulmak için.';

-- ============================================
-- 4.14.10 ADVANCES - Düşülmemiş Avanslar (YENİ)
-- ============================================

-- Ödeme ile ilişkilendirme için (YENİ)
CREATE INDEX IF NOT EXISTS idx_advances_deducted_payment 
ON advances(deducted_from_payment_id, worker_id)
WHERE deducted_from_payment_id IS NOT NULL;

COMMENT ON INDEX idx_advances_deducted_payment IS 
'Hangi ödemeden avans düşüldüğünü bulmak için.';

-- ============================================
-- 4.14.11 EXPENSES - Kategori Raporları (YENİ)
-- ============================================

-- Aylık masraf raporu için (YENİ)
CREATE INDEX IF NOT EXISTS idx_expenses_user_month 
ON expenses(user_id, EXTRACT(YEAR FROM expense_date), EXTRACT(MONTH FROM expense_date), amount);

COMMENT ON INDEX idx_expenses_user_month IS 
'Aylık masraf raporları için optimize edilmiş index.';

-- ============================================
-- 4.14.12 ACTIVITY_LOGS - Admin Denetimi (YENİ)
-- ============================================

-- Action type bazlı filtreleme (YENİ)
CREATE INDEX IF NOT EXISTS idx_activity_logs_action_created 
ON activity_logs(action_type, created_at DESC);

COMMENT ON INDEX idx_activity_logs_action_created IS 
'Belirli işlem tiplerini tarih sırasıyla listelemek için.';

-- Target user bazlı sorgular (YENİ)
CREATE INDEX IF NOT EXISTS idx_activity_logs_target_created 
ON activity_logs(target_user_id, created_at DESC)
WHERE target_user_id IS NOT NULL;

COMMENT ON INDEX idx_activity_logs_target_created IS 
'Belirli bir kullanıcı üzerinde yapılan işlemleri görmek için.';

-- ============================================
-- 4.14.13 EMPLOYEE_REMINDERS - Yaklaşan Hatırlatmalar (YENİ)
-- ============================================

-- Bugünün hatırlatmaları için (YENİ)
CREATE INDEX IF NOT EXISTS idx_employee_reminders_today 
ON employee_reminders(user_id, reminder_date, is_completed)
WHERE is_completed = FALSE;

COMMENT ON INDEX idx_employee_reminders_today IS 
'Bugünün tamamlanmamış hatırlatmalarını hızlı getirmek için.';

-- Worker bazlı hatırlatmalar (YENİ)
CREATE INDEX IF NOT EXISTS idx_employee_reminders_worker_pending 
ON employee_reminders(worker_id, reminder_date DESC)
WHERE is_completed = FALSE;

COMMENT ON INDEX idx_employee_reminders_worker_pending IS 
'Çalışan bazlı bekleyen hatırlatmaları listelemek için.';

-- ============================================
-- 4.14.14 ANALYZE - Yeni İndeksler
-- ============================================
-- 📊 Yeni eklenen indeksler için istatistik güncelleme

ANALYZE notifications;
ANALYZE attendance_requests;
ANALYZE paid_days;
ANALYZE fcm_tokens;
ANALYZE notification_settings;
ANALYZE notification_settings_workers;
ANALYZE workers;
ANALYZE users;
ANALYZE password_reset_tokens;
ANALYZE advances;
ANALYZE expenses;
ANALYZE activity_logs;
ANALYZE employee_reminders;

-- ============================================
-- 4.14.15 INDEX VERIFICATION QUERIES
-- ============================================
-- 🔍 İndekslerin durumunu kontrol etmek için kullanılabilir

-- Tüm indeksleri görmek için:
-- SELECT schemaname, tablename, indexname, indexdef 
-- FROM pg_indexes 
-- WHERE schemaname = 'public' 
-- ORDER BY tablename, indexname;

-- İndeks kullanım istatistiklerini görmek için:
-- SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
-- FROM pg_stat_user_indexes
-- WHERE schemaname = 'public'
-- ORDER BY idx_scan DESC;

-- Kullanılmayan indeksleri bulmak için:
-- SELECT schemaname, tablename, indexname, idx_scan
-- FROM pg_stat_user_indexes
-- WHERE schemaname = 'public' AND idx_scan = 0
-- ORDER BY tablename, indexname;

-- İndeks boyutlarını görmek için:
-- SELECT schemaname, tablename, indexname, 
--        pg_size_pretty(pg_relation_size(indexrelid)) as index_size
-- FROM pg_stat_user_indexes
-- WHERE schemaname = 'public'
-- ORDER BY pg_relation_size(indexrelid) DESC;

-- Yeni eklenen indeksleri kontrol etmek için:
-- SELECT indexname FROM pg_indexes 
-- WHERE schemaname = 'public' 
-- AND indexname IN (
--   'idx_notifications_unread_lookup', 'idx_notifications_type_recipient', 'idx_notifications_related_id',
--   'idx_attendance_requests_worker_date_unique', 'idx_attendance_requests_user_pending', 'idx_attendance_requests_worker_reviewed',
--   'idx_paid_days_worker_date_status', 'idx_paid_days_payment_worker', 'idx_paid_days_worker_date_lookup',
--   'idx_fcm_tokens_user_active', 'idx_fcm_tokens_worker_active', 'idx_fcm_tokens_cleanup',
--   'idx_notification_settings_enabled', 'idx_notification_settings_workers_enabled_time',
--   'idx_workers_user_active', 'idx_workers_username_lower', 'idx_workers_email_lower',
--   'idx_users_username_lower', 'idx_users_email_lower', 'idx_users_active',
--   'idx_password_reset_tokens_valid', 'idx_password_reset_tokens_email_valid',
--   'idx_advances_deducted_payment', 'idx_expenses_user_month',
--   'idx_activity_logs_action_created', 'idx_activity_logs_target_created',
--   'idx_employee_reminders_today', 'idx_employee_reminders_worker_pending'
-- );


-- ============================================
-- SECTION 5: FUNCTIONS (Fonksiyonlar)
-- ============================================
-- 📌 AÇIKLAMA: İş mantığını içeren veritabanı fonksiyonları
-- Karmaşık işlemleri tek seferde yapar, kod tekrarını önler

-- ============================================
-- 5.1 UTILITY FUNCTIONS (Yardımcı Fonksiyonlar)
-- ============================================
-- 🔧 Genel amaçlı yardımcı fonksiyonlar

-- Sahipsiz ödemeleri bulan fonksiyon
-- 💡 Hiçbir paid_days kaydı olmayan payment'ları bulur
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
-- 💡 Her payment için kaç tam/yarım gün ödendiğini hesaplar
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
-- 💡 Dinamik SQL ile herhangi bir tablodaki kayıt sayısını bulur
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
-- 💡 JSON formatında birden fazla koşul ile kayıt sayar
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

-- ============================================
-- 5.2 WORKER STATS FUNCTIONS (Çalışan İstatistikleri)
-- ============================================
-- 📊 Çalışan istatistiklerini hesaplayan fonksiyonlar

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
  days_in_period := month_end - month_start + 1;
  
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT CASE WHEN a.status = 'fullDay' THEN a.date END) as total_full_days,
    COUNT(DISTINCT CASE WHEN a.status = 'halfDay' THEN a.date END) as total_half_days,
    (days_in_period - COUNT(DISTINCT CASE WHEN a.status IN ('fullDay', 'halfDay') THEN a.date END))::BIGINT as total_absent_days,
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

-- Çalışan için toplam ödeme miktarını hesaplayan fonksiyon
-- 💡 Bir çalışana yapılan tüm ödemelerin toplamını döndürür
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
-- 💡 Belirli tarih aralığındaki yevmiye geçmişini listeler
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

-- ============================================
-- 5.3 WORKER STATUS FUNCTIONS (Çalışan Durum Kontrolleri)
-- ============================================
-- ✅ Çalışanların yevmiye durumlarını kontrol eden fonksiyonlar

-- Yevmiye girişi yapmamış çalışanları bulan fonksiyon
-- 💡 Belirli bir tarihte yevmiye yapmayan aktif çalışanları listeler
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

-- Çalışan için bugünün yevmiye durumunu kontrol eden fonksiyon
-- 💡 Çalışan yevmiye girebilir mi? Kontrol eder
-- Durumlar: manager_entered, pending, approved, rejected, none
CREATE OR REPLACE FUNCTION check_worker_today_attendance_status(worker_id_param BIGINT, check_date DATE)
RETURNS TABLE (
  can_submit BOOLEAN,
  status_type TEXT,
  status_value TEXT,
  message TEXT
) AS $$
DECLARE
  attendance_exists BOOLEAN;
  request_exists BOOLEAN;
  request_status TEXT;
  request_value TEXT;
  attendance_value TEXT;
BEGIN
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
  
  RETURN QUERY SELECT 
    TRUE as can_submit,
    'none'::TEXT as status_type,
    NULL::TEXT as status_value,
    'Bugün için yevmiye girişi yapabilirsiniz.' as message;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5.4 PASSWORD FUNCTIONS (Şifre İşlemleri)
-- ============================================
-- 🔐 Şifre değiştirme fonksiyonları
-- NOT: Eski şifre kontrolü hash karşılaştırması ile yapılır

-- Çalışan şifre değiştirme fonksiyonu
-- 💡 Eski şifre doğruysa yeni şifreyi günceller
CREATE OR REPLACE FUNCTION change_worker_password(worker_id_param BIGINT, old_password_hash TEXT, new_password_hash TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  current_password TEXT;
BEGIN
  SELECT password_hash INTO current_password
  FROM workers
  WHERE id = worker_id_param;
  
  IF current_password = old_password_hash THEN
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
-- 💡 Yönetici/admin şifre değiştirme (eski şifre kontrolü ile)
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

-- ============================================
-- 5.5 PASSWORD RESET FUNCTIONS (Şifre Sıfırlama - Migration)
-- ============================================
-- 🔑 Email ile şifre sıfırlama fonksiyonları
-- Token tabanlı güvenli şifre sıfırlama sistemi

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
  DELETE FROM password_reset_tokens
  WHERE user_type = p_user_type 
    AND user_id = p_user_id 
    AND used = FALSE;
  
  INSERT INTO password_reset_tokens (user_type, user_id, email, token, expires_at)
  VALUES (p_user_type, p_user_id, p_email, p_token, CURRENT_TIMESTAMP + INTERVAL '24 hours')
  RETURNING id INTO token_id;
  
  RETURN token_id;
END;
$$ LANGUAGE plpgsql;

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
$$ LANGUAGE plpgsql;

-- ============================================
-- 5.6 EMAIL UNIQUE CHECK FUNCTION (Migration)
-- ============================================
-- 📧 Email benzersizlik kontrolü (trigger fonksiyonu)
-- users ve workers tablolarında email çakışmasını önler

CREATE OR REPLACE FUNCTION check_email_unique()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

-- ============================================
-- 5.7 NOTIFICATION FUNCTIONS (Bildirim Fonksiyonları)
-- ============================================
-- 🔔 Bildirim gönderme fonksiyonları

-- Yevmiye yapmamış çalışanlara toplu bildirim gönderen fonksiyon
-- 💡 Belirli bir tarihte yevmiye yapmayan çalışanlara hatırlatma gönderir
CREATE OR REPLACE FUNCTION send_attendance_reminder_to_workers(user_id_param BIGINT, check_date DATE)
RETURNS INTEGER AS $$
DECLARE
  worker_record RECORD;
  notification_count INTEGER := 0;
BEGIN
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

-- Manager bilgisi getiren fonksiyon (Migration)
-- 💡 Bildirimler için yönetici bilgilerini döndürür
CREATE OR REPLACE FUNCTION get_manager_info_for_notification(user_id_param INT)
RETURNS TABLE (
  user_id INT,
  username TEXT,
  first_name TEXT,
  last_name TEXT,
  full_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.username,
    u.first_name,
    u.last_name,
    CONCAT(u.first_name, ' ', u.last_name) as full_name
  FROM users u
  WHERE u.id = user_id_param;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5.8 FCM FUNCTIONS (Firebase Cloud Messaging - Migration)
-- ============================================
-- 📱 Push notification fonksiyonları
-- FCM token yönetimi ve bildirim gönderme

CREATE OR REPLACE FUNCTION update_fcm_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FCM token temizleme fonksiyonu
-- 💡 Eski ve kullanılmayan token'ları temizler (performans için)
-- 🔄 Cron job ile haftalık çalıştırılabilir
CREATE OR REPLACE FUNCTION cleanup_inactive_fcm_tokens()
RETURNS void AS $$
DECLARE
  deleted_count INTEGER;
  deactivated_count INTEGER;
BEGIN
  -- 90 günden eski deaktif token'ları sil
  DELETE FROM fcm_tokens
  WHERE is_active = FALSE
    AND updated_at < NOW() - INTERVAL '90 days';
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  -- 180 günden beri kullanılmayan token'ları deaktif et
  UPDATE fcm_tokens
  SET is_active = FALSE
  WHERE last_used_at < NOW() - INTERVAL '180 days'
    AND is_active = TRUE;
  
  GET DIAGNOSTICS deactivated_count = ROW_COUNT;
  
  RAISE NOTICE '🗑️ % adet eski token silindi', deleted_count;
  RAISE NOTICE '⏸️ % adet token deaktif edildi', deactivated_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FCM Push Notification Fonksiyonu
-- ============================================
-- 📱 Yeni bildirim eklendiğinde otomatik olarak FCM Edge Function'ını çağırır
-- ⚠️ NOT: URL ve Authorization token projenize özel olmalıdır
-- 🔧 Supabase Dashboard > Edge Functions > send-push-notification

CREATE OR REPLACE FUNCTION notify_via_fcm()
RETURNS TRIGGER AS $$
DECLARE
  request_id bigint;
  service_role_key TEXT;
BEGIN
  BEGIN
    -- Service role key'i Supabase'den al
    service_role_key := current_setting('app.settings.service_role_key', true);
    
    -- Eger setting yoksa hardcoded kullan (gecici)
    IF service_role_key IS NULL THEN
      service_role_key := 'YOUR_SUPABASE_SERVICE_ROLE_KEY_HERE';
    END IF;
    
    SELECT net.http_post(
      url := 'https://uvdcefauzxordqgvvweq.supabase.co/functions/v1/send-push-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || service_role_key
      ),
      body := jsonb_build_object(
        'recipientId', NEW.recipient_id,
        'title', NEW.title,
        'message', NEW.message,
        'notificationType', NEW.notification_type,
        'relatedId', NEW.related_id
      )
    ) INTO request_id;

    RAISE LOG 'FCM notification request sent: %', request_id;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'FCM notification failed: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION notify_via_fcm() IS 'Yeni bildirim eklendiğinde FCM Edge Function çağırır ve anında push notification gönderir';

-- ============================================
-- pg_net Extension Kontrolü
-- ============================================
-- 📌 FCM bildirimleri için pg_net extension gereklidir
-- Supabase'de varsayılan olarak yüklüdür
-- Eğer yüklü değilse: CREATE EXTENSION pg_net;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') THEN
    RAISE WARNING '⚠️ pg_net extension yüklü değil! FCM bildirimleri çalışmayacak.';
    RAISE WARNING '📦 Yüklemek için: CREATE EXTENSION pg_net;';
    RAISE WARNING '🔧 Supabase''de varsayılan olarak yüklüdür, manuel kurulum gerekmez.';
  ELSE
    RAISE NOTICE '✅ pg_net extension yüklü - FCM bildirimleri aktif';
  END IF;
END $$;

-- ============================================
-- Akıllı Bildirim Temizleme Fonksiyonu
-- ============================================
-- 💡 Akıllı bildirim temizleme sistemi
-- 🔄 pg_cron ile otomatik her saat başı çalıştırılır
-- ✅ Türkiye saati (UTC+3) ile doğru hesaplama yapar
--
-- KURALLAR:
-- 1. Okunmuş + bildirimin geldiği saatten 24 saat sonra → SİL
-- 2. Okunmamış → KALSIN (okunana kadar)
-- 3. Okundu + bildirimin geldiği saatten 24 saat geçmişse → HEMEN SİL (trigger ile)
-- 4. Okunmamış + bildirimin geldiği saatten 7 gün geçmişse → SİL

CREATE OR REPLACE FUNCTION smart_cleanup_notifications()
RETURNS void AS $$
DECLARE
  deleted_read_count INTEGER;
  deleted_old_unread_count INTEGER;
  now_turkey TIMESTAMP WITH TIME ZONE;
  twentyfour_hours_ago TIMESTAMP WITH TIME ZONE;
  seven_days_ago TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Şu anki zaman (Türkiye saati)
  now_turkey := NOW() AT TIME ZONE 'Europe/Istanbul';
  
  -- 24 saat önce
  twentyfour_hours_ago := now_turkey - INTERVAL '24 hours';
  
  -- 7 gün önce
  seven_days_ago := now_turkey - INTERVAL '7 days';
  
  RAISE NOTICE '🧹 Akıllı bildirim temizleme başlatıldı';
  RAISE NOTICE '⏰ Şu an (Türkiye): %', now_turkey;
  RAISE NOTICE '📅 24 saat önce: %', twentyfour_hours_ago;
  RAISE NOTICE '📅 7 gün önce: %', seven_days_ago;
  
  -- KURAL 1: Okunmuş + bildirimin geldiği saatten 24 saat geçmiş bildirimleri sil
  DELETE FROM notifications
  WHERE is_read = TRUE
    AND created_at < twentyfour_hours_ago;
  
  GET DIAGNOSTICS deleted_read_count = ROW_COUNT;
  
  -- KURAL 4: Okunmamış + bildirimin geldiği saatten 7 gün geçmiş bildirimleri sil
  DELETE FROM notifications
  WHERE is_read = FALSE
    AND created_at < seven_days_ago;
  
  GET DIAGNOSTICS deleted_old_unread_count = ROW_COUNT;
  
  RAISE NOTICE '✅ % adet okunmuş 24 saat eski bildirim silindi', deleted_read_count;
  RAISE NOTICE '✅ % adet 7 gün eski okunmamış bildirim silindi', deleted_old_unread_count;
  RAISE NOTICE '📊 Kalan bildirim sayısı: %', (SELECT COUNT(*) FROM notifications);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION smart_cleanup_notifications() IS 
'Akıllı bildirim temizleme: Okunmuş bildirimleri 24 saat sonra, okunmamış bildirimleri 7 gün sonra siler. Bildirimin geldiği saatten itibaren hesaplanır.';

-- ============================================
-- Okunduğunda Anında Temizleme Trigger Fonksiyonu
-- ============================================
-- KURAL 3: Bildirim okunduğunda, bildirimin geldiği saatten 24 saat geçmişse hemen sil

CREATE OR REPLACE FUNCTION cleanup_on_notification_read()
RETURNS TRIGGER AS $$
DECLARE
  now_turkey TIMESTAMP WITH TIME ZONE;
  notification_age INTERVAL;
BEGIN
  -- Sadece is_read FALSE'dan TRUE'ya değiştiğinde çalış
  IF NEW.is_read = TRUE AND OLD.is_read = FALSE THEN
    -- Şu anki zaman (Türkiye saati)
    now_turkey := NOW() AT TIME ZONE 'Europe/Istanbul';
    
    -- Bildirimin yaşı
    notification_age := now_turkey - NEW.created_at;
    
    -- Eğer bildirim 24 saatten eski ise, hemen sil
    IF notification_age >= INTERVAL '24 hours' THEN
      RAISE LOG '🗑️ Bildirim okundu ve 24 saat geçmiş, siliniyor: ID=%, Yaş=%, Tarih=%', NEW.id, notification_age, NEW.created_at;
      
      -- Bildirimi sil
      DELETE FROM notifications WHERE id = NEW.id;
      
      -- NULL döndürerek UPDATE işlemini iptal et (zaten silindi)
      RETURN NULL;
    END IF;
  END IF;
  
  -- Normal UPDATE devam etsin
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_on_notification_read() IS 
'Bildirim okunduğunda, bildirimin geldiği saatten 24 saat geçmişse hemen siler. 24 saat geçmemişse kalır.';


-- Eski activity log'ları temizleyen fonksiyon
-- 💡 10 günden eski activity log'ları siler (performans ve depolama için)
-- 🔄 Cron job ile haftalık veya aylık çalıştırılabilir
-- ⚠️ Denetim gereksinimleri varsa süreyi uzatın (örn: 1 yıl, 2 yıl)
CREATE OR REPLACE FUNCTION cleanup_old_activity_logs()
RETURNS void AS $$
DECLARE
  deleted_count INTEGER;
  retention_days INTEGER := 10; -- 10 gün saklama süresi (değiştirilebilir)
  cutoff_date TIMESTAMP WITH TIME ZONE;
BEGIN
  cutoff_date := NOW() - (retention_days || ' days')::INTERVAL;
  
  RAISE NOTICE '🧹 Activity log temizleme başlatıldı';
  RAISE NOTICE '⏰ Şu an: %', NOW();
  RAISE NOTICE '📅 Silme tarihi: % günden eski (% öncesi)', retention_days, cutoff_date;
  
  DELETE FROM activity_logs
  WHERE created_at < cutoff_date;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RAISE NOTICE '✅ % adet eski activity log silindi', deleted_count;
  RAISE NOTICE '📊 Kalan log sayısı: %', (SELECT COUNT(*) FROM activity_logs);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_old_activity_logs() IS 'Eski activity log kayıtlarını temizler. Varsayılan: 10 gün. Denetim gereksinimleri için süre uzatılabilir.';

-- ============================================
-- 5.12 AUTOMATIC CLEANUP SYSTEM (Otomatik Temizleme Sistemi)
-- ============================================
-- 🔄 pg_cron ile otomatik temizleme işlemleri
-- Her gece belirli saatlerde eski kayıtları temizler

-- ============================================
-- pg_cron Extension Kontrolü
-- ============================================
-- 📌 Otomatik temizleme için pg_cron extension gereklidir
-- Supabase Dashboard > Database > Extensions > pg_cron (enable)

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    RAISE WARNING '⚠️ pg_cron extension yüklü değil!';
    RAISE WARNING '📦 Supabase Dashboard > Database > Extensions > pg_cron (enable)';
    RAISE WARNING '🔧 Extension aktif edilene kadar otomatik temizleme çalışmayacak.';
  ELSE
    RAISE NOTICE '✅ pg_cron extension yüklü - Otomatik temizleme aktif';
  END IF;
END $$;

-- ============================================
-- Cron Job 1: Akıllı Bildirim Temizleme
-- ============================================
-- Her saat başı çalışır (bildirimin geldiği saatten 24 saat sonra silmek için)

-- Mevcut job'ı sil (varsa)
SELECT cron.unschedule('cleanup-old-notifications') 
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'cleanup-old-notifications'
);

-- Yeni cron job ekle - Her saat başı
SELECT cron.schedule(
  'cleanup-old-notifications',
  '0 * * * *', -- Her saat başı (00:00, 01:00, 02:00, ...)
  $$SELECT smart_cleanup_notifications()$$
);

-- ============================================
-- Cron Job 2: FCM Token Temizleme
-- ============================================
-- Her Pazar saat 03:00 (Türkiye saati) = 00:00 UTC

-- Mevcut job'ı sil (varsa)
SELECT cron.unschedule('cleanup-inactive-fcm-tokens') 
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'cleanup-inactive-fcm-tokens'
);

-- Yeni cron job ekle
SELECT cron.schedule(
  'cleanup-inactive-fcm-tokens',
  '0 0 * * 0', -- Her Pazar 00:00 UTC (03:00 Türkiye saati)
  $$SELECT cleanup_inactive_fcm_tokens()$$
);

-- ============================================
-- Cron Job 3: Activity Log Temizleme
-- ============================================
-- Her Pazartesi saat 02:00 (Türkiye saati) = 23:00 UTC Pazar

-- Mevcut job'ı sil (varsa)
SELECT cron.unschedule('cleanup-old-activity-logs') 
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'cleanup-old-activity-logs'
);

-- Yeni cron job ekle
SELECT cron.schedule(
  'cleanup-old-activity-logs',
  '0 23 * * 0', -- Her Pazar 23:00 UTC (Pazartesi 02:00 Türkiye saati)
  $$SELECT cleanup_old_activity_logs()$$
);

-- ============================================
-- Cron Job 4: Şifre Sıfırlama Token Temizleme
-- ============================================
-- Her gün saat 04:00 (Türkiye saati) = 01:00 UTC

-- Mevcut job'ı sil (varsa)
SELECT cron.unschedule('cleanup-expired-reset-tokens') 
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'cleanup-expired-reset-tokens'
);

-- Yeni cron job ekle
SELECT cron.schedule(
  'cleanup-expired-reset-tokens',
  '0 1 * * *', -- Her gün 01:00 UTC (04:00 Türkiye saati)
  $$SELECT cleanup_expired_reset_tokens()$$
);

-- ============================================
-- Cron Job Yönetimi Komutları
-- ============================================
-- 📋 Cron job'ları yönetmek için kullanışlı komutlar

-- Tüm cron job'ları görmek için:
-- SELECT * FROM cron.job;

-- Cron job geçmişini görmek için:
-- SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 20;

-- Belirli bir job'ın geçmişini görmek için:
-- SELECT * FROM cron.job_run_details 
-- WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'cleanup-old-notifications')
-- ORDER BY start_time DESC LIMIT 10;

-- Bir job'ı silmek için:
-- SELECT cron.unschedule('job-name');

-- Bir job'ı manuel çalıştırmak için:
-- SELECT cleanup_old_read_notifications();

-- ============================================
-- İlk Temizleme (Şimdi Çalıştır)
-- ============================================
-- Mevcut eski kayıtları hemen temizle

SELECT smart_cleanup_notifications();
SELECT cleanup_expired_reset_tokens();

-- ============================================
-- Kurulum Mesajları
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Otomatik temizleme sistemi kuruldu';
  RAISE NOTICE '';
  RAISE NOTICE '📋 AKıLLI BİLDİRİM TEMİZLEME KURALLARI:';
  RAISE NOTICE '  1. Okunmuş + bildirimin geldiği saatten 24 saat sonra → Otomatik sil (her saat başı kontrol)';
  RAISE NOTICE '  2. Okunmamış → Kalır (okunana kadar)';
  RAISE NOTICE '  3. Okundu + bildirimin geldiği saatten 24 saat geçmişse → Anında sil (trigger)';
  RAISE NOTICE '  4. Okunmamış + bildirimin geldiği saatten 7 gün geçmişse → Otomatik sil (her saat başı kontrol)';
  RAISE NOTICE '';
  RAISE NOTICE '📅 CRON JOB ZAMANLARI:';
  RAISE NOTICE '  - Bildirimler: Her saat başı (bildirimin geldiği saatten 24 saat sonra silmek için)';
  RAISE NOTICE '  - FCM Token''lar: Her Pazar 03:00 (Türkiye saati)';
  RAISE NOTICE '  - Activity Log''lar: Her Pazartesi 02:00 (Türkiye saati)';
  RAISE NOTICE '  - Reset Token''lar: Her gün 04:00 (Türkiye saati)';
END $$;

-- ============================================
-- 5.9 ATTENDANCE APPROVAL FUNCTIONS (Yevmiye Onay Fonksiyonları)
-- ============================================
-- ✅ Yevmiye taleplerini onaylama/reddetme fonksiyonları

-- Bekleyen talepleri toplu onaylayan fonksiyon
-- 💡 Bir yöneticinin tüm pending taleplerini tek seferde onaylar
CREATE OR REPLACE FUNCTION approve_all_pending_requests(user_id_param BIGINT, reviewed_by_param BIGINT)
RETURNS INTEGER AS $$
DECLARE
  approved_count INTEGER := 0;
  request_record RECORD;
BEGIN
  FOR request_record IN 
    SELECT * FROM attendance_requests 
    WHERE user_id = user_id_param 
    AND request_status = 'pending'
  LOOP
    INSERT INTO attendance (user_id, worker_id, date, status, created_by)
    VALUES (
      request_record.user_id,
      request_record.worker_id,
      request_record.date,
      request_record.status,
      'worker'
    )
    ON CONFLICT (worker_id, date) DO NOTHING;
    
    UPDATE attendance_requests
    SET request_status = 'approved',
        reviewed_at = CURRENT_TIMESTAMP,
        reviewed_by = reviewed_by_param
    WHERE id = request_record.id;
    
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

-- Tek bir talebi onaylayan fonksiyon (EN GÜNCEL - Migration versiyonu)
-- Özellikler:
-- ✅ Türkiye saati (UTC+3) ile attendance kaydı
-- ✅ Bildirim mesajı güncelleme (✅ Onaylandı)
-- ✅ Otomatik is_read = TRUE

CREATE OR REPLACE FUNCTION approve_attendance_request(request_id_param BIGINT, reviewed_by_param BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
  request_record RECORD;
  status_text TEXT;
BEGIN
  SELECT * INTO request_record
  FROM attendance_requests
  WHERE id = request_id_param AND request_status = 'pending';
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Türkiye saati (UTC+3) ile kaydet
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
  
  UPDATE attendance_requests
  SET request_status = 'approved',
      reviewed_at = CURRENT_TIMESTAMP,
      reviewed_by = reviewed_by_param
  WHERE id = request_id_param;
  
  -- Status text'i hazırla
  status_text := CASE 
    WHEN request_record.status = 'fullDay' THEN 'Tam Gün'
    WHEN request_record.status = 'halfDay' THEN 'Yarım Gün'
    WHEN request_record.status = 'absent' THEN 'Gelmedi'
    ELSE request_record.status
  END;
  
  -- Orijinal bildirim mesajını güncelle
  UPDATE notifications
  SET message = (SELECT full_name FROM workers WHERE id = request_record.worker_id) || 
                ' (' || status_text || ') - ✅ Onaylandı',
      is_read = TRUE  -- Otomatik okundu işaretle
  WHERE related_id = request_id_param 
    AND notification_type = 'attendance_request'
    AND recipient_id = request_record.user_id;
  
  -- Çalışana yeni bildirim gönder
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

-- Tek bir talebi reddeden fonksiyon (EN GÜNCEL - Migration versiyonu)
-- Özellikler:
-- ✅ Bildirim mesajı güncelleme (❌ Reddedildi)
-- ✅ Otomatik is_read = TRUE

CREATE OR REPLACE FUNCTION reject_attendance_request(request_id_param BIGINT, reviewed_by_param BIGINT, reason TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  request_record RECORD;
  status_text TEXT;
BEGIN
  SELECT * INTO request_record
  FROM attendance_requests
  WHERE id = request_id_param AND request_status = 'pending';
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  UPDATE attendance_requests
  SET request_status = 'rejected',
      reviewed_at = CURRENT_TIMESTAMP,
      reviewed_by = reviewed_by_param,
      rejection_reason = reason
  WHERE id = request_id_param;
  
  -- Status text'i hazırla
  status_text := CASE 
    WHEN request_record.status = 'fullDay' THEN 'Tam Gün'
    WHEN request_record.status = 'halfDay' THEN 'Yarım Gün'
    WHEN request_record.status = 'absent' THEN 'Gelmedi'
    ELSE request_record.status
  END;
  
  -- Orijinal bildirim mesajını güncelle
  UPDATE notifications
  SET message = (SELECT full_name FROM workers WHERE id = request_record.worker_id) || 
                ' (' || status_text || ') - ❌ Reddedildi',
      is_read = TRUE  -- Otomatik okundu işaretle
  WHERE related_id = request_id_param 
    AND notification_type = 'attendance_request'
    AND recipient_id = request_record.user_id;
  
  -- Çalışana yeni bildirim gönder
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

-- Otomatik onay kontrolü ve işlemi yapan fonksiyon (EN GÜNCEL - Migration versiyonu)
-- Özellikler:
-- ✅ Türkiye saati (UTC+3) ile attendance kaydı
-- ✅ Türkçe mesaj formatı (Tam Gün, Yarım Gün, Gelmedi)
-- ✅ FCM ile anında push notification gönderimi

CREATE OR REPLACE FUNCTION auto_approve_if_trusted()
RETURNS TRIGGER AS $$
DECLARE
  is_trusted_worker BOOLEAN;
  auto_approve_enabled BOOLEAN;
BEGIN
  SELECT w.is_trusted INTO is_trusted_worker
  FROM workers w
  WHERE w.id = NEW.worker_id;
  
  SELECT COALESCE(ns.auto_approve_trusted, FALSE) INTO auto_approve_enabled
  FROM notification_settings ns
  WHERE ns.user_id = NEW.user_id;
  
  IF COALESCE(is_trusted_worker, FALSE) AND auto_approve_enabled THEN
    -- Türkiye saati (UTC+3) ile kaydet
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
    
    NEW.request_status := 'approved';
    NEW.reviewed_at := CURRENT_TIMESTAMP;
    NEW.reviewed_by := NEW.user_id;
    
    -- Çalışana otomatik onay bildirimi (FCM ile anında)
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
    -- Yöneticiye yevmiye talebi bildirimi (FCM ile anında)
    INSERT INTO notifications (
      sender_id, sender_type, recipient_id, recipient_type,
      notification_type, title, message, related_id
    ) VALUES (
      NEW.worker_id, 'worker', NEW.user_id, 'user',
      'attendance_request', 'Yeni Yevmiye Talebi',
      (SELECT full_name FROM workers WHERE id = NEW.worker_id) || ' (' || 
      CASE 
        WHEN NEW.status = 'fullDay' THEN 'Tam Gün'
        WHEN NEW.status = 'halfDay' THEN 'Yarım Gün'
        WHEN NEW.status = 'absent' THEN 'Gelmedi'
        ELSE NEW.status
      END || ') - Onay bekliyor',
      NEW.id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5.10 PAYMENT FUNCTIONS (Ödeme Fonksiyonları - Migration)
-- ============================================
-- 💰 Ödeme güncelleme ve silme fonksiyonları
-- Otomatik bildirim gönderimi ile

CREATE OR REPLACE FUNCTION update_payment(
  payment_id_param BIGINT,
  full_days_param INTEGER,
  half_days_param INTEGER,
  amount_param NUMERIC
)
RETURNS BOOLEAN AS $$
DECLARE
  payment_record RECORD;
  old_full_days INTEGER;
  old_half_days INTEGER;
  old_amount NUMERIC;
  notification_message TEXT;
BEGIN
  SELECT * INTO payment_record
  FROM payments
  WHERE id = payment_id_param;
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  old_full_days := payment_record.full_days;
  old_half_days := payment_record.half_days;
  old_amount := payment_record.amount;
  
  DELETE FROM paid_days WHERE payment_id = payment_id_param;
  
  DECLARE
    unpaid_record RECORD;
    full_days_to_mark INTEGER := full_days_param;
    half_days_to_mark INTEGER := half_days_param;
  BEGIN
    FOR unpaid_record IN (
      SELECT a.worker_id, a.date, a.status
      FROM attendance a
      WHERE a.worker_id = payment_record.worker_id
        AND a.user_id = payment_record.user_id
        AND (a.status = 'fullDay' OR a.status = 'halfDay')
        AND NOT EXISTS (
          SELECT 1 FROM paid_days pd
          WHERE pd.worker_id = a.worker_id
            AND pd.date = a.date
            AND pd.status = a.status
            AND pd.payment_id != payment_id_param
        )
      ORDER BY a.date
    ) LOOP
      IF unpaid_record.status = 'fullDay' AND full_days_to_mark > 0 THEN
        INSERT INTO paid_days (user_id, worker_id, date, status, payment_id)
        VALUES (payment_record.user_id, unpaid_record.worker_id, unpaid_record.date, unpaid_record.status, payment_id_param);
        full_days_to_mark := full_days_to_mark - 1;
      END IF;
      
      IF unpaid_record.status = 'halfDay' AND half_days_to_mark > 0 THEN
        INSERT INTO paid_days (user_id, worker_id, date, status, payment_id)
        VALUES (payment_record.user_id, unpaid_record.worker_id, unpaid_record.date, unpaid_record.status, payment_id_param);
        half_days_to_mark := half_days_to_mark - 1;
      END IF;
      
      EXIT WHEN full_days_to_mark <= 0 AND half_days_to_mark <= 0;
    END LOOP;
  END;
  
  UPDATE payments
  SET 
    full_days = full_days_param,
    half_days = half_days_param,
    amount = amount_param,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = payment_id_param;
  
  notification_message := '';
  
  IF old_full_days != full_days_param THEN
    notification_message := notification_message || old_full_days || ' Tam Gün - ' || full_days_param || ' Tam Gün' || E'\n';
  ELSE
    notification_message := notification_message || old_full_days || ' Tam Gün - Değişiklik yok' || E'\n';
  END IF;
  
  IF old_half_days != half_days_param THEN
    notification_message := notification_message || old_half_days || ' Yarım Gün - ' || half_days_param || ' Yarım Gün' || E'\n';
  ELSE
    notification_message := notification_message || old_half_days || ' Yarım Gün - Değişiklik yok' || E'\n';
  END IF;
  
  IF old_amount != amount_param THEN
    notification_message := notification_message || '₺' || REPLACE(TO_CHAR(old_amount, 'FM999G999G999G999'), ',', '.') || ' - ₺' || REPLACE(TO_CHAR(amount_param, 'FM999G999G999G999'), ',', '.') || E'\n';
  ELSE
    notification_message := notification_message || '₺' || REPLACE(TO_CHAR(old_amount, 'FM999G999G999G999'), ',', '.') || ' - Değişiklik yok' || E'\n';
  END IF;
  
  notification_message := notification_message || E'\n' || 'Güncelleme Tarihi: ' || TO_CHAR(CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul', 'DD.MM.YYYY HH24:MI');
  
  INSERT INTO notifications (
    sender_id, sender_type, recipient_id, recipient_type,
    notification_type, title, message, related_id
  ) VALUES (
    payment_record.user_id, 'user', payment_record.worker_id, 'worker',
    'payment_updated', 'Ödemelerde güncelleme yapıldı!',
    notification_message,
    payment_id_param
  );
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_payment(payment_id_param BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
  payment_record RECORD;
  notification_message TEXT;
BEGIN
  SELECT * INTO payment_record
  FROM payments
  WHERE id = payment_id_param;
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  notification_message := 
    payment_record.full_days || ' Tam Gün' || E'\n' ||
    payment_record.half_days || ' Yarım Gün' || E'\n' ||
    '₺' || REPLACE(TO_CHAR(payment_record.amount, 'FM999G999G999G999'), ',', '.') || E'\n\n' ||
    'Ödeme Tarihi: ' || TO_CHAR(payment_record.payment_date, 'DD.MM.YYYY') || E'\n' ||
    'Silme Tarihi: ' || TO_CHAR(CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Istanbul', 'DD.MM.YYYY HH24:MI');
  
  INSERT INTO notifications (
    sender_id, sender_type, recipient_id, recipient_type,
    notification_type, title, message, related_id
  ) VALUES (
    payment_record.user_id, 'user', payment_record.worker_id, 'worker',
    'payment_deleted', 'Yapılan ödeme silindi!',
    notification_message,
    payment_id_param
  );
  
  DELETE FROM paid_days WHERE payment_id = payment_id_param;
  
  DELETE FROM payments WHERE id = payment_id_param;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5.11 UPDATED_AT FUNCTIONS (Otomatik Güncelleme)
-- ============================================
-- 🕐 updated_at kolonunu otomatik güncelleyen trigger fonksiyonları

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_payments_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5.13 ADVANCE AND EXPENSE FUNCTIONS (Avans ve Masraf Fonksiyonları)
-- ============================================
-- 💰 Avans ve masraf hesaplama fonksiyonları

-- Çalışanın toplam avansını hesaplayan fonksiyon
CREATE OR REPLACE FUNCTION get_worker_total_advances(worker_id_param BIGINT)
RETURNS DECIMAL AS $$
DECLARE
  total_advance DECIMAL;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO total_advance
  FROM advances
  WHERE worker_id = worker_id_param;
  
  RETURN total_advance;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_worker_total_advances(BIGINT) IS 'Çalışanın toplam avansını hesaplar';

-- Çalışanın düşülmemiş avansını hesaplayan fonksiyon
CREATE OR REPLACE FUNCTION get_worker_pending_advances(worker_id_param BIGINT)
RETURNS DECIMAL AS $$
DECLARE
  pending_advance DECIMAL;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO pending_advance
  FROM advances
  WHERE worker_id = worker_id_param AND is_deducted = FALSE;
  
  RETURN pending_advance;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_worker_pending_advances(BIGINT) IS 'Çalışanın henüz düşülmemiş avansını hesaplar';

-- Kategoriye göre toplam masrafı hesaplayan fonksiyon
CREATE OR REPLACE FUNCTION get_expenses_by_category(user_id_param BIGINT, category_param TEXT)
RETURNS DECIMAL AS $$
DECLARE
  total_expense DECIMAL;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO total_expense
  FROM expenses
  WHERE user_id = user_id_param AND category = category_param;
  
  RETURN total_expense;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_expenses_by_category(BIGINT, TEXT) IS 'Belirli kategorideki toplam masrafı hesaplar';

-- Yöneticinin aylık toplam masrafını hesaplayan fonksiyon
CREATE OR REPLACE FUNCTION get_monthly_expenses(user_id_param BIGINT, month_start DATE, month_end DATE)
RETURNS DECIMAL AS $$
DECLARE
  monthly_total DECIMAL;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO monthly_total
  FROM expenses
  WHERE user_id = user_id_param
    AND expense_date >= month_start
    AND expense_date <= month_end;
  
  RETURN monthly_total;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_monthly_expenses(BIGINT, DATE, DATE) IS 'Belirli ay aralığındaki toplam masrafı hesaplar';

-- Yöneticinin aylık toplam avansını hesaplayan fonksiyon
CREATE OR REPLACE FUNCTION get_monthly_advances(user_id_param BIGINT, month_start DATE, month_end DATE)
RETURNS DECIMAL AS $$
DECLARE
  monthly_total DECIMAL;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO monthly_total
  FROM advances
  WHERE user_id = user_id_param
    AND advance_date >= month_start
    AND advance_date <= month_end;
  
  RETURN monthly_total;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_monthly_advances(BIGINT, DATE, DATE) IS 'Belirli ay aralığındaki toplam avansı hesaplar';

-- En çok harcanan kategoriyi bulan fonksiyon
CREATE OR REPLACE FUNCTION get_top_expense_category(user_id_param BIGINT)
RETURNS TABLE (
  category TEXT,
  total_amount DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.category,
    SUM(e.amount) as total_amount
  FROM expenses e
  WHERE e.user_id = user_id_param
  GROUP BY e.category
  ORDER BY total_amount DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_top_expense_category(BIGINT) IS 'En çok harcanan kategoriyi ve tutarını döndürür';

-- ============================================
-- SECTION 6: TRIGGERS (Tetikleyiciler)
-- ============================================
-- 📌 AÇIKLAMA: Otomatik çalışan veritabanı tetikleyicileri
-- INSERT, UPDATE, DELETE işlemlerinde otomatik çalışır

-- ============================================
-- 6.1 AUTO APPROVE TRIGGER
-- ============================================
-- ✅ Güvenilir çalışanların taleplerini otomatik onaylar
-- attendance_requests tablosuna INSERT olduğunda çalışır

CREATE TRIGGER trigger_auto_approve_attendance
  BEFORE INSERT ON attendance_requests
  FOR EACH ROW
  EXECUTE FUNCTION auto_approve_if_trusted();

-- ============================================
-- 6.2 UPDATED_AT TRIGGERS (Users & Workers)
-- ============================================
-- 🕐 Kullanıcı ve çalışan güncellendiğinde updated_at'i otomatik günceller

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workers_updated_at
  BEFORE UPDATE ON workers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6.3 ATTENDANCE UPDATED_AT TRIGGER (Migration)
-- ============================================
-- 🕐 Yevmiye güncellendiğinde updated_at'i otomatik günceller

CREATE TRIGGER update_attendance_updated_at
    BEFORE UPDATE ON attendance
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6.4 PAYMENTS UPDATED_AT TRIGGER (Migration)
-- ============================================
-- 🕐 Ödeme güncellendiğinde updated_at'i otomatik günceller

CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_payments_updated_at_column();

-- ============================================
-- 6.5 FCM TOKENS UPDATED_AT TRIGGER (Migration)
-- ============================================
-- 🕐 FCM token güncellendiğinde updated_at'i otomatik günceller

CREATE TRIGGER trigger_update_fcm_tokens_updated_at
BEFORE UPDATE ON fcm_tokens
FOR EACH ROW
EXECUTE FUNCTION update_fcm_tokens_updated_at();

-- ============================================
-- 6.6 EMAIL UNIQUE CHECK TRIGGERS (Migration)
-- ============================================
-- 📧 Email benzersizliğini kontrol eder (users ve workers arası)

CREATE TRIGGER check_email_unique_users
  BEFORE INSERT OR UPDATE OF email ON users
  FOR EACH ROW
  EXECUTE FUNCTION check_email_unique();

CREATE TRIGGER check_email_unique_workers
  BEFORE INSERT OR UPDATE OF email ON workers
  FOR EACH ROW
  EXECUTE FUNCTION check_email_unique();

-- ============================================
-- 6.7 FCM NOTIFICATION TRIGGER (Migration)
-- ============================================
-- 📱 Yeni bildirim eklendiğinde otomatik push notification gönderir
-- Supabase Edge Function çağrısı yapar

CREATE TRIGGER on_notification_insert_fcm_trigger
AFTER INSERT ON notifications
FOR EACH ROW
EXECUTE FUNCTION notify_via_fcm();

COMMENT ON TRIGGER on_notification_insert_fcm_trigger ON notifications IS 'Yeni bildirim için FCM push notification gönderir';

-- ============================================
-- 6.8 SMART NOTIFICATION CLEANUP TRIGGER
-- ============================================
-- 🗑️ Bildirim okunduğunda akıllı temizleme yapar
-- KURAL 3: Okundu + aynı gün değilse → HEMEN SİL

DROP TRIGGER IF EXISTS trigger_cleanup_on_read ON notifications;
CREATE TRIGGER trigger_cleanup_on_read
  BEFORE UPDATE OF is_read ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION cleanup_on_notification_read();

COMMENT ON TRIGGER trigger_cleanup_on_read ON notifications IS 
'Bildirim okunduğunda otomatik temizleme yapar (eski ise hemen siler)';

-- ============================================
-- 6.9 ADVANCES UPDATED_AT TRIGGER
-- ============================================
-- 🕐 Avans güncellendiğinde updated_at'i otomatik günceller

DROP TRIGGER IF EXISTS update_advances_updated_at ON advances;
CREATE TRIGGER update_advances_updated_at
  BEFORE UPDATE ON advances
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6.10 EXPENSES UPDATED_AT TRIGGER
-- ============================================
-- 🕐 Masraf güncellendiğinde updated_at'i otomatik günceller

DROP TRIGGER IF EXISTS update_expenses_updated_at ON expenses;
CREATE TRIGGER update_expenses_updated_at
  BEFORE UPDATE ON expenses
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SECTION 7: ROW LEVEL SECURITY (RLS)
-- ============================================
-- 📌 AÇIKLAMA: Satır seviyesi güvenlik politikaları
-- Hangi kullanıcının hangi verilere erişebileceğini kontrol eder

-- ============================================
-- 7.1 ENABLE RLS ON ALL TABLES
-- ============================================
-- 🔒 Tüm tablolarda RLS'yi aktifleştirir
-- NOT: Şu an tüm tablolar için "allow_all" politikası var (geliştirme aşaması)

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
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE password_reset_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE advances ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 7.2 CORE TABLES RLS POLICIES
-- ============================================
-- 🔓 Ana tablolar için politikalar (şu an herkese açık - geliştirme aşaması)
-- Production'da kullanıcı bazlı kısıtlamalar eklenmelidir

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
-- 7.3 FCM TOKENS RLS POLICIES (Migration)
-- ============================================
-- 🔓 Service role tam erişime sahip (FCM token yönetimi için)

CREATE POLICY "Service role has full access"
ON fcm_tokens FOR ALL
USING (true);

-- ============================================
-- 7.4 ACTIVITY LOGS RLS POLICIES (Migration)
-- ============================================
-- 📋 Activity log politikaları
-- Sadece okuma ve ekleme izni var, güncelleme/silme yasak (denetim için)

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

-- ============================================
-- 7.5 PASSWORD RESET TOKENS RLS POLICIES (Migration)
-- ============================================
-- 🔑 Şifre sıfırlama token'ları için politika (herkese açık)

DROP POLICY IF EXISTS "allow_all_password_reset_tokens" ON password_reset_tokens;
CREATE POLICY "allow_all_password_reset_tokens" ON password_reset_tokens FOR ALL USING (true);

-- ============================================
-- 7.6 ADVANCES RLS POLICIES
-- ============================================
-- 💰 Avans politikaları (herkese açık - geliştirme aşaması)

DROP POLICY IF EXISTS "allow_all_advances" ON advances;
CREATE POLICY "allow_all_advances" ON advances FOR ALL USING (true);

-- ============================================
-- 7.7 EXPENSES RLS POLICIES
-- ============================================
-- 🏗️ Masraf politikaları (herkese açık - geliştirme aşaması)

DROP POLICY IF EXISTS "allow_all_expenses" ON expenses;
CREATE POLICY "allow_all_expenses" ON expenses FOR ALL USING (true);

-- ============================================
-- 7.8 NOTIFICATIONS REALTIME SETUP (Migration)
-- ============================================
-- 🔴 Supabase Realtime için ayarlar
-- REPLICA IDENTITY FULL: Tüm kolonları realtime'a gönderir
-- supabase_realtime: Bildirimler canlı olarak istemcilere iletilir

ALTER TABLE notifications REPLICA IDENTITY FULL;

ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- ============================================
-- SECTION 8: INITIAL DATA (Başlangıç Verileri)
-- ============================================
-- 📌 AÇIKLAMA: Veritabanı ilk kurulumda eklenen veriler
-- Admin kullanıcısı otomatik oluşturulur

-- Admin hesabı oluştur (şifre: ferhatcakircali - bcrypt ile hash'lenmiş)
-- 👤 Kullanıcı adı: admin
-- 🔐 Şifre: ferhatcakircali (bcrypt cost=10 ile hash'lenmiş)
-- ⚠️ Production'da bu şifreyi mutlaka değiştirin!
INSERT INTO users (username, password_hash, first_name, last_name, job_title, role, is_admin, is_blocked)
SELECT 
  'admin', 
  crypt('ferhatcakircali', gen_salt('bf', 10)), -- ✅ bcrypt hash (cost=10)
  'Ferhat', 
  'ÇAKIRCALI', 
  'System Administrator', 
  'admin',
  TRUE, 
  FALSE
WHERE NOT EXISTS (
  SELECT 1 FROM users WHERE username = 'admin'
);
