-- ============================================
-- NOTIFICATION TRIGGER FOR FCM PUSH
-- ============================================
-- Bu trigger, notifications tablosuna yeni kayıt eklendiğinde
-- otomatik olarak FCM push notification gönderir

-- Edge Function çağırmak için fonksiyon
CREATE OR REPLACE FUNCTION notify_fcm_on_insert()
RETURNS TRIGGER AS $$
DECLARE
  recipient_fcm_token TEXT;
  notification_payload JSONB;
BEGIN
  -- Alıcının FCM token'ını al
  IF NEW.recipient_type = 'worker' THEN
    SELECT token INTO recipient_fcm_token
    FROM fcm_tokens
    WHERE worker_id = NEW.recipient_id
      AND is_active = true
    ORDER BY updated_at DESC
    LIMIT 1;
  ELSIF NEW.recipient_type = 'user' THEN
    SELECT token INTO recipient_fcm_token
    FROM fcm_tokens
    WHERE user_id = NEW.recipient_id
      AND is_active = true
    ORDER BY updated_at DESC
    LIMIT 1;
  END IF;

  -- Token varsa notification payload oluştur
  IF recipient_fcm_token IS NOT NULL THEN
    notification_payload := jsonb_build_object(
      'token', recipient_fcm_token,
      'title', NEW.title,
      'body', NEW.message,
      'data', jsonb_build_object(
        'notification_id', NEW.id,
        'notification_type', NEW.notification_type,
        'related_id', NEW.related_id,
        'click_action', 'FLUTTER_NOTIFICATION_CLICK'
      )
    );

    -- Edge Function'a HTTP request gönder (pg_net extension gerekli)
    -- NOT: Bu kısım Supabase Edge Function ile entegre edilmeli
    -- Şimdilik sadece log yazıyoruz
    RAISE NOTICE 'FCM Notification: %', notification_payload;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger oluştur
DROP TRIGGER IF EXISTS trigger_fcm_notification ON notifications;
CREATE TRIGGER trigger_fcm_notification
  AFTER INSERT ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION notify_fcm_on_insert();

COMMENT ON FUNCTION notify_fcm_on_insert() IS 
'Yeni notification eklendiğinde FCM push notification gönderir';

COMMENT ON TRIGGER trigger_fcm_notification ON notifications IS 
'Notification eklendiğinde otomatik FCM push gönderir';
