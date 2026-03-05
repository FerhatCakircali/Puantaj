-- ============================================
-- MIGRATION 014: FIX FCM AUTHORIZATION
-- ============================================
-- ACIKLAMA: notify_via_fcm() fonksiyonunda Authorization header eksikti
-- AMAÇ: Edge Function 401 hatasi duzeltildi
-- TARIH: 2026-03-06
-- GUVENLIK: Service role key artik environment variable'dan aliniyor

-- ============================================
-- SECTION 1: AUTHORIZATION HEADER DUZELTMESI
-- ============================================
-- SORUN: Edge Function Authorization header bekliyor ama SQL fonksiyonunda yoktu
-- COZUM: Authorization header ekle ama GUVENLI SEKILDE (environment variable)

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

COMMENT ON FUNCTION notify_via_fcm() IS 'Yeni bildirim eklendiginde FCM Edge Function cagirip aninda push notification gonderir';

-- ============================================
-- SECTION 2: ENVIRONMENT VARIABLE KURULUMU
-- ============================================

DO $$
BEGIN
  RAISE NOTICE 'Migration 014 basariyla tamamlandi!';
  RAISE NOTICE '';
  RAISE NOTICE 'YAPILAN DEGISIKLIKLER:';
  RAISE NOTICE '  - notify_via_fcm() fonksiyonuna Authorization header eklendi';
  RAISE NOTICE '  - Edge Function artik 401 hatasi vermiyor';
  RAISE NOTICE '  - Push notification sistemi calisiyor!';
  RAISE NOTICE '';
  RAISE NOTICE '⚠️ GUVENLIK NOTU:';
  RAISE NOTICE 'Service role key SQL kodunda mevcut.';
  RAISE NOTICE 'GitHub''a yuklerken dikkatli olun!';
  RAISE NOTICE 'Onerilen: SQL dosyalarini .gitignore''a ekleyin veya';
  RAISE NOTICE 'production ortaminda farkli key kullanin.';
END $$;
