-- ============================================
-- PERFORMANS İYİLEŞTİRME İNDEKSLERİ (KONSOLİDE)
-- ============================================
-- Bu dosya, en sık kullanılan sorgular için tüm indeksleri oluşturur
-- 010 ve 011 migration dosyaları birleştirilmiştir
-- Supabase SQL Editor'de çalıştırın

-- ============================================
-- BÖLÜM 1: TEMEL İNDEKSLER
-- ============================================

-- ============================================
-- 1. EMPLOYEE_REMINDERS İNDEKSLERİ
-- ============================================

-- Hatırlatıcı tarihi ve kullanıcı bazlı sorgular için
CREATE INDEX IF NOT EXISTS idx_employee_reminders_user_date 
ON employee_reminders(user_id, reminder_date);

-- Tamamlanma durumu için
CREATE INDEX IF NOT EXISTS idx_employee_reminders_completed 
ON employee_reminders(is_completed);

-- Hatırlatıcı tarihi sıralama için
CREATE INDEX IF NOT EXISTS idx_employee_reminders_date 
ON employee_reminders(reminder_date DESC);

-- Sadece tamamlanmamış hatırlatıcılar için (partial index)
CREATE INDEX IF NOT EXISTS idx_reminders_pending 
ON employee_reminders(user_id, reminder_date) 
WHERE is_completed = false;

-- Bugünün hatırlatmaları için
CREATE INDEX IF NOT EXISTS idx_employee_reminders_today 
ON employee_reminders(user_id, reminder_date, is_completed)
WHERE is_completed = FALSE;

-- Worker bazlı hatırlatmalar
CREATE INDEX IF NOT EXISTS idx_employee_reminders_worker_pending 
ON employee_reminders(worker_id, reminder_date DESC)
WHERE is_completed = FALSE;

COMMENT ON INDEX idx_employee_reminders_today IS 
'Bugünün tamamlanmamış hatırlatmalarını hızlı getirmek için.';

COMMENT ON INDEX idx_employee_reminders_worker_pending IS 
'Çalışan bazlı bekleyen hatırlatmaları listelemek için.';

-- ============================================
-- 2. ACTIVITY_LOGS İNDEKSLERİ
-- ============================================

-- Oluşturulma tarihi için (temizleme ve sıralama)
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at 
ON activity_logs(created_at DESC);

-- Admin kullanıcı bazlı loglar için
CREATE INDEX IF NOT EXISTS idx_activity_logs_admin 
ON activity_logs(admin_id, created_at DESC);

-- Action type bazlı filtreleme
CREATE INDEX IF NOT EXISTS idx_activity_logs_action_created 
ON activity_logs(action_type, created_at DESC);

-- Target user bazlı sorgular
CREATE INDEX IF NOT EXISTS idx_activity_logs_target_created 
ON activity_logs(target_user_id, created_at DESC)
WHERE target_user_id IS NOT NULL;

COMMENT ON INDEX idx_activity_logs_action_created IS 
'Belirli işlem tiplerini tarih sırasıyla listelemek için.';

COMMENT ON INDEX idx_activity_logs_target_created IS 
'Belirli bir kullanıcı üzerinde yapılan işlemleri görmek için.';

-- ============================================
-- 3. ATTENDANCE (ATTENDANCES) İNDEKSLERİ
-- ============================================

-- Çalışan ve tarih bazlı puantaj sorguları için
CREATE INDEX IF NOT EXISTS idx_attendances_worker_date 
ON attendance(worker_id, date DESC);

-- Kullanıcı ve tarih bazlı sorgular için
CREATE INDEX IF NOT EXISTS idx_attendances_user_date 
ON attendance(user_id, date DESC);

-- Tarih aralığı sorguları için
CREATE INDEX IF NOT EXISTS idx_attendances_date 
ON attendance(date DESC);

-- Çalışan puantaj raporu için (composite index - en sık kullanılan)
CREATE INDEX IF NOT EXISTS idx_attendances_worker_user_date 
ON attendance(worker_id, user_id, date DESC);

-- ============================================
-- 4. ATTENDANCE_REQUESTS İNDEKSLERİ
-- ============================================

-- Çalışanın belirli bir tarihteki talep durumu
CREATE INDEX IF NOT EXISTS idx_attendance_requests_worker_date_unique 
ON attendance_requests(worker_id, date, request_status);

-- Yönetici için bekleyen talepler
CREATE INDEX IF NOT EXISTS idx_attendance_requests_user_pending 
ON attendance_requests(user_id, request_status, requested_at DESC)
WHERE request_status = 'pending';

-- Çalışan için talep geçmişi
CREATE INDEX IF NOT EXISTS idx_attendance_requests_worker_reviewed 
ON attendance_requests(worker_id, reviewed_at DESC)
WHERE reviewed_at IS NOT NULL;

COMMENT ON INDEX idx_attendance_requests_worker_date_unique IS 
'Çalışanın belirli bir tarihteki talep durumunu hızlı kontrol eder.';

COMMENT ON INDEX idx_attendance_requests_user_pending IS 
'Yöneticinin bekleyen taleplerini hızlı listelemek için partial index.';

COMMENT ON INDEX idx_attendance_requests_worker_reviewed IS 
'Çalışanın onaylanmış/reddedilmiş talep geçmişi için.';

-- ============================================
-- 5. PAYMENTS İNDEKSLERİ
-- ============================================

-- Çalışan bazlı ödeme sorguları için
CREATE INDEX IF NOT EXISTS idx_payments_worker 
ON payments(worker_id, payment_date DESC);

-- Kullanıcı bazlı ödeme sorguları için
CREATE INDEX IF NOT EXISTS idx_payments_user 
ON payments(user_id, payment_date DESC);

-- Ödeme tarihi sıralama için
CREATE INDEX IF NOT EXISTS idx_payments_date 
ON payments(payment_date DESC);

-- Ödeme raporu için (composite index)
CREATE INDEX IF NOT EXISTS idx_payments_worker_user_date 
ON payments(worker_id, user_id, payment_date DESC);

-- ============================================
-- 6. PAID_DAYS İNDEKSLERİ
-- ============================================

-- Belirli bir günün ödenip ödenmediğini kontrol
CREATE INDEX IF NOT EXISTS idx_paid_days_worker_date_status 
ON paid_days(worker_id, date, status);

-- Ödeme silme/güncelleme için
CREATE INDEX IF NOT EXISTS idx_paid_days_payment_worker 
ON paid_days(payment_id, worker_id, date);

-- Ödenmemiş günleri bulmak için
CREATE INDEX IF NOT EXISTS idx_paid_days_worker_date_lookup 
ON paid_days(worker_id, date);

COMMENT ON INDEX idx_paid_days_worker_date_status IS 
'Belirli bir günün ödenip ödenmediğini kontrol etmek için composite index.';

COMMENT ON INDEX idx_paid_days_payment_worker IS 
'Ödeme silme ve güncelleme işlemlerinde kullanılır.';

COMMENT ON INDEX idx_paid_days_worker_date_lookup IS 
'Çalışanın hangi günlerinin ödendiğini hızlı kontrol eder.';

-- ============================================
-- 7. ADVANCES İNDEKSLERİ
-- ============================================

-- Çalışan bazlı avans sorguları için
CREATE INDEX IF NOT EXISTS idx_advances_worker 
ON advances(worker_id, advance_date DESC);

-- Kullanıcı bazlı avans sorguları için
CREATE INDEX IF NOT EXISTS idx_advances_user 
ON advances(user_id, advance_date DESC);

-- Avans tarihi sıralama için
CREATE INDEX IF NOT EXISTS idx_advances_date 
ON advances(advance_date DESC);

-- Avans raporu için (composite index)
CREATE INDEX IF NOT EXISTS idx_advances_worker_user_date 
ON advances(worker_id, user_id, advance_date DESC);

-- Ödeme ile ilişkilendirme için
CREATE INDEX IF NOT EXISTS idx_advances_deducted_payment 
ON advances(deducted_from_payment_id, worker_id)
WHERE deducted_from_payment_id IS NOT NULL;

COMMENT ON INDEX idx_advances_deducted_payment IS 
'Hangi ödemeden avans düşüldüğünü bulmak için.';

-- ============================================
-- 8. EXPENSES İNDEKSLERİ
-- ============================================

-- Kullanıcı ve tarih bazlı masraf sorguları için
CREATE INDEX IF NOT EXISTS idx_expenses_user_date 
ON expenses(user_id, expense_date DESC);

-- Kategori bazlı sorgular için
CREATE INDEX IF NOT EXISTS idx_expenses_category 
ON expenses(category, expense_date DESC);

-- Masraf tarihi sıralama için
CREATE INDEX IF NOT EXISTS idx_expenses_date 
ON expenses(expense_date DESC);

-- Aylık masraf raporu için
CREATE INDEX IF NOT EXISTS idx_expenses_user_month 
ON expenses(user_id, EXTRACT(YEAR FROM expense_date), EXTRACT(MONTH FROM expense_date), amount);

COMMENT ON INDEX idx_expenses_user_month IS 
'Aylık masraf raporları için optimize edilmiş index.';

-- ============================================
-- 9. WORKERS (EMPLOYEES) İNDEKSLERİ
-- ============================================

-- Kullanıcı bazlı çalışan sorguları için
CREATE INDEX IF NOT EXISTS idx_employees_user 
ON workers(user_id, full_name);

-- Başlangıç tarihi sıralama için
CREATE INDEX IF NOT EXISTS idx_employees_start_date 
ON workers(start_date DESC);

-- Sadece aktif çalışanlar için (partial index)
CREATE INDEX IF NOT EXISTS idx_employees_active 
ON workers(user_id, full_name) 
WHERE is_active = true;

-- Aktif çalışanlar için (composite)
CREATE INDEX IF NOT EXISTS idx_workers_user_active 
ON workers(user_id, is_active, full_name)
WHERE is_active = TRUE;

-- Username ve email kontrolü için (case-insensitive)
CREATE INDEX IF NOT EXISTS idx_workers_username_lower 
ON workers(LOWER(username));

CREATE INDEX IF NOT EXISTS idx_workers_email_lower 
ON workers(LOWER(email))
WHERE email IS NOT NULL;

COMMENT ON INDEX idx_workers_user_active IS 
'Yöneticinin aktif çalışanlarını hızlı listelemek için partial index.';

COMMENT ON INDEX idx_workers_username_lower IS 
'Case-insensitive username araması için.';

COMMENT ON INDEX idx_workers_email_lower IS 
'Case-insensitive email araması için.';

-- ============================================
-- 10. USERS İNDEKSLERİ
-- ============================================

-- Email bazlı kullanıcı sorguları için
CREATE INDEX IF NOT EXISTS idx_users_email 
ON users(email);

-- Username bazlı sorgular için
CREATE INDEX IF NOT EXISTS idx_users_username 
ON users(username);

-- Admin durumu için
CREATE INDEX IF NOT EXISTS idx_users_admin 
ON users(is_admin);

-- Blok durumu için
CREATE INDEX IF NOT EXISTS idx_users_blocked 
ON users(is_blocked);

-- Username ve email kontrolü için (case-insensitive)
CREATE INDEX IF NOT EXISTS idx_users_username_lower 
ON users(LOWER(username));

CREATE INDEX IF NOT EXISTS idx_users_email_lower 
ON users(LOWER(email))
WHERE email IS NOT NULL;

-- Aktif yöneticiler için
CREATE INDEX IF NOT EXISTS idx_users_active 
ON users(is_blocked, is_admin)
WHERE is_blocked = FALSE;

COMMENT ON INDEX idx_users_username_lower IS 
'Case-insensitive username araması için.';

COMMENT ON INDEX idx_users_email_lower IS 
'Case-insensitive email araması için.';

COMMENT ON INDEX idx_users_active IS 
'Bloklanmamış kullanıcıları hızlı filtrelemek için.';

-- ============================================
-- BÖLÜM 2: BİLDİRİM VE TOKEN İNDEKSLERİ
-- ============================================

-- ============================================
-- 11. NOTIFICATIONS İNDEKSLERİ
-- ============================================

-- Okunmamış bildirimleri hızlı getirmek için
CREATE INDEX IF NOT EXISTS idx_notifications_unread_lookup 
ON notifications(recipient_id, recipient_type, is_read, created_at DESC)
WHERE is_read = FALSE;

-- Bildirim tipi bazlı sorgular için
CREATE INDEX IF NOT EXISTS idx_notifications_type_recipient 
ON notifications(notification_type, recipient_id, created_at DESC);

-- Related_id ile bildirim bulma (onay/red işlemleri için)
CREATE INDEX IF NOT EXISTS idx_notifications_related_id 
ON notifications(related_id, notification_type)
WHERE related_id IS NOT NULL;

COMMENT ON INDEX idx_notifications_unread_lookup IS 
'Okunmamış bildirimleri hızlı getirmek için partial composite index. Worker ve User dashboard''larında kullanılır.';

COMMENT ON INDEX idx_notifications_type_recipient IS 
'Bildirim tipine göre filtreleme için (attendance_request, payment_notification, vb.)';

COMMENT ON INDEX idx_notifications_related_id IS 
'Yevmiye talebi onay/red işlemlerinde orijinal bildirimi bulmak için kullanılır.';

-- ============================================
-- 12. FCM_TOKENS İNDEKSLERİ
-- ============================================

-- Aktif token'ları user/worker bazlı getirmek için
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_active 
ON fcm_tokens(user_id, is_active, last_used_at DESC)
WHERE user_id IS NOT NULL AND is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_fcm_tokens_worker_active 
ON fcm_tokens(worker_id, is_active, last_used_at DESC)
WHERE worker_id IS NOT NULL AND is_active = TRUE;

-- Eski token temizleme için
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_cleanup 
ON fcm_tokens(is_active, updated_at)
WHERE is_active = FALSE;

COMMENT ON INDEX idx_fcm_tokens_user_active IS 
'Kullanıcının aktif FCM token''larını push notification için hızlı getirir.';

COMMENT ON INDEX idx_fcm_tokens_worker_active IS 
'Çalışanın aktif FCM token''larını push notification için hızlı getirir.';

COMMENT ON INDEX idx_fcm_tokens_cleanup IS 
'Eski deaktif token''ları temizlemek için (cleanup_inactive_fcm_tokens fonksiyonu).';

-- ============================================
-- 13. NOTIFICATION_SETTINGS İNDEKSLERİ
-- ============================================

-- Aktif bildirim ayarları için
CREATE INDEX IF NOT EXISTS idx_notification_settings_enabled 
ON notification_settings(enabled, time)
WHERE enabled = TRUE;

COMMENT ON INDEX idx_notification_settings_enabled IS 
'Aktif bildirim ayarlarını zamanlamak için (cron job veya scheduler).';

-- ============================================
-- 14. NOTIFICATION_SETTINGS_WORKERS İNDEKSLERİ
-- ============================================

-- Aktif çalışan bildirim ayarları için
CREATE INDEX IF NOT EXISTS idx_notification_settings_workers_enabled_time 
ON notification_settings_workers(enabled, time)
WHERE enabled = TRUE;

COMMENT ON INDEX idx_notification_settings_workers_enabled_time IS 
'Aktif çalışan bildirim ayarlarını zamanlamak için.';

-- ============================================
-- 15. PASSWORD_RESET_TOKENS İNDEKSLERİ
-- ============================================

-- Geçerli şifre sıfırlama token'larını hızlı kontrol
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_valid 
ON password_reset_tokens(token, expires_at, used)
WHERE used = FALSE;

-- Email ile token arama
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_email_valid 
ON password_reset_tokens(email, user_type, expires_at)
WHERE used = FALSE;

COMMENT ON INDEX idx_password_reset_tokens_valid IS 
'Geçerli şifre sıfırlama token''larını hızlı kontrol eder.';

COMMENT ON INDEX idx_password_reset_tokens_email_valid IS 
'Email ile geçerli token''ları bulmak için.';

-- ============================================
-- ANALYZE - Tablo İstatistiklerini Güncelle
-- ============================================

ANALYZE users;
ANALYZE workers;
ANALYZE attendance;
ANALYZE attendance_requests;
ANALYZE payments;
ANALYZE paid_days;
ANALYZE advances;
ANALYZE expenses;
ANALYZE employee_reminders;
ANALYZE activity_logs;
ANALYZE notifications;
ANALYZE fcm_tokens;
ANALYZE notification_settings;
ANALYZE notification_settings_workers;
ANALYZE password_reset_tokens;

