-- ============================================
-- Migration 007: Add Instant Notification Function for Manager
-- Date: 2026-02-21
-- Purpose: When worker submits attendance request, send instant notification to manager
--          This function will be called from Flutter to send local push notification
-- ============================================

-- Function to get manager info for notification
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
-- NOTLAR
-- ============================================
-- 
-- KULLANIM:
-- Flutter tarafında çalışan yevmiye talebi gönderdiğinde:
-- 1. attendance_requests tablosuna INSERT yapılır (trigger çalışır)
-- 2. Trigger veritabanına bildirim kaydı ekler
-- 3. Flutter bu fonksiyonu çağırarak yöneticinin bilgilerini alır
-- 4. Flutter NotificationService.showInstantNotification() ile local bildirim gönderir
--
-- ÖRNEK FLUTTER KODU:
-- final managerInfo = await supabase.rpc('get_manager_info_for_notification', 
--   params: {'user_id_param': userId});
-- 
-- if (managerInfo.isNotEmpty) {
--   await notificationService.showInstantNotification(
--     id: 2, // Yevmiye talebi bildirimi için ID
--     title: 'Yeni Yevmiye Talebi',
--     body: '$workerName yevmiye girişi için onay bekliyor',
--     payload: 'attendance_request:$requestId',
--   );
-- }
--
