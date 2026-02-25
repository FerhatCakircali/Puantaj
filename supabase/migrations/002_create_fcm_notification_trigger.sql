-- FCM Notification Trigger
-- notifications tablosuna yeni kayıt eklendiğinde Edge Function'ı çağırır

-- 1. Edge Function'ı çağıran fonksiyon
CREATE OR REPLACE FUNCTION notify_via_fcm()
RETURNS TRIGGER AS $$
DECLARE
  request_id bigint;
BEGIN
  -- Edge Function'ı asenkron olarak çağır (pg_net extension kullanarak)
  BEGIN
    SELECT net.http_post(
      url := 'https://YOUR_PROJECT_ID.supabase.co/functions/v1/send-push-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY_HERE'
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
      -- Hata durumunda log'la ama trigger'ı başarısız sayma
      RAISE WARNING 'FCM notification failed: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Trigger'ı notifications tablosuna bağla
DROP TRIGGER IF EXISTS on_notification_insert_fcm_trigger ON notifications;

CREATE TRIGGER on_notification_insert_fcm_trigger
AFTER INSERT ON notifications
FOR EACH ROW
EXECUTE FUNCTION notify_via_fcm();

-- 3. Yorum ekle
COMMENT ON FUNCTION notify_via_fcm() IS 'Yeni bildirim eklendiğinde FCM Edge Function''ını çağırır';
COMMENT ON TRIGGER on_notification_insert_fcm_trigger ON notifications IS 'Yeni bildirim için FCM push notification gönderir';

-- 4. pg_net extension kontrolü (opsiyonel)
-- Eğer pg_net extension yüklü değilse, bu trigger çalışmaz
-- Supabase projelerinde pg_net varsayılan olarak yüklüdür
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') THEN
    RAISE WARNING 'pg_net extension is not installed. FCM notifications will not work.';
    RAISE WARNING 'Install it with: CREATE EXTENSION pg_net;';
  END IF;
END $$;
